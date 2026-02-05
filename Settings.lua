--==========================================================
-- Money Flow - Settings.lua (separat vindue)
--==========================================================

MoneyFlowDB = MoneyFlowDB or {}
MoneyFlowDB.settingsKeys = MoneyFlowDB.settingsKeys or {}

-- Default settings
if MoneyFlowDB.settingsKeys.openWithBags == nil then
    MoneyFlowDB.settingsKeys.openWithBags = true
end

-- Small debug helper (kan fjernes)
local function dprint(...)
    print("|cff00ff00MoneyFlow:|r", ...)
end

--==========================================================
-- Settings Frame (Popup)
--==========================================================
MoneyFlowSettingsFrame = CreateFrame("Frame", "MoneyFlowSettingsFrame", UIParent, "BackdropTemplate")
MoneyFlowSettingsFrame:SetSize(320, 180)
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

-- Close button
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

-- Sync checkbox when frame is shown
MoneyFlowSettingsFrame:SetScript("OnShow", function()
    openWithBags:SetChecked(MoneyFlowDB.settingsKeys.openWithBags)
end)

--==========================================================
-- Optional: small info text
--==========================================================
local info = MoneyFlowSettingsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
info:SetPoint("TOPLEFT", openWithBags, "BOTTOMLEFT", 0, -10)
info:SetWidth(290)
info:SetJustifyH("LEFT")
info:SetText("Tip: You can still open Money Flow with /mf even if this is disabled.")
