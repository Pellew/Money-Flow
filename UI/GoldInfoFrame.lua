function MoneyFlow:BuildGoldFrame()
    if self.goldFrame then
        return self.goldFrame
    end

    local db = self.db and self.db.profile and self.db.profile.GoldFrame
    local width = (db and db.Width) or 360
    local height = (db and db.Height) or 360

    local frame = CreateFrame("Frame", "MoneyFlowGoldInfoFrame", UIParent, "BackdropTemplate")
    frame:SetSize(width, height)
    frame:SetPoint("CENTER", UIParent, "CENTER", 20, 0)
    frame:Hide()
    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("DIALOG")

    frame.isPinned = false
    frame.isPreview = false

    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0, 0, 0, 0.9)

    frame:HookScript("OnHide", function(self)
        self.isPinned = false
        self.isPreview = false
    end)


    tinsert(UISpecialFrames, "MoneyFlowGoldInfoFrame")

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
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    titleBar:SetBackdropColor(0.2, 0.2, 0.2, 1)

    local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("LEFT", titleBar, "LEFT", 8, 0)
    titleText:SetText("Gold Info")

    local closeButton = CreateFrame("Button", nil, titleBar, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", titleBar, "TOPRIGHT", -6, -6)
    closeButton:SetScript("OnClick", function()
        frame.isPinned = false
        frame.isPreview = false
        frame:Hide()
    end)

    local resetButton = CreateFrame("Button", nil, titleBar, "GameMenuButtonTemplate")
    resetButton:SetPoint("RIGHT", closeButton, "LEFT", -5, 0)
    resetButton:SetSize(90, 20)
    resetButton:SetText("Reset data")
    resetButton:GetFontString():SetTextColor(1.0, 0.82, 0.0)
    resetButton:SetScript("OnClick", function()
        StaticPopupDialogs["MONEYFLOW_CONFIRM_RESET_GOLD"] = StaticPopupDialogs["MONEYFLOW_CONFIRM_RESET_GOLD"] or {
            text = "Reset all saved character gold data?",
            button1 = YES,
            button2 = NO,
            OnAccept = function()
                MoneyFlow:ResetGoldInfo()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("MONEYFLOW_CONFIRM_RESET_GOLD")
    end)

    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:SetResizeBounds(280, 220, 700, 800)
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
    resizeButton:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then
            resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
            frame:StopMovingOrSizing()
        end

        if MoneyFlow.db and MoneyFlow.db.profile and MoneyFlow.db.profile.GoldFrame then
            local w, h = frame:GetSize()
            MoneyFlow.db.profile.GoldFrame.Width = math.floor(w + 0.5)
            MoneyFlow.db.profile.GoldFrame.Height = math.floor(h + 0.5)
        end
    end)

    frame.totalLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.totalLabel:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 8, 10)
    frame.totalLabel:SetText("Total:")

    frame.totalValue = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.totalValue:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 10)
    frame.totalValue:SetJustifyH("RIGHT")
    frame.totalValue:SetText("")

    frame.lines = {}

    frame.titleBar = titleBar
    frame.closeButton = closeButton
    frame.resetButton = resetButton
    frame.resizeButton = resizeButton

    self.goldFrame = frame
    self:ApplyFrameStrata()
    return frame
end

function MoneyFlow:RefreshGoldFrame()
    local frame = self:BuildGoldFrame()
    if not frame then
        return
    end

    local rows = self:GetGoldCharactersList()
    local maxLines = 16
    local lineHeight = 18
    local startY = -42

    for i = 1, maxLines do
        local line = frame.lines[i]
        if not line then
            line = {}

            line.name = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            line.name:SetJustifyH("LEFT")
            line.name:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, startY - (i - 1) * lineHeight)

            line.gold = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            line.gold:SetJustifyH("RIGHT")

            line.remove = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
            line.remove:SetSize(18, 18)
            line.remove:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, startY - (i - 1) * lineHeight + 6)
            line.remove:SetScript("OnClick", function(button)
                if not button.characterKey then
                    return
                end

                StaticPopupDialogs["MONEYFLOW_CONFIRM_REMOVE_GOLD_CHARACTER"] =
                    StaticPopupDialogs["MONEYFLOW_CONFIRM_REMOVE_GOLD_CHARACTER"] or {
                        text = "Remove saved gold data for %s?",
                        button1 = YES,
                        button2 = NO,
                        OnAccept = function(_, data)
                            if data and data.key then
                                MoneyFlow:RemoveGoldCharacter(data.key)
                            end
                        end,
                        timeout = 0,
                        whileDead = true,
                        hideOnEscape = true,
                        preferredIndex = 3,
                    }

                StaticPopup_Show(
                    "MONEYFLOW_CONFIRM_REMOVE_GOLD_CHARACTER",
                    button.characterName or button.characterKey,
                    nil,
                    { key = button.characterKey }
                )
            end)
            line.remove:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText("Remove this character from the overview.", 0.8, 0.8, 0.8)
                GameTooltip:Show()
            end)
            line.remove:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)

            frame.lines[i] = line
        end

        line.gold:ClearAllPoints()
        line.gold:SetPoint(
            "TOPRIGHT",
            frame,
            "TOPRIGHT",
            frame.isPreview and -8 or -30,
            startY - (i - 1) * lineHeight
        )

        local row = rows[i]
        if row then
            local characterName = row.name or "?"
            local color = row.class and C_ClassColor.GetClassColor(row.class)
            if color then
                line.name:SetTextColor(color:GetRGB())
            else
                line.name:SetTextColor(1, 1, 1)
            end

            line.name:SetText(characterName)
            line.gold:SetText(GetMoneyString(row.gold or 0, true) or "0")
            line.remove.characterKey = row.key
            line.remove.characterName = characterName
            line.name:Show()
            line.gold:Show()
            if frame.isPreview then
                line.remove:Hide()
            else
                line.remove:Show()
            end
        else
            line.name:SetText("")
            line.gold:SetText("")
            line.remove.characterKey = nil
            line.remove.characterName = nil
            line.name:Hide()
            line.gold:Hide()
            line.remove:Hide()
        end
    end

    frame.totalValue:SetText(GetMoneyString(self:GetGoldTotal(), true) or "0")
    frame.totalValue:SetTextColor(1.0, 0.82, 0.0)
end

function MoneyFlow:ToggleGoldFrame()
    local frame = self:BuildGoldFrame()

    if frame:IsShown() and frame.isPinned then
        frame.isPinned = false
        frame.isPreview = false
        frame:Hide()
        return
    end

    frame.isPinned = true
    frame.isPreview = false

    self:RefreshGoldFrame()

    frame:SetAlpha(1)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetResizable(true)

    frame.titleBar:EnableMouse(true)
    frame.closeButton:Show()
    frame.resetButton:Show()
    frame.resizeButton:Show()

    if not frame:IsShown() then
        frame:Show()
    end
    frame:Raise()
end

local function PlacePreviewAboveMainOrFallback(frame, moneyFrame, hoverAnchor)
    local fw, fh = frame:GetWidth(), frame:GetHeight()
    local gap = 8
    local margin = 12

    local parentLeft = UIParent:GetLeft() or 0
    local parentRight = UIParent:GetRight() or GetScreenWidth()
    local parentTop = UIParent:GetTop() or GetScreenHeight()
    local parentBottom = UIParent:GetBottom() or 0

    local function tryPlaceAbove(baseFrame)
        local l = baseFrame:GetLeft()
        local r = baseFrame:GetRight()
        local t = baseFrame:GetTop()
        if not l or not r or not t then
            return false
        end

        local x = l + ((r - l) - fw) / 2
        local y = t + gap

        local left = x
        local bottom = y
        local right = x + fw
        local top = y + fh

        if left >= parentLeft + margin and right <= parentRight - margin and bottom >= parentBottom + margin and top <= parentTop - margin then
            frame:ClearAllPoints()
            frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
            return true
        end
        return false
    end

    if moneyFrame and moneyFrame:IsShown() and tryPlaceAbove(moneyFrame) then
        return
    end

    if hoverAnchor and tryPlaceAbove(hoverAnchor) then
        return
    end

    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
end

function MoneyFlow:ShowGoldPreview(anchorFrame)
    local profile = self.db and self.db.profile and self.db.profile.GoldFrame
    if profile and profile.PreviewOnHover == false then
        return
    end

    local frame = self:BuildGoldFrame()
    if frame.isPinned then
        return
    end

    frame.isPreview = true
    frame.isPinned = false

    self:RefreshGoldFrame()

    frame:SetAlpha(0.96)
    frame:EnableMouse(false)
    frame:SetMovable(false)
    frame:SetResizable(false)

    frame.titleBar:EnableMouse(false)
    frame.closeButton:Hide()
    frame.resetButton:Hide()
    frame.resizeButton:Hide()

    PlacePreviewAboveMainOrFallback(frame, self.moneyFrame, anchorFrame)

    frame:Show()
    frame:Raise()
end

function MoneyFlow:HideGoldPreview()
    local frame = self.goldFrame
    if not frame then
        return
    end

    if frame.isPinned then
        return
    end

    frame.isPreview = false
    frame:Hide()
end
