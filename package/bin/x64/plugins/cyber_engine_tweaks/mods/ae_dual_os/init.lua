-- AE Dual OS 0.1.0. Runtime-only TweakDB changes; no RED4ext/TweakXL needed.
-- Attachment mapping approach: Cyberware-EX, Pavel Siberx (MIT, included).
local SLOT = 'AEDualOS.Sandevistan'
local READY = 'AEDualOS.Ready'
local BASE = 'AttachmentSlots.SystemReplacementCW'
local initialized = false
local elapsed, diagnosed = 0, false

local function contains(list, id)
  for _, value in ipairs(list) do
    if value == id then return true end
  end
  return false
end

local function copy(list)
  local result = {}
  for i, value in ipairs(list) do result[i] = value end
  return result
end

local function initialize()
  -- Reloading CET after loading a save must not alter attachment definitions.
  if TweakDB:GetRecord(READY) then
    initialized = true
    print('[AE Dual OS] Already initialized; keeping existing mappings.')
    return
  end
  if not Game.GetSystemRequestsHandler():IsPreGame() then error('Initialize at the main menu: restart the game.') end
  local base = TweakDBID.new(BASE)
  local slot = TweakDBID.new(SLOT)
  local changes, playerCount, sandyCount = {}, 0, 0
  local playerName = TweakDB:GetFlat('Character.Player_Puppet_Base.displayName')
  assert(playerName ~= nil, 'Player base record missing')
  -- Collect first; only the player records carrying the original OS slot.
  for _, record in ipairs(TweakDB:GetRecords('gamedataCharacter_Record')) do
    local id = record:GetID()
    local slots = TweakDB:GetFlat(id + '.attachmentSlots')
    if slots and contains(slots, base) and TweakDB:GetFlat(id + '.displayName') == playerName then
      local replacement = copy(slots)
      if not contains(replacement, slot) then table.insert(replacement, slot) end
      table.insert(changes, {id = id + '.attachmentSlots', old = copy(slots), new = replacement})
      playerCount = playerCount + 1
    end
  end
  for _, record in ipairs(TweakDB:GetRecords('gamedataItem_Record')) do
    local id = record:GetID()
    local slots = TweakDB:GetFlat(id + '.placementSlots')
    local cyberwareType = TweakDB:GetFlat(id + '.cyberwareType')
    if slots and #slots > 0 and cyberwareType and NameToString(cyberwareType) == 'Sandevistan' then
      -- Preserve any additional placement slots supplied by another mod.
      local replacement = copy(slots)
      local changed = false
      for index, value in ipairs(replacement) do
        if value == base then replacement[index], changed = slot, true end
      end
      if changed then
        table.insert(changes, {id = id + '.placementSlots', old = copy(slots), new = replacement})
        sandyCount = sandyCount + 1
      end
    end
  end
  assert(playerCount > 0 and sandyCount > 0, 'No compatible player/Sandevistan records found')
  assert(not TweakDB:GetRecord(SLOT), 'Slot name already exists without readiness marker; restart required')
  assert(TweakDB:CreateRecord(SLOT, 'gamedataAttachmentSlot_Record'), 'Cannot create independent Sandy slot')
  local applied = 0
  local ok, err = pcall(function()
    for index, change in ipairs(changes) do
      applied = index -- include a possibly partially applied failed operation in rollback
      assert(TweakDB:SetFlat(change.id, change.new), 'SetFlat failed: ' .. tostring(change.id))
    end
    assert(TweakDB:CreateRecord(READY, 'gamedataAttachmentSlot_Record'), 'Cannot enable redscript addon')
  end)
  if not ok then
    local restored = true
    for index = applied, 1, -1 do
      if not TweakDB:SetFlat(changes[index].id, changes[index].old) then restored = false end
    end
    TweakDB:DeleteRecord(SLOT)
    if not restored then error(tostring(err) .. '; rollback incomplete, restart before loading a save') end
    error(err)
  end
  initialized = true
  print(string.format('[AE Dual OS] READY: %d player records, %d Sandevistan records; separate physical slots.', playerCount, sandyCount))
end

registerForEvent('onInit', function()
  local ok, err = pcall(initialize)
  if not ok then print('[AE Dual OS] DISABLED: ' .. tostring(err)) end
end)

-- One read-only snapshot after each load; no equipment/stat/save mutations.
registerForEvent('onUpdate', function(delta)
  if not initialized then return end
  local player = Game.GetPlayer()
  if not player or Game.GetSystemRequestsHandler():IsPreGame() then diagnosed, elapsed = false, 0; return end
  if diagnosed then return end
  elapsed = elapsed + delta
  if elapsed < 8 then return end
  diagnosed = true
  local ok, result = pcall(function() return player:AEDualDiagnostics() end)
  print('[AE Dual OS] ' .. (ok and result or ('Diagnostics unavailable: ' .. tostring(result))))
end)

return { diagnostics = function()
  local player = Game.GetPlayer()
  if player then print('[AE Dual OS] ' .. player:AEDualDiagnostics()) end
end }
