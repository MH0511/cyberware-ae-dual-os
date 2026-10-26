// Based on Cyberware-EX (MIT, Pavel Siberx), adapted for two OS and 2.5.
// Existing engine RTTI class. Only expose its native fields when Codeware does
// not already declare it; this does not load or depend on the Codeware DLL.
@if(!ModuleExists("Codeware"))
public native class inkHudEntryInfo extends inkUserData {
    public native let size: Vector2;
    public native let offset: Vector2;
}

@wrapMethod(HotkeysWidgetController)
protected cb func OnInitialize() -> Bool {
    wrappedMethod();
    if !AEDualOS.Ready() { return false; }
    let container = inkWidgetRef.Get(this.m_dpadHintsPanel) as inkCompoundWidget;
    if !IsDefined(container) { return false; }
    let i = 0;
    while i < container.GetNumChildren() {
        let widget = container.GetWidgetByIndex(i);
        if Equals(widget.GetName(), n"AEDualMain") { return false; }
        if Equals(widget.GetName(), n"cyberware") {
            let extra = this.SpawnFromLocal(container, n"cyberware");
            if !IsDefined(extra) { return false; }
            widget.SetName(n"AEDualMain");
            extra.SetName(n"AEDualCyberdeck");
            container.ReorderChild(extra, i + 1);
            let info = this.GetRootWidget().GetUserData(n"inkHudEntryInfo") as inkHudEntryInfo;
            if IsDefined(info) { info.size = Vector2(2400.00, 300.00); }
            return false;
        }
        i += 1;
    }
    return false;
}

@wrapMethod(HotkeysWidgetController)
protected cb func OnPlayerAttach(player: ref<GameObject>) -> Bool {
    wrappedMethod(player);
    if AEDualOS.Ready() {
        GameInstance.GetBlackboardSystem(player.GetGame()).Get(GetAllBlackboardDefs().UI_Hotkeys).SetVariant(GetAllBlackboardDefs().UI_Hotkeys.ModifiedHotkey, ToVariant(EHotkey.LBRB), true);
    }
}

@wrapMethod(ChargedHotkeyItemCyberwareController)
protected func UpdateCurrentItem() -> Void {
    let name = this.GetRootWidget().GetName();
    if !AEDualOS.Ready() || (NotEquals(name, n"AEDualMain") && NotEquals(name, n"AEDualCyberdeck")) {
        wrappedMethod();
        return;
    }
    let equipment = EquipmentSystem.GetData(this.GetPlayerControlledObject());
    let item = ItemID.None();
    if Equals(name, n"AEDualCyberdeck") {
        if equipment.AEDualEquipped() { item = equipment.AEDualItem(n"Cyberdeck"); }
    } else {
        item = equipment.AEDualItem(n"Sandevistan");
        if !ItemID.IsValid(item) { item = equipment.GetActiveItem(gamedataEquipmentArea.SystemReplacementCW); }
    }
    let previous = this.m_currentItem;
    this.m_currentItem = this.m_inventoryManager.GetInventoryItemDataFromItemID(item);
    this.m_currentItem.Quantity = 0;
    this.m_hotkeyItemController.Setup(this.m_currentItem, ItemDisplayContext.DPAD_RADIAL);
    if previous.ID != item {
        this.UpdateStatListener();
        if ItemID.IsValid(item) {
            this.UpdateChargeValue(this.GetStatPoolCurrentValue(this.m_currentStatPoolType, true), this.GetStatPoolMaxPoints(this.m_currentStatPoolType) / 100.00, false);
        }
    }
    if !ItemID.IsValid(item) || !this.IsCyberwareSupported(item) {
        this.GetRootWidget().SetVisible(false);
        return;
    }
    this.ResolveState();
    switch this.GetItemType(item, n"None") {
        case this.c_cyberdeckKey:
            this.GetRootWidget().SetVisible(this.IsCyberdeckOverloadPerkPresent());
            break;
        case this.c_sandevistanKey:
            this.UpdateSandevistanVisibility();
            break;
        case this.c_berserkKey:
            this.GetRootWidget().SetVisible(Equals(PlayerPuppet.GetCurrentVehicleState(this.GetPlayer()), gamePSMVehicle.Default));
            break;
        default:
            this.GetRootWidget().SetVisible(false);
    }
}
