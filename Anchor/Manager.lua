-- Anchor/Manager.lua

local PROVIDER_PRIORITY = { "BETTERBAGS", "ELVUI", "BAGANATOR", "BLIZZARD" }

function MoneyFlow:OpenWithBags()
    return self.db and self.db.profile and self.db.profile.MainFrame.OpenWithBags == true
end

function MoneyFlow:AnchorToBags()
    return self.db and self.db.profile and self.db.profile.MainFrame.AnchorToBags == true
end

local function IsFrameObject(obj)
    if not obj then
        return false
    end
    local t = type(obj)
    if t ~= "table" and t ~= "userdata" then
        return false
    end
    if not obj.IsObjectType then
        return false
    end
    local ok, isFrame = pcall(obj.IsObjectType, obj, "Frame")
    return ok and isFrame
end

local function IsAnchorFrame(obj)
    if not IsFrameObject(obj) then
        return false
    end
    if obj:IsObjectType("Button") then
        return false
    end

    local name = obj.GetName and obj:GetName() or ""
    if type(name) == "string" and (name:find("CloseButton") or name:find("NineSlice")) then
        return false
    end
    return true
end

function MoneyFlow:GetProviderPriority()
    return PROVIDER_PRIORITY
end

function MoneyFlow:IsAnyBagVisible()
    for _, id in ipairs(self:GetProviderPriority()) do
        if self:IsProviderVisible(id) then
            return true
        end
    end
    return false
end

function MoneyFlow:GetAnchorTargetFrame()
    local provider = (self.db.profile.Anchor.Provider or "AUTO"):upper()

    if provider == "MANUAL" then
        local name = self.db.profile.Anchor.ManualFrameName
        if name and name ~= "" and IsAnchorFrame(_G[name]) then
            return _G[name]
        end
        return UIParent
    end

    if provider ~= "AUTO" then
        return self:GetProviderFrame(provider) or UIParent
    end

    for _, id in ipairs(self:GetProviderPriority()) do
        if self:IsProviderVisible(id) then
            local frame = self:GetProviderFrame(id)
            if frame then
                return frame
            end
        end
    end

    for _, id in ipairs(self:GetProviderPriority()) do
        local frame = self:GetProviderFrame(id)
        if frame then
            return frame
        end
    end

    return UIParent
end

function MoneyFlow:ApplyBagAnchor()
    if not self.moneyFrame or not self:AnchorToBags() then
        return
    end

    local main = self.db.profile.MainFrame
    local target = self:GetAnchorTargetFrame() or UIParent

    self.moneyFrame:ClearAllPoints()
    self.moneyFrame:SetPoint(
        main.MoneyFlowAnchor or main.MoneyTrackAnchor or "CENTER",
        target,
        main.ParentAnchor or "CENTER",
        main.XOffset or 0,
        main.YOffset or 0
    )
end

function MoneyFlow:SyncBagVisibility()
    if not self.moneyFrame or not self:OpenWithBags() then
        return
    end

    if self:IsAnyBagVisible() then
        if self:AnchorToBags() then
            self:ApplyBagAnchor()
        end
        self.moneyFrame:Show()
    else
        self.moneyFrame:Hide()
    end
end

function MoneyFlow:ForceShowForBagOpen()
    if not self.moneyFrame or not self:OpenWithBags() then
        return
    end

    if self:AnchorToBags() then
        self:ApplyBagAnchor()
    end
    self.moneyFrame:Show()
end

function MoneyFlow:HookBagFrame(frame)
    if not IsAnchorFrame(frame) then
        return
    end

    self._hookedBagFrames = self._hookedBagFrames or {}
    if self._hookedBagFrames[frame] then
        return
    end
    self._hookedBagFrames[frame] = true

    frame:HookScript("OnShow", function()
        self:ForceShowForBagOpen()
    end)

    frame:HookScript("OnHide", function()
        self:SyncBagVisibility()
    end)
end

function MoneyFlow:HookCurrentBagFrames()
    for _, id in ipairs(self:GetProviderPriority()) do
        self:HookProviderFrames(id)
    end
end

function MoneyFlow:InstallAllProviderHooks()
    for _, id in ipairs(self:GetProviderPriority()) do
        self:InstallProviderHooks(id)
    end
end

function MoneyFlow:InstallBagToggleHooks()
    if self.bagToggleHooksInstalled then
        return
    end
    self.bagToggleHooksInstalled = true

    hooksecurefunc("ToggleBackpack", function()
        self:HookCurrentBagFrames()
        self:SyncBagVisibility()
    end)

    hooksecurefunc("ToggleAllBags", function()
        self:HookCurrentBagFrames()
        self:SyncBagVisibility()
    end)

    hooksecurefunc("OpenAllBags", function()
        self:HookCurrentBagFrames()
        self:ForceShowForBagOpen()
    end)

    hooksecurefunc("CloseAllBags", function()
        self:SyncBagVisibility()
    end)

    if type(_G.BetterBags_ToggleBags) == "function" then
        hooksecurefunc("BetterBags_ToggleBags", function()
            self:HookCurrentBagFrames()
            self:SyncBagVisibility()
        end)
    end

    self:InstallAllProviderHooks()
    self:HookCurrentBagFrames()
end
