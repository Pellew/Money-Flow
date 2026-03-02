function MoneyFlow:SlashDebug()
    self.db.profile.Debug = not self.db.profile.Debug
    print("|cff00ff00MoneyFlow:|r DEBUG =", self.db.profile.Debug and "ON" or "OFF")
end

local function GetFrameName(frame)
    if not frame then
        return "nil"
    end
    return (frame.GetName and frame:GetName()) or tostring(frame)
end

function MoneyFlow:SlashProviderStatus()
    if not self.db or not self.db.profile then
        print("|cff00ff00MoneyFlow:|r DB not ready")
        return
    end

    local selected = (self.db.profile.Anchor and self.db.profile.Anchor.Provider) or "AUTO"
    local target = self:GetAnchorTargetFrame()
    local visibleProvider = nil
    local visibleFrame = nil

    for _, id in ipairs(self:GetProviderPriority()) do
        if self:IsProviderVisible(id) then
            visibleProvider = id
            visibleFrame = self:GetProviderFrame(id)
            break
        end
    end

    local moneyFrameShown = self.moneyFrame and self.moneyFrame:IsShown() or false
    local openWithBags = self:OpenWithBags()
    local anchorToBags = self:AnchorToBags()

    print("|cff00ff00MoneyFlow:|r Provider status")
    print("|cff00ff00MoneyFlow:|r Selected =", selected)
    print("|cff00ff00MoneyFlow:|r Visible provider =", visibleProvider or "none")
    print("|cff00ff00MoneyFlow:|r Visible frame =", GetFrameName(visibleFrame))
    print("|cff00ff00MoneyFlow:|r Anchor target =", GetFrameName(target))
    print("|cff00ff00MoneyFlow:|r OpenWithBags =", tostring(openWithBags), "| AnchorToBags =", tostring(anchorToBags))
    print("|cff00ff00MoneyFlow:|r MoneyFrame shown =", tostring(moneyFrameShown))
end

function MoneyFlow:SlashToggleFrame()
    if not self.moneyFrame then
        print("|cff00ff00MoneyFlow:|r MoneyFlow frame not initialized")
        return
    end

    if self.moneyFrame:IsShown() then
        self.moneyFrame:Hide()
        return
    end

    if self:AnchorToBags() then
        if self:IsAnyBagVisible() then
            self:ApplyBagAnchor()
        end
    else
        local main = self.db and self.db.profile and self.db.profile.MainFrame
        self.moneyFrame:ClearAllPoints()
        self.moneyFrame:SetPoint(
            (main and (main.MoneyFlowAnchor or main.MoneyTrackAnchor)) or "CENTER",
            UIParent,
            (main and main.ParentAnchor) or "CENTER",
            (main and main.XOffset) or 0,
            (main and main.YOffset) or 0
        )
    end
    self.moneyFrame:Show()
end

function MoneyFlow:SlashGoldFrame()
    self:ToggleGoldFrame()
end

function MoneyFlow:SlashMainCommand(input)
    local arg = (input or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")

    if arg == "provider" or arg == "status" then
        self:SlashProviderStatus()
        return
    end

    if arg == "debug" then
        self:SlashDebug()
        return
    end

    if arg == "gold" or arg == "goldinfo" then
        self:SlashGoldFrame()
        return
    end

    self:SlashToggleFrame()
end
