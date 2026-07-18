local Addon = _G.MoneyFlow
if not Addon or type(Addon.RegisterAnchorProvider) ~= "function" then
    return
end
-- Anchor/Providers/EllesmereUI.lua

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

local function Defer(callback)
    if C_Timer and C_Timer.After then
        C_Timer.After(0, callback)
        return
    end
    callback()
end

Addon:RegisterAnchorProvider("ELLESMEREUI", {
    GetFrame = function(_, addon)
        if IsFrameObject(_G.EUI_Bags) then
            return _G.EUI_Bags
        end
        if IsFrameObject(_G.EUI_MainBagFrame) then
            return _G.EUI_MainBagFrame
        end
        return nil
    end,

    IsVisible = function(_, addon)
        local frame = addon:GetProviderFrame("ELLESMEREUI")
        return frame and frame:IsVisible() or false
    end,

    InstallHooks = function(_, addon)
        local frame = addon:GetProviderFrame("ELLESMEREUI")
        if not frame then
            return false
        end

        local function syncAfterToggle()
            Defer(function()
                addon:HookCurrentBagFrames()
                addon:SyncBagVisibility()
            end)
        end

        if type(_G.ToggleAllBags) == "function" then
            hooksecurefunc("ToggleAllBags", syncAfterToggle)
        end
        if type(_G.ToggleBackpack) == "function" then
            hooksecurefunc("ToggleBackpack", syncAfterToggle)
        end
        if type(_G.ToggleBag) == "function" then
            hooksecurefunc("ToggleBag", syncAfterToggle)
        end
        if type(_G.OpenAllBags) == "function" then
            hooksecurefunc("OpenAllBags", function()
                Defer(function()
                    addon:HookCurrentBagFrames()
                    addon:ForceShowForBagOpen()
                end)
            end)
        end
        if type(_G.CloseAllBags) == "function" then
            hooksecurefunc("CloseAllBags", syncAfterToggle)
        end

        addon:HookBagFrame(frame)
        return true
    end,

    HookFrames = function(_, addon)
        addon:HookBagFrame(addon:GetProviderFrame("ELLESMEREUI"))
    end,
})
