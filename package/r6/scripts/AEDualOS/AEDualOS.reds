// AE Dual OS 0.1.0, local Cyberpunk 2077 2.5 adaptation.
// Equipment/HUD/focus approach derived from Cyberware-EX, Copyright (c) 2023
// Pavel Siberx, MIT. See LICENSE-Cyberware-EX.txt shipped with this addon.

public abstract class AEDualOS {
    public static func Ready() -> Bool {
        return IsDefined(TweakDBInterface.GetAttachmentSlotRecord(t"AEDualOS.Ready"));
    }
}

@addMethod(EquipmentSystemPlayerData)
public final const func AEDualItem(tag: CName) -> ItemID {
    let areaIndex = this.GetEquipAreaIndex(gamedataEquipmentArea.SystemReplacementCW);
    if areaIndex < 0 || areaIndex >= ArraySize(this.m_equipment.equipAreas) {
        return ItemID.None();
    }
    let i = 0;
    while i < ArraySize(this.m_equipment.equipAreas[areaIndex].equipSlots) {
        let item = this.m_equipment.equipAreas[areaIndex].equipSlots[i].itemID;
        if ItemID.IsValid(item) && this.CheckTagsInItem(item, [tag]) {
            return item;
        }
        i += 1;
    }
    return ItemID.None();
}

@addMethod(EquipmentSystemPlayerData)
public final const func AEDualEquipped() -> Bool {
    return AEDualOS.Ready() && ItemID.IsValid(this.AEDualItem(n"Cyberdeck"))
        && ItemID.IsValid(this.AEDualItem(n"Sandevistan"));
}

// Quickhacks/programs must resolve the deck regardless of visual slot order.
// Keep the new 2.5 optional left-hand parameter for all other equipment.
@wrapMethod(EquipmentSystemPlayerData)
public final const func GetActiveItem(equipArea: gamedataEquipmentArea, opt isLeftHandWeapon: Bool) -> ItemID {
    if AEDualOS.Ready() && Equals(equipArea, gamedataEquipmentArea.SystemReplacementCW) {
        let deck = this.AEDualItem(n"Cyberdeck");
        if ItemID.IsValid(deck) { return deck; }
        let sandy = this.AEDualItem(n"Sandevistan");
        if ItemID.IsValid(sandy) { return sandy; }
    }
    return wrappedMethod(equipArea, isLeftHandWeapon);
}

// The OS is already equipped. Changing its hotkey must not unequip the other OS.
@wrapMethod(EquipmentSystemPlayerData)
public final func AssignItemToHotkey(newID: ItemID, hotkey: EHotkey) -> Void {
    if AEDualOS.Ready() && Equals(hotkey, EHotkey.LBRB) {
        this.m_hotkeys[EnumInt(hotkey)].StoreItem(newID);
        this.SyncHotkeyData(hotkey);
        return;
    }
    wrappedMethod(newID, hotkey);
}

@wrapMethod(EquipmentSystemPlayerData)
private final func UnequipItem(equipAreaIndex: Int32, slotIndex: Int32, opt forceRemove: Bool) -> Void {
    let osArea = AEDualOS.Ready() && Equals(this.m_equipment.equipAreas[equipAreaIndex].areaType, gamedataEquipmentArea.SystemReplacementCW);
    let previous = this.m_equipment.equipAreas[equipAreaIndex].equipSlots[slotIndex].itemID;
    wrappedMethod(equipAreaIndex, slotIndex, forceRemove);
    // Do not reapply effects after a blocked/unsuccessful unequip.
    if osArea && ItemID.IsValid(previous) && !this.IsEquipped(previous) {
        let i = 0;
        while i < ArraySize(this.m_equipment.equipAreas[equipAreaIndex].equipSlots) {
            let remaining = this.m_equipment.equipAreas[equipAreaIndex].equipSlots[i].itemID;
            if ItemID.IsValid(remaining) {
                this.RemoveEquipGLPs(remaining);
                this.ApplyEquipGLPs(remaining);
            }
            i += 1;
        }
        this.AssignItemToHotkey(this.GetActiveItem(gamedataEquipmentArea.SystemReplacementCW), EHotkey.LBRB);
    }
}

@wrapMethod(PlayerPuppet)
private final func ActivateIconicCyberware() -> Void {
    let equipment = EquipmentSystem.GetData(this);
    let focus = this.GetPlayerStateMachineBlackboard().GetInt(GetAllBlackboardDefs().PlayerStateMachine.Vision) == 1;
    // Vanilla 2.5 already routes focus input through the overclock helper.
    if !equipment.AEDualEquipped() || focus {
        wrappedMethod();
        return;
    }
    let successful = false;
    if GameInstance.GetStatsSystem(this.GetGame()).GetStatBoolValue(Cast<StatsObjectID>(this.GetEntityID()), gamedataStatType.HasSandevistan) {
        if TimeDilationHelper.CanUseTimeDilation(this) {
            successful = ItemActionsHelper.UseItem(this, equipment.AEDualItem(n"Sandevistan"));
        }
    } else {
        if this.IsPhoneCallActive() {
            this.ShowSandevistanBlockedNotification();
            return;
        }
    }
    // In 2.5 the Sandy action itself handles IconicCyberwareActivated.
    let action = new DPADActionPerformed();
    action.action = EHotkey.LBRB;
    action.state = EUIActionState.COMPLETED;
    action.successful = successful;
    GameInstance.GetUISystem(this.GetGame()).QueueEvent(action);
}

// Avoid the vanilla focus transition that exits Sandevistan and removes its buff.
@wrapMethod(TimeDilationFocusModeDecisions)
protected final const func EnterCondition(const stateContext: ref<StateContext>, const scriptInterface: ref<StateGameScriptInterface>) -> Bool {
    if !EquipmentSystem.GetData(scriptInterface.executionOwner).AEDualEquipped() {
        return wrappedMethod(stateContext, scriptInterface);
    }
    let timeSystem = scriptInterface.GetTimeSystem();
    if !this.IsInVisionModeActiveState(stateContext, scriptInterface) {
        if timeSystem.IsTimeDilationActive(n"focusMode") {
            let easeOut = TweakDBInterface.GetCName(t"timeSystem.focusModeTimeDilation.easeOutCurve", n"None");
            timeSystem.UnsetTimeDilation(n"focusMode", easeOut);
            timeSystem.UnsetTimeDilationOnLocalPlayerZero(n"focusMode", easeOut);
            if timeSystem.IsTimeDilationActive(n"sandevistan") {
                timeSystem.SetTimeDilationOnLocalPlayerZero(n"sandevistan", 1.00, 999.00, n"None", n"None");
                timeSystem.SetIgnoreTimeDilationOnLocalPlayerZero(true);
            }
        }
        return false;
    }
    if this.IsPlayerInBraindance(scriptInterface) || !this.ShouldActivate(stateContext, scriptInterface) {
        return false;
    }
    if timeSystem.IsTimeDilationActive(n"sandevistan") {
        if !timeSystem.IsTimeDilationActive(n"focusMode") && this.GetBoolFromTimeSystemTweak("focusModeTimeDilation", "enableTimeDilation") {
            let easeIn = TweakDBInterface.GetCName(t"timeSystem.focusModeTimeDilation.easeInCurve", n"None");
            let easeOut = TweakDBInterface.GetCName(t"timeSystem.focusModeTimeDilation.easeOutCurve", n"None");
            timeSystem.SetTimeDilation(n"focusMode", TweakDBInterface.GetFloat(t"timeSystem.focusModeTimeDilation.timeDilation", 1.00), 999.00, easeIn, easeOut);
            if TweakDBInterface.GetBool(t"timeSystem.focusModeTimeDilation.applyTimeDilationToPlayer", false) {
                timeSystem.SetTimeDilationOnLocalPlayerZero(n"focusMode", TweakDBInterface.GetFloat(t"timeSystem.focusModeTimeDilation.playerTimeDilation", 1.00), 999.00, easeIn, easeOut);
            }
        }
        return false;
    }
    return wrappedMethod(stateContext, scriptInterface);
}

@wrapMethod(PlayerPuppet)
protected cb func OnCleanUpTimeDilationEvent(evt: ref<CleanUpTimeDilationEvent>) -> Bool {
    if EquipmentSystem.GetData(this).AEDualEquipped() {
        let timeSystem = GameInstance.GetTimeSystem(this.GetGame());
        // A delayed cleanup from an earlier focus/Sandy activation must not
        // reset the player's speed while the other (or a new) effect is active.
        if (Equals(evt.reason, n"focusMode") || Equals(evt.reason, n"sandevistan"))
            && (timeSystem.IsTimeDilationActive(n"sandevistan") || timeSystem.IsTimeDilationActive(n"focusMode")) {
            return false;
        }
    }
    return wrappedMethod(evt);
}

@addMethod(PlayerPuppet)
public final func AEDualDiagnostics() -> String {
    let data = EquipmentSystem.GetData(this);
    let stats = GameInstance.GetStatsSystem(this.GetGame());
    let id = Cast<StatsObjectID>(this.GetEntityID());
    return "ready=" + ToString(AEDualOS.Ready())
        + " dual=" + ToString(data.AEDualEquipped())
        + " deck=" + ToString(data.AEDualItem(n"Cyberdeck"))
        + " sandy=" + ToString(data.AEDualItem(n"Sandevistan"))
        + " HasCyberdeck=" + ToString(stats.GetStatValue(id, gamedataStatType.HasCyberdeck))
        + " HasSandevistan=" + ToString(stats.GetStatValue(id, gamedataStatType.HasSandevistan))
        + " CanUseOverclock=" + ToString(stats.GetStatValue(id, gamedataStatType.CanUseOverclock))
        + " focus=" + ToString(this.GetPlayerStateMachineBlackboard().GetInt(GetAllBlackboardDefs().PlayerStateMachine.Vision))
        + " sandyActive=" + ToString(GameInstance.GetTimeSystem(this.GetGame()).IsTimeDilationActive(n"sandevistan"));
}
