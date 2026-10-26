from pathlib import Path
import sys
root = Path(__file__).resolve().parents[1]

from lupa.luajit21 import LuaRuntime

setup = r'''
local mt = {}
local function id(s) return setmetatable({value=s}, mt) end
mt.__add = function(a,b) return id(a.value .. b) end
mt.__eq = function(a,b) return a.value == b.value end
mt.__tostring = function(a) return a.value end
TweakDBID = {new=id}
NameToString = function(v) assert(type(v)=='string'); return v end
events, logs = {}, {}
print = function(v) table.insert(logs,v) end
registerForEvent = function(e,f) events[e]=f end
Game = {
 GetPlayer=function() return {} end, -- 2.5 has a player even in the main menu
 GetSystemRequestsHandler=function() return {IsPreGame=function() return not loaded end} end
}
local base = id('AttachmentSlots.SystemReplacementCW')
flats = {
 ['Character.Player_Puppet_Base.displayName']='V',
 ['Player.displayName']='V', ['Player.attachmentSlots']={base, id('Other.Slot')},
 ['NPC.displayName']='NPC', ['NPC.attachmentSlots']={base},
 ['NoOS.displayName']='V', ['NoOS.attachmentSlots']={id('Other.Slot')},
 ['Apogee.cyberwareType']='Sandevistan', ['Apogee.placementSlots']={base},
 ['OldSandy.cyberwareType']='Sandevistan', ['OldSandy.placementSlots']={base,id('Other.Slot')},
 ['EmptySandy.cyberwareType']='Sandevistan', ['EmptySandy.placementSlots']={},
 ['ThirdParty.cyberwareType']='Sandevistan', ['ThirdParty.placementSlots']={id('ThirdParty.Slot')},
 ['Deck.cyberwareType']='Cyberdeck', ['Deck.placementSlots']={base},
 ['Berserk.cyberwareType']='Berserk', ['Berserk.placementSlots']={base},
 ['Weapon.placementSlots']={id('Other.Slot')}
}
records, writes = {}, 0
local function rec(name) return {GetID=function() return id(name) end} end
TweakDB = {
 GetRecord=function(_,key) return records[tostring(key)] end,
 GetFlat=function(_,key) return flats[tostring(key)] end,
 GetRecords=function(_,kind)
   if kind=='gamedataCharacter_Record' then return {rec('Player'),rec('NPC'),rec('NoOS')} end
   assert(kind=='gamedataItem_Record')
   return {rec('Apogee'),rec('OldSandy'),rec('EmptySandy'),rec('ThirdParty'),rec('Deck'),rec('Berserk'),rec('Weapon')}
 end,
 CreateRecord=function(_,key,kind)
   assert(kind=='gamedataAttachmentSlot_Record')
   if failReady and key=='AEDualOS.Ready' then return false end
   if records[key] then return false end
   records[key]=true; return true
 end,
 DeleteRecord=function(_,key) records[key]=nil; return true end,
 SetFlat=function(_,key,value)
   writes=writes+1
   -- Simulate failure even after the current write to exercise full rollback.
   flats[tostring(key)]=value
   return writes~=failAt
 end
}
function snapshot()
 local lines={}
 for key,value in pairs(flats) do
   if type(value)=='table' then
     local values={}
     for _,v in ipairs(value) do table.insert(values,tostring(v)) end
     table.insert(lines,key..'='..table.concat(values,','))
   else table.insert(lines,key..'='..value) end
 end
 table.sort(lines); return table.concat(lines,'\n')
end
'''
code = (root / 'package/bin/x64/plugins/cyber_engine_tweaks/mods/ae_dual_os/init.lua').read_text()

def environment():
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(setup)
    lua.execute(code)
    return lua, lua.globals()

lua, g = environment()
g.events['onInit']()
assert g.records['AEDualOS.Ready']
lua.execute('''
assert(#flats['Player.attachmentSlots']==3)
assert(tostring(flats['Apogee.placementSlots'][1])=='AEDualOS.Sandevistan')
assert(tostring(flats['OldSandy.placementSlots'][2])=='Other.Slot')
assert(tostring(flats['Deck.placementSlots'][1])=='AttachmentSlots.SystemReplacementCW')
assert(tostring(flats['Berserk.placementSlots'][1])=='AttachmentSlots.SystemReplacementCW')
assert(tostring(flats['ThirdParty.placementSlots'][1])=='ThirdParty.Slot')
assert(#flats['NPC.attachmentSlots']==1 and #flats['NoOS.attachmentSlots']==1)
''')
before, writes = g.snapshot(), g.writes
g.events['onInit']()
assert g.snapshot() == before and g.writes == writes
print('PASS: scoped mapping, preserves unrelated slots/items, repeat initialization is idempotent')

for index in range(1, 4):
    lua, g = environment()
    before = g.snapshot()
    g.failAt = index
    g.events['onInit']()
    assert g.snapshot() == before
    assert not g.records['AEDualOS.Ready'] and not g.records['AEDualOS.Sandevistan']
print('PASS: partial write failure at each mutation restores the original state and leaves addon disabled')

lua, g = environment()
before = g.snapshot()
g.failReady = True
g.events['onInit']()
assert g.snapshot() == before and not g.records['AEDualOS.Sandevistan']
print('PASS: readiness failure rolls all mappings back')

lua, g = environment()
before = g.snapshot()
g.loaded = True
g.events['onInit']()
assert g.snapshot() == before and g.writes == 0 and not g.records['AEDualOS.Ready']
print('PASS: refuses late initialization while a player is loaded')
