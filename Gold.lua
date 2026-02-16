local addonName, MoneyFlow = ...
--==========================================================
-- SavedVariables init
--==========================================================
MoneyFlowDB = MoneyFlowDB or {}
MoneyFlowDB.settingsKeys = MoneyFlowDB.settingsKeys or {}

MoneyFlowCharDB = MoneyFlowCharDB or {}
MoneyFlowCharDB.frameSize = MoneyFlowCharDB.frameSize or {}

MoneyFlowDB = MoneyFlowDB or {}
MoneyFlowDB.goldInfo = MoneyFlowDB.goldInfo or {}

if type(MoneyFlowCharDB.goldframeSize) ~= "table"
    or type(MoneyFlowCharDB.goldframeSize.w) ~= "number"
    or type(MoneyFlowCharDB.goldframeSize.h) ~= "number" then
    MoneyFlowCharDB.goldframeSize = { w = 320, h = 360 }
end



--==========================================================
-- Gold Frame
--==========================================================
local goldFrame = CreateFrame("Frame", "goldFrame", UIParent, "BackdropTemplate")
goldFrame:SetSize(320, 360)
goldFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
goldFrame:Hide()

goldFrame:SetBackdrop({
    bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile     = true,
    tileSize = 16,
    edgeSize = 16,
    insets   = { left = 4, right = 4, top = 4, bottom = 4 },
})
goldFrame:SetBackdropColor(0, 0, 0, 0.9)

goldFrame.totalLabel = goldFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
goldFrame.totalLabel:SetPoint("BOTTOMLEFT", goldFrame, "BOTTOMLEFT", 8, 10)
goldFrame.totalLabel:SetText("Total:")

goldFrame.totalValue = goldFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
goldFrame.totalValue:SetJustifyH("RIGHT")
goldFrame.totalValue:SetPoint("BOTTOMRIGHT", goldFrame, "BOTTOMRIGHT", -15, 10)
goldFrame.totalValue:SetText("")

MoneyFlow.goldFrame = goldFrame


-- ESC close support
tinsert(UISpecialFrames, "goldFrame")

--==========================================================
-- Move/Resize
--==========================================================

-- Movable
goldFrame:SetMovable(true)
goldFrame:SetResizable(true)
goldFrame:SetResizeBounds(240, 150, 600, 700)
goldFrame:EnableMouse(true)
goldFrame:RegisterForDrag("LeftButton")
goldFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
goldFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

local resizeButton = CreateFrame("Button", nil, goldFrame)
resizeButton:SetPoint("BOTTOMRIGHT", goldFrame, "BOTTOMRIGHT", -2, 2)
resizeButton:SetSize(16, 16)
resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeButton:SetScript("OnMouseDown", function(_, button)
    if button == "LeftButton" and goldFrame.StartSizing then
        resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
        goldFrame:StartSizing("BOTTOMRIGHT")
    end
end)

resizeButton:SetScript("OnMouseUp", function(_, button)
    if button == "LeftButton" then
        resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        goldFrame:StopMovingOrSizing()
    end

    MoneyFlowCharDB = MoneyFlowCharDB or {}
    MoneyFlowCharDB.goldframeSize = MoneyFlowCharDB.goldframeSize or { w = 320, h = 360 }

    local w, h = goldFrame:GetSize()
    MoneyFlowCharDB.goldframeSize.w = math.floor(w + 0.5)
    MoneyFlowCharDB.goldframeSize.h = math.floor(h + 0.5)
end)


--==========================================================
-- Title bar
--==========================================================
local titleBar = CreateFrame("Frame", nil, goldFrame, "BackdropTemplate")
titleBar:SetHeight(35)
titleBar:SetPoint("TOPLEFT", goldFrame, "TOPLEFT")
titleBar:SetPoint("TOPRIGHT", goldFrame, "TOPRIGHT")
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
titleText:SetText("Gold Info")

local closeButton = CreateFrame("Button", nil, titleBar, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", titleBar, "TOPRIGHT", -6, -6)
closeButton:SetScript("OnClick", function()
    goldFrame:Hide()
end)

local resetButton = CreateFrame("Button", nil, titleBar, "GameMenuButtonTemplate")
resetButton:SetPoint("RIGHT", closeButton, "LEFT", -5, 0)
resetButton:SetSize(90, 20)
resetButton:SetText("Reset data")
resetButton:SetScript("OnClick", function()
    MoneyFlow:ResetGoldInfo()
end)

resetButton:SetScript("OnClick", function()
    StaticPopupDialogs["MONEYFLOW_RESET_GOLDINFO"] = {
        text = "Reset all saved gold info for all characters?",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
            MoneyFlow:ResetGoldInfo()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("MONEYFLOW_RESET_GOLDINFO")
end)



--==========================================================
-- Character info table
--==========================================================
local function GetPlayerKey()
    local name = UnitName("player")
    local realm = GetRealmName()
    return realm .. "-" .. name
end

-- Denne er lavet som en "Method" hvad betyder det, for den er vel ikke global ?
function MoneyFlow:UpdateGoldInfo()
    MoneyFlowDB = MoneyFlowDB or {}
    MoneyFlowDB.goldInfo = MoneyFlowDB.goldInfo or {}

    local key = GetPlayerKey()
    MoneyFlowDB.goldInfo[key] = MoneyFlowDB.goldInfo[key] or {}

    local className, classFile = UnitClass("player")

    local entry = MoneyFlowDB.goldInfo[key]
    entry.name = UnitName("player")
    entry.realm = GetRealmName()
    entry.gold = GetMoney()
    entry.class = classFile
    entry.lastUpdate = time()
end

function MoneyFlow:GetGoldList()
    local list = {}
    if not MoneyFlowDB or not MoneyFlowDB.goldInfo then return list end

    for _, data in pairs(MoneyFlowDB.goldInfo) do
        table.insert(list, {
            name = data.name or "?",
            realm = data.realm or "?",
            gold = data.gold or 0,
            class = data.class,
        })
    end

    table.sort(list, function(a, b) return a.gold > b.gold end)
    return list
end

function MoneyFlow:GetTotalGold()
    local total = 0
    if not MoneyFlowDB or not MoneyFlowDB.goldInfo then return 0 end

    for _, data in pairs(MoneyFlowDB.goldInfo) do
        total = total + (data.gold or 0)
    end

    return total
end

function MoneyFlow:ResetGoldInfo()
    if not MoneyFlowDB then MoneyFlowDB = {} end
    MoneyFlowDB.goldInfo = {} -- wipe alle chars

    -- (valgfrit) re-seed current character så listen ikke bliver tom
    self:UpdateGoldInfo()

    -- re-render hvis frame findes
    if self.goldFrame then
        self:RenderGoldFrame(self.goldFrame)
    end
end

--==========================================================
-- Labels/Values
--==========================================================

function MoneyFlow:RenderGoldFrame(goldFrame)
    goldFrame.lines = goldFrame.lines or {}

    local rows = self:GetGoldList()


    local maxLines = 15
    local lineHeight = 20

    for i = 1, maxLines do
        local line = goldFrame.lines[i]

        if not line then
            line = {}

            -- Name (LEFT)
            local fsName = goldFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            fsName:SetJustifyH("LEFT")
            fsName:SetPoint("TOPLEFT", goldFrame, "TOPLEFT", 8, -40 - (i - 1) * lineHeight)


            -- Gold (RIGHT)
            local fsGold = goldFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            fsGold:SetJustifyH("RIGHT")
            fsGold:SetPoint("TOPRIGHT", goldFrame, "TOPRIGHT", -8, -40 - (i - 1) * lineHeight)

            line.name = fsName
            line.gold = fsGold

            goldFrame.lines[i] = line
        end

        local row = rows[i]

        if row then
            local color = row.class and C_ClassColor.GetClassColor(row.class)
            if color then
                line.name:SetTextColor(color:GetRGB())
            else
                line.name:SetTextColor(1, 1, 1)
            end

            line.name:SetText(row.name)

            line.gold:SetText(GetMoneyString(row.gold, true))



            line.name:Show()
            line.gold:Show()
        else
            line.name:SetText("")
            line.gold:SetText("")

            line.name:Hide()
            line.gold:Hide()
        end
    end

    local total = self:GetTotalGold()
    goldFrame.totalValue:SetText(GetMoneyString(total, true))
end
