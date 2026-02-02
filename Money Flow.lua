print("Money Flow Addon Loaded")

-- =========================================================
-- Saved config
-- NOTE: We bind config on PLAYER_LOGIN (guaranteed SavedVariables loaded)
-- =========================================================

local config = nil

local function EnsureConfig()
    if not config then
        MoneyFlowConfig = MoneyFlowConfig or {}
        config = MoneyFlowConfig
        if config.openOnBags == nil then
            config.openOnBags = false
        end
    end
end

-- =========================================================
-- UI: Main frame
-- =========================================================
-- Main Frame
local mainFrame = CreateFrame("Frame", "MoneyFlowMainFrame", UIParent, "BackdropTemplate")
mainFrame:SetSize(300, 250)
mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
mainFrame:Hide()

mainFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
mainFrame:SetBackdropColor(0, 0, 0, 0.9)

-- UI frame functionality
mainFrame:SetMovable(true)
mainFrame:EnableMouse(true)
mainFrame:RegisterForDrag("LeftButton")
mainFrame:SetScript("OnDragStart", function(self)
    self:StartMoving()
    if self.SetUserPlaced then
        self:SetUserPlaced(true)
    end
end)
mainFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
end)


-- Resize functionality
mainFrame:SetResizable(true)
mainFrame:SetResizeBounds(200, 150, 600, 400)

-- resize button
local resizeButton = CreateFrame("Button", nil, mainFrame)
resizeButton:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -2, 2)
resizeButton:SetSize(16, 16)
resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")

-- resize scripts
resizeButton:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and mainFrame.StartSizing then
        resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
        mainFrame:StartSizing("BOTTOMRIGHT")
        if mainFrame.SetUserPlaced then
            mainFrame:SetUserPlaced(true)
        end
    end
end)

resizeButton:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" then
        resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        if mainFrame.StopMovingOrSizing then
            mainFrame:StopMovingOrSizing()
        end
    end
end)

-- Titlebar
local titleBar = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
titleBar:SetHeight(35)
titleBar:SetPoint("TOPLEFT", mainFrame, "TOPLEFT")
titleBar:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT")
titleBar:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
titleBar:SetBackdropColor(0.2, 0.2, 0.2, 1)
local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
titleText:SetPoint("LEFT", titleBar, "LEFT", 8, 0)
titleText:SetText("Money Flow")

-- Close button
local closeButton = CreateFrame("Button", nil, titleBar, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", titleBar, "TOPRIGHT", -6, -6)
closeButton:SetScript("OnClick", function()
    mainFrame:Hide()
end)

-- Character info
mainFrame.playerName = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
mainFrame.playerName:SetPoint("TOPLEFT", titleBar, "TOPLEFT", 8, -38)
mainFrame.playerName:SetText("Character: " .. UnitName("player") .. " - " .. UnitLevel("player"))

-- Income label
mainFrame.incomeLabel = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
mainFrame.incomeLabel:SetPoint("TOPLEFT", mainFrame.playerName, "BOTTOMLEFT", 0, -10)
mainFrame.incomeLabel:SetText("Gold Income:")

-- Income value
mainFrame.incomeValue = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
mainFrame.incomeValue:SetPoint("LEFT", mainFrame.incomeLabel, "RIGHT", 10, 0)

-- Outgoing label
mainFrame.outgoingLabel = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
mainFrame.outgoingLabel:SetPoint("TOPLEFT", mainFrame.incomeLabel, "BOTTOMLEFT", 0, -10)
mainFrame.outgoingLabel:SetText("Gold spent:")

-- Outgoing value
mainFrame.outgoingValue = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
mainFrame.outgoingValue:SetPoint("LEFT", mainFrame.outgoingLabel, "RIGHT", 10, 0)

-- Total label
mainFrame.totalLabel = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
mainFrame.totalLabel:SetPoint("TOPLEFT", mainFrame.outgoingLabel, "BOTTOMLEFT", 0, -10)
mainFrame.totalLabel:SetText("Total gold:")

--Total Value
mainFrame.totalValue = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
mainFrame.totalValue:SetPoint("LEFT", mainFrame.totalLabel, "RIGHT", 10, 0)

-- Reset Button
local ResetSessionData -- forward declaration

local resetButton = CreateFrame("BUTTON", nil, mainFrame, "GameMenuButtonTemplate")
resetButton:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT", 10, 10)
resetButton:SetSize(120, 30)
resetButton:SetText("Reset Session")

-- Reset button clicked script
resetButton:SetScript("OnClick", function()
    ResetSessionData()
end)

-- Tootltip for reset button
resetButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Reset the gold income and expenses for this session.", 0.8, 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)

resetButton:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

-- =========================================================
-- Session Tracking (Gold per session)
-- =========================================================
-- Variables to track income and outgoings
local totalGoldEarned = 0
local totalGoldSpent = 0
local lastMoney = nil -- to track changes

local function UpdateToDisplay()
    local net = totalGoldEarned - totalGoldSpent
    local displayText

    if net < 0 then
        displayText = "-" .. C_CurrencyInfo.GetCoinTextureString(-net)
    else
        displayText = C_CurrencyInfo.GetCoinTextureString(net)
    end

    mainFrame.totalValue:SetText(displayText)

    -- Color coding
    if net > 0 then
        mainFrame.totalValue:SetTextColor(0, 1, 0) -- Green for profit
    elseif net < 0 then
        mainFrame.totalValue:SetTextColor(1, 0, 0) -- Red for loss
    end
end

-- Refresh UI function
local function RefreshUI()
    mainFrame.incomeValue:SetText(C_CurrencyInfo.GetCoinTextureString(totalGoldEarned))
    mainFrame.outgoingValue:SetText(C_CurrencyInfo.GetCoinTextureString(totalGoldSpent))
    UpdateToDisplay()
end

-- Local function for reset button
ResetSessionData = function() -- used in reset button
    totalGoldEarned = 0
    totalGoldSpent = 0
    lastMoney = GetMoney()
    RefreshUI()
end

RefreshUI() -- Initial UI refresh when game is starting to make sure values are correct

-- =========================================================
-- Slash commands
-- =========================================================

SLASH_MONEYFLOW1 = "/Moneyflow"
SLASH_MONEYFLOW2 = "/mf"
SLASH_MONEYFLOW3 = "/moneyflow"
SLASH_MONEYFLOW4 = "/MoneyFlow"
SlashCmdList["MONEYFLOW"] = function()
    if mainFrame:IsShown() then
        mainFrame:Hide()
    else
        mainFrame:Show()
    end
end

SLASH_MONEYFLOWRESET1 = "/mfreset"
SLASH_MONEYFLOWRESET2 = "/moneyflowreset"
SlashCmdList["MONEYFLOWRESET"] = function()
    ResetSessionData()
end

-- =========================================================
-- Bags integration (hook-based, NO frame detection)
-- Works even if bag UI frames changed (Midnight/12.x)
-- =========================================================

local function ShowWithBags()
    EnsureConfig()
    if config.openOnBags then
        mainFrame:Show()
    end
end

local function HideWithBags()
    EnsureConfig()
    if config.openOnBags then
        mainFrame:Hide()
    end
end

local function ToggleWithBags()
    EnsureConfig()
    if config.openOnBags then
        if mainFrame:IsShown() then mainFrame:Hide() else mainFrame:Show() end
    end
end

if ToggleAllBags then hooksecurefunc("ToggleAllBags", ToggleWithBags) end
if OpenAllBags then hooksecurefunc("OpenAllBags", ShowWithBags) end
if CloseAllBags then hooksecurefunc("CloseAllBags", HideWithBags) end

-- =========================================================
-- Event handling
-- =========================================================

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_MONEY")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        EnsureConfig()
        lastMoney = GetMoney()
        mainFrame:Hide()
    elseif event == "PLAYER_MONEY" then
        local currentMoney = GetMoney()
        if lastMoney then
            local diff = currentMoney - lastMoney
            if diff > 0 then
                totalGoldEarned = totalGoldEarned + diff
            elseif diff < 0 then
                totalGoldSpent = totalGoldSpent - diff -- diff is negative
            end
            RefreshUI()
        end
        lastMoney = currentMoney
    end
end)

-- =========================================================
-- Interface / Settings Options panel
-- =========================================================
-- Create options panel
local optionsPanel = CreateFrame("Frame", "MoneyFlowOptionsPanel", InterfaceOptionsFramePanelContainer)
optionsPanel.name = "Money Flow"

local optTitle = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
optTitle:SetPoint("TOPLEFT", 16, -16)
optTitle:SetText("Money Flow Options")

local optSubText = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
optSubText:SetPoint("TOPLEFT", optTitle, "BOTTOMLEFT", 0, -8)
optSubText:SetText("Simple gold tracking addon. Use /mf to open the main window.")

-- Checkbox: Open on bags
local openOnBagsCheckbox = CreateFrame("CheckButton", "MoneyFlowOpenOnBagsCheckbox", optionsPanel,
    "InterfaceOptionsCheckButtonTemplate")
openOnBagsCheckbox:SetPoint("TOPLEFT", optSubText, "BOTTOMLEFT", 0, -8)
openOnBagsCheckbox.Text:SetText("Open Money Flow when opening bags")

openOnBagsCheckbox:SetScript("OnClick", function(self)
    EnsureConfig()
    config.openOnBags = self:GetChecked() and true or false
end)

-- Initialize checkbox state when panel is shown
optionsPanel:SetScript("OnShow", function()
    -- Ensure config if options opened before PLAYER_LOGIN
    EnsureConfig()
    openOnBagsCheckbox:SetChecked(config.openOnBags)
end)

if Settings and Settings.RegisterCanvasLayoutCategory then
    local category = Settings.RegisterCanvasLayoutCategory(optionsPanel, optionsPanel.name)
    Settings.RegisterAddOnCategory(category)
elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(optionsPanel)
end

-- =========================================================
-- End of File
-- =========================================================
