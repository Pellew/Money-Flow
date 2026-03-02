local frame = CreateFrame("Frame", "MoneyFlowFrame", UIParent, "BackdropTemplate")

local db = MoneyFlow and MoneyFlow.db
local mainFrameDB = db and db.profile and db.profile.MainFrame

local width = (mainFrameDB and mainFrameDB.Width) or 300
local height = (mainFrameDB and mainFrameDB.Height) or 180

frame:SetSize(width, height)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

frame:Hide()
frame:SetClampedToScreen(true)
frame:SetFrameStrata("DIALOG")

frame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})

frame:SetBackdropColor(0, 0, 0, 0.9)

tinsert(UISpecialFrames, "MoneyFlowFrame")

local titleBar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
titleBar:SetHeight(35)
titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT")
titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
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
closeButton:SetScript("OnClick", function()
    frame:Hide()
end)

local optionsButton = CreateFrame("Button", nil, titleBar, "GameMenuButtonTemplate")
optionsButton:SetPoint("RIGHT", closeButton, "LEFT", -4, 0)
optionsButton:SetSize(80, 20)
optionsButton:SetText("Options")
optionsButton:GetFontString():SetTextColor(1.0, 0.82, 0.0)
optionsButton:SetScript("OnClick", function()
    MoneyFlow:OpenOptions()
end)

frame:SetMovable(true)
frame:EnableMouse(true)
titleBar:EnableMouse(true)
titleBar:RegisterForDrag("LeftButton")
titleBar:SetScript("OnDragStart", function()
    frame:StartMoving()
end)
titleBar:SetScript("OnDragStop", function()
    frame:StopMovingOrSizing()
end)

local resizeButton = CreateFrame("Button", nil, frame)
resizeButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
resizeButton:SetSize(16, 16)
resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeButton:SetScript("OnMouseDown", function(_, button)
    if button == "LeftButton" and frame.StartSizing then
        resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
        frame:StartSizing("BOTTOMRIGHT")
    end
end)

frame:SetResizable(true)
frame:SetResizeBounds(300, 180, 1080, 1080)

resizeButton:SetScript("OnMouseUp", function(_, button)
    if button == "LeftButton" then
        resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        frame:StopMovingOrSizing()
    end

    local dbase = MoneyFlow and MoneyFlow.db
    if not dbase or not dbase.profile or not dbase.profile.MainFrame then
        return
    end

    local w, h = frame:GetSize()
    dbase.profile.MainFrame.Width = math.floor(w + 0.5)
    dbase.profile.MainFrame.Height = math.floor(h + 0.5)
end)

local resetButton = CreateFrame("BUTTON", nil, frame, "GameMenuButtonTemplate")
resetButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 10)
resetButton:SetSize(120, 30)
resetButton:GetFontString():SetTextColor(1.0, 0.82, 0.0)
resetButton:SetText("Reset Session")
resetButton:SetScript("OnClick", function()
    MoneyFlow:ResetSessionData()
    MoneyFlow:RefreshFrame()
end)

resetButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Reset the gold income and expenses for this session.", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)
resetButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

local goldInfoButton = CreateFrame("BUTTON", nil, frame, "GameMenuButtonTemplate")
goldInfoButton:SetPoint("LEFT", resetButton, "RIGHT", 8, 0)
goldInfoButton:SetSize(120, 30)
goldInfoButton:GetFontString():SetTextColor(1.0, 0.82, 0.0)
goldInfoButton:SetText("Gold Info")

goldInfoButton:SetScript("OnClick", function()
    MoneyFlow:ToggleGoldFrame()
end)

goldInfoButton:SetScript("OnEnter", function(self)
    MoneyFlow:ShowGoldPreview(self)
end)

goldInfoButton:SetScript("OnLeave", function()
    MoneyFlow:HideGoldPreview()
end)

MoneyFlow.moneyFrame = frame
MoneyFlow.titleBar = titleBar
