--==========================================================
-- Money Flow - Version 2.0.2
--==========================================================
-- Highlights:
--  - NO bag hook install on login (lazy install when bags are toggled)
--  - Supports: Blizzard bags, ElvUI, Baganator, BetterBags
--  - Safe frame calls (avoids "bad self" errors)
--  - Clean debug system (/mfdebug)
--==========================================================

--==========================================================
-- SavedVariables init
--==========================================================
MoneyFlowDB = MoneyFlowDB or {}
MoneyFlowDB.settingsKeys = MoneyFlowDB.settingsKeys or {}

-- Default settings
if MoneyFlowDB.settingsKeys.openWithBags == nil then
    MoneyFlowDB.settingsKeys.openWithBags = true
end

-- Default settings
if MoneyFlowDB.settingsKeys.anchorToBags == nil then
    MoneyFlowDB.settingsKeys.anchorToBags = true
end


--==========================================================
-- Debug
--==========================================================
local DEBUG = false
local function dprint(...)
    if DEBUG then
        print("|cff00ff00MoneyFlow:|r", ...)
    end
end

--==========================================================
-- Safe helpers (avoid "bad self" IsShown/GetName/GetPoint errors)
--==========================================================
local function IsFrameObject(obj)
    if not obj then return false end
    local t = type(obj)
    if t ~= "table" and t ~= "userdata" then return false end
    if not obj.IsObjectType then return false end
    local ok, isFrame = pcall(obj.IsObjectType, obj, "Frame")
    return ok and isFrame
end

local function SafeIsShown(obj)
    if not IsFrameObject(obj) or not obj.IsShown then return false end
    local ok, shown = pcall(obj.IsShown, obj)
    return ok and shown
end

local function SafeName(obj)
    if not obj then return "nil" end
    if type(obj) ~= "table" then return tostring(obj) end
    if not obj.GetName then return "<?> (no GetName)" end
    local ok, name = pcall(obj.GetName, obj)
    if ok and name then return name end
    return "<?> (bad GetName)"
end

local function SafeGetPoint(obj, index)
    if not IsFrameObject(obj) or not obj.GetPoint then return nil end
    local ok, p1, rel, p2, x, y = pcall(obj.GetPoint, obj, index or 1)
    if not ok then return nil end
    return p1, rel, p2, x, y
end

--==========================================================
-- Settings helper
--==========================================================
local function OpenWithBagsEnabled()
    return MoneyFlowDB
        and MoneyFlowDB.settingsKeys
        and MoneyFlowDB.settingsKeys.openWithBags == true
end

local function AnchorToBagsEnable()
    return MoneyFlowDB
        and MoneyFlowDB.settingsKeys
        and MoneyFlowDB.settingsKeys.anchorToBags == true
end

--==========================================================
-- UI: Main frame
--==========================================================
local mainFrame = CreateFrame("Frame", "MoneyFlowMainFrame", UIParent, "BackdropTemplate")
mainFrame:SetSize(300, 180)
mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
mainFrame:Hide()

-- Make frame closable with ESC
tinsert(UISpecialFrames, "MoneyFlowMainFrame")

-- Ensure visible above heavy UI (ElvUI bags can be high)
mainFrame:SetClampedToScreen(true)
mainFrame:SetFrameStrata("DIALOG")
mainFrame:SetFrameLevel(1000)

mainFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
mainFrame:SetBackdropColor(0, 0, 0, 0.9)

--==========================================================
-- Titlebar
--==========================================================
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

local closeButton = CreateFrame("Button", nil, titleBar, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", titleBar, "TOPRIGHT", -6, -6)
closeButton:SetScript("OnClick", function() mainFrame:Hide() end)

-- Options button (åbner/lukker MoneyFlowSettingsFrame hvis den findes)
local optionButton = CreateFrame("Button", nil, titleBar, "GameMenuButtonTemplate")
optionButton:SetPoint("RIGHT", closeButton, "LEFT", -5, 0)
optionButton:SetSize(70, 20)
optionButton:SetText("Options")
optionButton:SetScript("OnClick", function()
    if not _G.MoneyFlowSettingsFrame then
        print("|cff00ff00MoneyFlow:|r Settings frame ikke fundet (MoneyFlowSettingsFrame).")
        return
    end

    if MoneyFlowSettingsFrame:IsShown() then
        MoneyFlowSettingsFrame:Hide()
    else
        MoneyFlowSettingsFrame:Show()
        MoneyFlowSettingsFrame:Raise()
    end
end)


--==========================================================
-- Move/Resize
--==========================================================
mainFrame:SetMovable(true)
mainFrame:EnableMouse(true)
mainFrame:RegisterForDrag("LeftButton")
mainFrame:SetScript("OnDragStart", function(self)
    self:StartMoving()
    -- only store user placement if NOT opening with bags mode
    if self.SetUserPlaced and not AnchorToBagsEnable() then
        self:SetUserPlaced(true)
    end
end)
mainFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

mainFrame:SetResizable(true)
mainFrame:SetResizeBounds(200, 150, 600, 400)

local resizeButton = CreateFrame("Button", nil, mainFrame)
resizeButton:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -2, 2)
resizeButton:SetSize(16, 16)
resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeButton:SetScript("OnMouseDown", function(_, button)
    if button == "LeftButton" and mainFrame.StartSizing then
        resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
        mainFrame:StartSizing("BOTTOMRIGHT")
        if mainFrame.SetUserPlaced then mainFrame:SetUserPlaced(true) end
    end
end)
resizeButton:SetScript("OnMouseUp", function(_, button)
    if button == "LeftButton" then
        resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        if mainFrame.StopMovingOrSizing then mainFrame:StopMovingOrSizing() end
    end
end)

--==========================================================
-- Labels/Values
--==========================================================
mainFrame.playerName = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
mainFrame.playerName:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 8, -6)
mainFrame.playerName:SetText("Character: " ..
    UnitName("player") .. "-" .. GetRealmName() .. " - Level: " .. UnitLevel("player"))

mainFrame.incomeLabel = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
mainFrame.incomeLabel:SetPoint("TOPLEFT", mainFrame.playerName, "BOTTOMLEFT", 0, -10)
mainFrame.incomeLabel:SetText("Gold Income:")

mainFrame.incomeValue = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
mainFrame.incomeValue:SetPoint("LEFT", mainFrame.incomeLabel, "RIGHT", 10, 0)

mainFrame.outgoingLabel = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
mainFrame.outgoingLabel:SetPoint("TOPLEFT", mainFrame.incomeLabel, "BOTTOMLEFT", 0, -10)
mainFrame.outgoingLabel:SetText("Gold spent:")

mainFrame.outgoingValue = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
mainFrame.outgoingValue:SetPoint("LEFT", mainFrame.outgoingLabel, "RIGHT", 10, 0)

mainFrame.totalLabel = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
mainFrame.totalLabel:SetPoint("TOPLEFT", mainFrame.outgoingLabel, "BOTTOMLEFT", 0, -10)
mainFrame.totalLabel:SetText("Total gold:")

mainFrame.totalValue = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
mainFrame.totalValue:SetPoint("LEFT", mainFrame.totalLabel, "RIGHT", 10, 0)

-- Reset button
local ResetSessionData
local resetButton = CreateFrame("BUTTON", nil, mainFrame, "GameMenuButtonTemplate")
resetButton:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT", 10, 10)
resetButton:SetSize(120, 30)
resetButton:SetText("Reset Session")
resetButton:SetScript("OnClick", function() ResetSessionData() end)

resetButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Reset the gold income and expenses for this session.", 0.8, 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)
resetButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

--==========================================================
-- Session Tracking
--==========================================================
local totalGoldEarned = 0
local totalGoldSpent  = 0
local lastMoney       = nil

local function UpdateTotalsDisplay()
    local net = totalGoldEarned - totalGoldSpent
    local text
    if net < 0 then
        text = "-" .. C_CurrencyInfo.GetCoinTextureString(-net)
        mainFrame.totalValue:SetTextColor(1, 0, 0)
    elseif net > 0 then
        text = C_CurrencyInfo.GetCoinTextureString(net)
        mainFrame.totalValue:SetTextColor(0, 1, 0)
    else
        text = C_CurrencyInfo.GetCoinTextureString(0)
        mainFrame.totalValue:SetTextColor(1, 1, 1)
    end
    mainFrame.totalValue:SetText(text)
end

local function RefreshUI()
    mainFrame.incomeValue:SetText(C_CurrencyInfo.GetCoinTextureString(totalGoldEarned))
    mainFrame.outgoingValue:SetText(C_CurrencyInfo.GetCoinTextureString(totalGoldSpent))
    UpdateTotalsDisplay()
end

ResetSessionData = function()
    totalGoldEarned = 0
    totalGoldSpent  = 0
    lastMoney       = GetMoney()
    RefreshUI()
end

RefreshUI()

--==========================================================
-- Bag providers (table-driven bag detection + anchor resolve)
--==========================================================

local function SafeGetName(obj)
    if not obj or type(obj) ~= "table" or not obj.GetName then return nil end
    local ok, name = pcall(obj.GetName, obj)
    return ok and name or nil
end

local function SafeChildren(parent)
    if not parent or not parent.GetChildren then return {} end

    -- pcall kan returnere mange values: ok, child1, child2, ...
    local results = { pcall(parent.GetChildren, parent) }

    if not results[1] then
        return {}
    end

    -- fjern ok-flaget (første element)
    table.remove(results, 1)
    return results
end




-- Each provider can:
--  - isLoaded(): optional - quick check
--  - getFrame(): returns the "root" candidate frame (or nil)
--  - resolveAnchor(frame): optional - returns the *actual* frame to hook/anchor to
--  - fallbackScan(): optional - scan UIParent children if globals are unreliable
local BagProviders = {
    {
        name = "BetterBags",
        isLoaded = function() return _G.BetterBags ~= nil or _G.BetterBagsBagBackpack ~= nil end,
        getFrame = function()
            return _G.BetterBagsBagBackpack
        end,
        resolveAnchor = function(frame)
            -- If BetterBags uses an inner container you want to anchor to,
            -- adjust here. Default to frame.
            return frame
        end,
        fallbackScan = function()
            for _, child in ipairs(SafeChildren(UIParent)) do
                if SafeIsShown(child) then
                    local n = SafeGetName(child)
                    if n and n:find("^BetterBags_") then
                        return child
                    end
                end
            end
        end,
    },
    {
        name = "ElvUI",
        isLoaded = function() return _G.ElvUI ~= nil or _G.ElvUI_ContainerFrame ~= nil end,
        getFrame = function()
            return _G.ElvUI_ContainerFrame
        end,
        resolveAnchor = function(frame)
            -- If ElvUI returns a wrapper and you need the real container, adjust here.
            return frame
        end,
    },
    {
        name = "Baganator",
        isLoaded = function() return _G.Baganator ~= nil end,
        getFrame = function()
            -- Keep your known candidates as primary
            local baganatorCandidates = {
                "Baganator_CategoryViewBackpackViewFrameBlizzard",
                "Baganator_CategoryViewBackpackViewFrame",
                "Baganator_CategoryViewBackpackViewFrameBlizzard_NineSlice",
            }
            for _, name in ipairs(baganatorCandidates) do
                if SafeIsShown(_G[name]) then return _G[name] end
            end
            -- If not shown yet, still return something if it exists:
            for _, name in ipairs(baganatorCandidates) do
                if IsFrameObject(_G[name]) then return _G[name] end
            end
        end,
        resolveAnchor = function(frame)
            return frame
        end,
        fallbackScan = function()
            for _, child in ipairs(SafeChildren(UIParent)) do
                if SafeIsShown(child) then
                    local n = SafeGetName(child)
                    if n and n:find("^Baganator_") and n:find("CategoryViewBackpackViewFrame") then
                        return child
                    end
                end
            end
        end,
    },
    {
        name = "Blizzard",
        isLoaded = function() return true end,
        getFrame = function()
            -- 12.x Combined Bags
            if IsFrameObject(_G.ContainerFrameCombinedBags) then
                return _G.ContainerFrameCombinedBags
            end
            -- Old container frames
            for i = 1, 13 do
                local f = _G["ContainerFrame" .. i]
                if IsFrameObject(f) then return f end
            end
        end,
        resolveAnchor = function(frame)
            return frame
        end,
    },
}

local function ResolveProviderAnchor(provider, requireShown)
    if provider.isLoaded and not provider.isLoaded() then
        return nil
    end

    local frame = provider.getFrame and provider.getFrame() or nil
    if (not IsFrameObject(frame)) and provider.fallbackScan then
        frame = provider.fallbackScan()
    end
    if not IsFrameObject(frame) then return nil end

    local anchor = frame
    if provider.resolveAnchor then
        local ok, resolved = pcall(provider.resolveAnchor, frame)
        if ok and IsFrameObject(resolved) then
            anchor = resolved
        end
    end

    if requireShown then
        if SafeIsShown(anchor) then return anchor end
        return nil
    end

    -- allow non-shown candidates for hooking
    return anchor
end

local function FindBagFrame(requireShown)
    for _, provider in ipairs(BagProviders) do
        local anchor = ResolveProviderAnchor(provider, requireShown)
        if anchor then
            return anchor, provider.name
        end
    end
    return nil, nil
end

--==========================================================
-- Anchoring logic
--==========================================================
--==========================================================
-- Anchoring logic (anchor to a specific resolved frame)
--==========================================================
local function AnchorToFrame(frameToAnchorTo)
    dprint("anchor target:", SafeName(frameToAnchorTo))

    if not IsFrameObject(frameToAnchorTo) or not MoneyFlowDB.settingsKeys.anchorToBags then
        return false
    end

    -- Optional debug info
    if DEBUG then
        local shown = SafeIsShown(frameToAnchorTo)
        local okA, a = pcall(frameToAnchorTo.GetAlpha, frameToAnchorTo)
        local okS, s = pcall(frameToAnchorTo.GetFrameStrata, frameToAnchorTo)
        local okL, l = pcall(frameToAnchorTo.GetFrameLevel, frameToAnchorTo)
        dprint("bag info: shown =", shown and "true" or "false",
            "alpha =", okA and a or "?",
            "strata =", okS and s or "?",
            "level =", okL and l or "?")

        local p1, rel, p2, x, y = SafeGetPoint(frameToAnchorTo, 1)
        if p1 then
            dprint("bag point:", p1, SafeName(rel), p2, x, y)
        else
            dprint("bag point: <none>")
        end
    end

    -- Force above bag UI

    mainFrame:SetClampedToScreen(true)

    mainFrame:ClearAllPoints()
    if mainFrame.SetUserPlaced then
        mainFrame:SetUserPlaced(false)
    end

    mainFrame:SetPoint(MoneyFlowDB.anchorPointMainFrame, frameToAnchorTo, MoneyFlowDB.anchorPointBagFrame, 0, 10)


    return true
end

--==========================================================
-- Bag OnShow/OnHide hooks (LAZY install)
--==========================================================
local BagHooks = {
    installed = false,
    installing = false,
    retries = 0,
    ticker = nil,
}

local function InstallBagShowHideHooks()
    if BagHooks.installed then return true end

    local bagFrame, providerName = FindBagFrame(false)
    if not IsFrameObject(bagFrame) then
        return false
    end

    if bagFrame.__MoneyFlowHooked then
        BagHooks.installed = true
        return true
    end

    bagFrame.__MoneyFlowHooked = true
    BagHooks.installed = true

    dprint("Bag hooks installed on:", SafeName(bagFrame), "provider:", providerName or "?")

    bagFrame:HookScript("OnShow", function()
        if not OpenWithBagsEnabled() then return end
        local shownFrame = select(1, FindBagFrame(true)) or bagFrame
        AnchorToFrame(shownFrame)
        mainFrame:Show()
        mainFrame:Raise()
    end)


    bagFrame:HookScript("OnHide", function()
        if not OpenWithBagsEnabled() then return end
        mainFrame:Hide()
        dprint("Bag OnHide -> MoneyFlow hidden")
    end)

    -- If bags are already shown when we hook:
    if SafeIsShown(bagFrame) and OpenWithBagsEnabled() then
        AnchorToFrame(bagFrame)
        mainFrame:Show()
        mainFrame:Raise()
    end

    return true
end


-- Lazy installer: called when bags are toggled (NOT on login)
local function EnsureBagHooksInstalledSoon()
    if BagHooks.installed or BagHooks.installing then return end
    BagHooks.installing = true
    BagHooks.retries = 0

    -- Let bag UI show first (important for ElvUI/BetterBags)
    C_Timer.After(0, function()
        if InstallBagShowHideHooks() then
            BagHooks.installing = false
            return
        end

        -- Retry quietly a few times (no spam)
        BagHooks.ticker = C_Timer.NewTicker(0.2, function()
            BagHooks.retries = BagHooks.retries + 1
            if InstallBagShowHideHooks() or BagHooks.retries >= 20 then
                if BagHooks.ticker then BagHooks.ticker:Cancel() end
                BagHooks.ticker = nil
                BagHooks.installing = false
            end
        end)
    end)
end

--==========================================================
-- “Trigger hooks” for different bag systems
--  - We hook common bag functions AND BetterBags toggle if present
--  - These triggers only *start* the lazy install and (optionally) show frame
--==========================================================
local function OnAnyBagsToggled()
    if not OpenWithBagsEnabled() then return end

    EnsureBagHooksInstalledSoon()

    -- Try to show immediately (covers first open before OnShow hooks exist)
    C_Timer.After(0, function()
        local bagFrame = select(1, FindBagFrame(true))
        local ok = false
        if IsFrameObject(bagFrame) then
            ok = AnchorToFrame(bagFrame)
            if ok then
                mainFrame:Show()
                mainFrame:Raise()
            end
        end
        dprint("Toggle -> Anchor ok =", ok and "true" or "false")
    end)
end


-- Hook Blizzard/global bag toggles (often still used by bag addons)
if ToggleBackpack then hooksecurefunc("ToggleBackpack", OnAnyBagsToggled) end
if ToggleAllBags then hooksecurefunc("ToggleAllBags", OnAnyBagsToggled) end
if OpenAllBags then hooksecurefunc("OpenAllBags", OnAnyBagsToggled) end
if CloseAllBags then
    hooksecurefunc("CloseAllBags", function()
        if OpenWithBagsEnabled() then mainFrame:Hide() end
    end)
end

-- BetterBags has its own toggle function/macro
if BetterBags_ToggleBags then hooksecurefunc("BetterBags_ToggleBags", OnAnyBagsToggled) end
if BetterBags_ToggleAllBags then hooksecurefunc("BetterBags_ToggleAllBags", OnAnyBagsToggled) end

--==========================================================
-- Slash commands
--==========================================================
SLASH_MONEYFLOW1 = "/mf"
SLASH_MONEYFLOW2 = "/moneyflow"

SlashCmdList["MONEYFLOW"] = function()
    if mainFrame:IsShown() then
        mainFrame:Hide()
    else
        mainFrame:Show()
        mainFrame:Raise()
    end
end

SLASH_MONEYFLOWRESET1 = "/mfreset"
SlashCmdList["MONEYFLOWRESET"] = function()
    ResetSessionData()
end

-- Toggle debug mode and print current bag target
SLASH_MONEYFLOWDEBUG1 = "/mfdebug"
SlashCmdList["MONEYFLOWDEBUG"] = function()
    DEBUG = not DEBUG
    print("|cff00ff00MoneyFlow:|r DEBUG =", DEBUG and "ON" or "OFF")

    local bagFrame, providerName = FindBagFrame()
    dprint("Current bag frame:", SafeName(bagFrame), "provider:", providerName or "?")

    if IsFrameObject(bagFrame) then
        local shown = SafeIsShown(bagFrame)
        local okA, a = pcall(bagFrame.GetAlpha, bagFrame)
        local okS, s = pcall(bagFrame.GetFrameStrata, bagFrame)
        local okL, l = pcall(bagFrame.GetFrameLevel, bagFrame)
        dprint("bag info: shown =", shown and "true" or "false",
            "alpha =", okA and a or "?",
            "strata =", okS and s or "?",
            "level =", okL and l or "?")
    end
end

--==========================================================
-- Event handling (NO bag hook install here)
--==========================================================
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_MONEY")

eventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        lastMoney = GetMoney()
        RefreshUI()
        -- NOTE: We do NOT install bag hooks on login (lazy mode)
        print("|cff00ff00Money Flow|r addon ready.")
    elseif event == "PLAYER_MONEY" then
        local currentMoney = GetMoney()
        if lastMoney then
            local diff = currentMoney - lastMoney
            if diff > 0 then
                totalGoldEarned = totalGoldEarned + diff
            elseif diff < 0 then
                totalGoldSpent = totalGoldSpent - diff
            end
            RefreshUI()
        end
        lastMoney = currentMoney
    end
end)
