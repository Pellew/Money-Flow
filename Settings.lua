--==========================================================
-- Money Flow - Settings.lua (separat vindue)
--==========================================================
local addonName, MoneyFlow = ...
--========================
-- SavedVariables + Defaults (robust + migrering)
--========================
MoneyFlowDB = MoneyFlowDB or {}
MoneyFlowDB.settingsKeys = MoneyFlowDB.settingsKeys or {}

-- Defaults for bools
if MoneyFlowDB.settingsKeys.openWithBags == nil then
    MoneyFlowDB.settingsKeys.openWithBags = true
end
if MoneyFlowDB.settingsKeys.anchorToBags == nil then
    MoneyFlowDB.settingsKeys.anchorToBags = true
end

-- Migrate / defaults for strings (fixer gamle installs hvor det var {} / table)
if type(MoneyFlowDB.anchorPointMainFrame) ~= "string" then
    MoneyFlowDB.anchorPointMainFrame = "TOPRIGHT"
end
if type(MoneyFlowDB.anchorPointBagFrame) ~= "string" then
    MoneyFlowDB.anchorPointBagFrame = "TOPLEFT"
end

-- Small debug helper (kan fjernes)
local function dprint(...)
    print("|cff00ff00MoneyFlow:|r", ...)
end

--==========================================================
-- Settings Frame (Popup)  **why is this a global frame**
--==========================================================
MoneyFlowSettingsFrame = CreateFrame("Frame", "MoneyFlowSettingsFrame", UIParent, "BackdropTemplate")
MoneyFlowSettingsFrame:SetSize(320, 330)
MoneyFlowSettingsFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
MoneyFlowSettingsFrame:Hide()

MoneyFlowSettingsFrame:SetBackdrop({
    bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile     = true,
    tileSize = 16,
    edgeSize = 16,
    insets   = { left = 4, right = 4, top = 4, bottom = 4 },
})
MoneyFlowSettingsFrame:SetBackdropColor(0, 0, 0, 0.9)

-- ESC close support
tinsert(UISpecialFrames, "MoneyFlowSettingsFrame")

-- Movable
MoneyFlowSettingsFrame:SetMovable(true)
MoneyFlowSettingsFrame:EnableMouse(true)
MoneyFlowSettingsFrame:RegisterForDrag("LeftButton")
MoneyFlowSettingsFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
MoneyFlowSettingsFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

--==========================================================
-- Title bar
--==========================================================
local titleBar = CreateFrame("Frame", nil, MoneyFlowSettingsFrame, "BackdropTemplate")
titleBar:SetHeight(32)
titleBar:SetPoint("TOPLEFT", MoneyFlowSettingsFrame, "TOPLEFT")
titleBar:SetPoint("TOPRIGHT", MoneyFlowSettingsFrame, "TOPRIGHT")
titleBar:SetBackdrop({
    bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile     = true,
    tileSize = 16,
    edgeSize = 16,
    insets   = { left = 4, right = 4, top = 4, bottom = 4 },
})
titleBar:SetBackdropColor(0.2, 0.2, 0.2, 1)

local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
titleText:SetPoint("LEFT", titleBar, "LEFT", 8, 0)
titleText:SetText("Money Flow - Options")

local closeButton = CreateFrame("Button", nil, titleBar, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", titleBar, "TOPRIGHT", -6, -6)
closeButton:SetScript("OnClick", function()
    MoneyFlowSettingsFrame:Hide()
end)

--==========================================================
-- Checkbox: Open with Bags
--==========================================================
local openWithBags = CreateFrame("CheckButton", nil, MoneyFlowSettingsFrame, "InterfaceOptionsCheckButtonTemplate")
openWithBags:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 12, -18)
openWithBags.Text:SetText("Open Money Flow when bags are opened")

openWithBags:SetScript("OnClick", function(self)
    MoneyFlowDB.settingsKeys.openWithBags = self:GetChecked() and true or false
    dprint("openWithBags set to:", MoneyFlowDB.settingsKeys.openWithBags and "true" or "false")
end)

openWithBags:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Open with Bags", 1, 1, 1)
    GameTooltip:AddLine("If enabled, Money Flow will show/hide together with your bag window.", 0.9, 0.9, 0.9, true)
    GameTooltip:Show()
end)
openWithBags:SetScript("OnLeave", function() GameTooltip:Hide() end)

--==========================================================
-- Info text
--==========================================================
local info = MoneyFlowSettingsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
info:SetPoint("TOPLEFT", openWithBags, "BOTTOMLEFT", 5, -5)
info:SetWidth(300)
info:SetJustifyH("LEFT")
info:SetText("Tip: You can still open Money Flow with /mf even if this is disabled.")

--==========================================================
-- Checkbox: Anchor to bags
--==========================================================
local anchorToBags = CreateFrame("CheckButton", nil, MoneyFlowSettingsFrame, "InterfaceOptionsCheckButtonTemplate")
anchorToBags:SetPoint("TOPLEFT", info, "BOTTOMLEFT", -5, -18)
anchorToBags.Text:SetText("Anchor to bags")

anchorToBags:SetScript("OnClick", function(self)
    MoneyFlowDB.settingsKeys.anchorToBags = self:GetChecked() and true or false
    dprint("anchorToBags set to:", MoneyFlowDB.settingsKeys.anchorToBags and "true" or "false")

    -- Hvis du har en apply-funktion, kan du re-apply her:
    -- if _G.MoneyFlowFrame then MoneyFlow.Anchor:Apply(_G.MoneyFlowFrame) end
end)

anchorToBags:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Anchor to bags", 1, 1, 1)
    GameTooltip:AddLine("If enabled, Money Flow will anchor to your bags when opened.", 0.9, 0.9, 0.9, true)
    GameTooltip:Show()
end)
anchorToBags:SetScript("OnLeave", function() GameTooltip:Hide() end)

--==========================================================
-- Dropdown options (shared)
--==========================================================
local ANCHOR_OPTIONS = {
    { text = "Top left",     value = "TOPLEFT" },
    { text = "Top right",    value = "TOPRIGHT" },
    { text = "Left",         value = "LEFT" },
    { text = "Right",        value = "RIGHT" },
    { text = "Bottom left",  value = "BOTTOMLEFT" },
    { text = "Bottom right", value = "BOTTOMRIGHT" },
}

local function GetTextForValue(options, value)
    for _, opt in ipairs(options) do
        if opt.value == value then
            return opt.text
        end
    end
    return nil
end


--==========================================================
-- Blizzard-clean dropdown creator (genbruges til MF + BF)
--==========================================================
local function CreateAnchorDropdown(parent, labelText, anchorToFrame, anchorToPoint, x, y, width, options, getValue,
                                    setValue)
    -- Label
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", anchorToFrame, anchorToPoint, x, y)
    label:SetText(labelText)

    -- Dropdown frame
    local dd = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    dd:SetPoint("TOPLEFT", label, "BOTTOMLEFT", -10, -5)
    UIDropDownMenu_SetWidth(dd, width or 160)

    -- Setter: DB + UI text + refresh checks
    local function ApplyValue(value)
        setValue(value)
        local text = GetTextForValue(options, value) or tostring(value or "Unknown")
        UIDropDownMenu_SetSelectedValue(dd, value)
        UIDropDownMenu_SetText(dd, text)
    end


    -- Initializer (byg knapper)
    dd.initialize = function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        info.keepShownOnClick = false

        for _, opt in ipairs(options) do
            info.text = opt.text
            info.value = opt.value
            info.func = function() ApplyValue(opt.value) end
            info.checked = (getValue() == opt.value)
            UIDropDownMenu_AddButton(info, level)
        end
    end

    UIDropDownMenu_Initialize(dd, dd.initialize)

    -- Sæt initial tekst fra DB (vigtigt)
    ApplyValue(getValue())

    return dd, ApplyValue
end

--==========================================================
-- Dropdown: Money Flow frame anchorpoint
--==========================================================
local dropdownMF, ApplyMF = CreateAnchorDropdown(
    MoneyFlowSettingsFrame,
    "Choose anchorpoint for Money Flow frame",
    anchorToBags,
    "BOTTOMLEFT",
    5, -10,
    160,
    ANCHOR_OPTIONS,
    function() return MoneyFlowDB.anchorPointMainFrame end,
    function(v) MoneyFlowDB.anchorPointMainFrame = v end
)

--==========================================================
-- Dropdown: Bag frame anchorpoint
--==========================================================
local dropdownBF, ApplyBF = CreateAnchorDropdown(
    MoneyFlowSettingsFrame,
    "Choose anchorpoint for bag frame",
    dropdownMF,
    "BOTTOMLEFT",
    10, -10,
    160,
    ANCHOR_OPTIONS,
    function() return MoneyFlowDB.anchorPointBagFrame end,
    function(v) MoneyFlowDB.anchorPointBagFrame = v end
)

--==========================================================
-- Single OnShow sync (ingen dobbelt SetScript)
--==========================================================
MoneyFlowSettingsFrame:HookScript("OnShow", function()
    openWithBags:SetChecked(MoneyFlowDB.settingsKeys.openWithBags)
    anchorToBags:SetChecked(MoneyFlowDB.settingsKeys.anchorToBags)

    -- Hvis DB er blevet ændret andetsteds, sync dropdown-tekst igen
    ApplyMF(MoneyFlowDB.anchorPointMainFrame)
    ApplyBF(MoneyFlowDB.anchorPointBagFrame)
end)


local restoreBtn = CreateFrame("Button", nil, MoneyFlowSettingsFrame, "UIPanelButtonTemplate")
restoreBtn:SetSize(180, 22)
restoreBtn:SetPoint("BOTTOM", MoneyFlowSettingsFrame, "BOTTOM", 0, 12)
restoreBtn:SetText("Restore Defaults")

restoreBtn:SetScript("OnClick", function()
    -- Reset keys (lad strukturen være)
    MoneyFlowDB.settingsKeys              = MoneyFlowDB.settingsKeys or {}
    MoneyFlowDB.settingsKeys.openWithBags = true
    MoneyFlowDB.settingsKeys.anchorToBags = true

    MoneyFlowDB.anchorPointMainFrame      = "TOPRIGHT"
    MoneyFlowDB.anchorPointBagFrame       = "TOPLEFT"

    MoneyFlowCharDB.frameSize             = { w = 300, h = 180 }

    -- Sync UI
    openWithBags:SetChecked(true)
    anchorToBags:SetChecked(true)
    ApplyMF(MoneyFlowDB.anchorPointMainFrame)
    ApplyBF(MoneyFlowDB.anchorPointBagFrame)

    dprint("Defaults restored. (Saved on next /reload or logout)")
end)
