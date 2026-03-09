local Addon = _G.MoneyFlow
if not Addon or type(Addon.RegisterAnchorProvider) ~= "function" then
    return
end
-- Anchor/Providers/ElvUI.lua

local unpack = unpack or table.unpack

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

local function GetEngine()
    local root = _G.ElvUI
    if type(root) ~= "table" then
        return nil
    end

    local ok, E = pcall(unpack, root)
    if ok and type(E) == "table" then
        return E
    end
    return nil
end

local function GetBagsModule()
    local E = GetEngine()
    if not E or type(E.GetModule) ~= "function" then
        return nil
    end

    local ok, bags = pcall(E.GetModule, E, "Bags", true)
    if ok and bags then
        return bags
    end
    return nil
end

Addon:RegisterAnchorProvider("ELVUI", {
    GetFrame = function(_, addon)
        local bags = GetBagsModule()
        if bags and IsFrameObject(bags.BagFrame) then
            return bags.BagFrame
        end
        if IsFrameObject(_G.ElvUI_ContainerFrame) then
            return _G.ElvUI_ContainerFrame
        end
        return nil
    end,

    IsVisible = function(_, addon)
        local frame = addon:GetProviderFrame("ELVUI")
        return frame and frame:IsVisible() or false
    end,

    InstallHooks = function(_, addon)
        local bags = GetBagsModule()
        if not bags then
            return false
        end

        if type(bags.OpenBags) == "function" then
            hooksecurefunc(bags, "OpenBags", function()
                addon:HookCurrentBagFrames()
                addon:ForceShowForBagOpen()
            end)
        end

        if type(bags.CloseAllBags) == "function" then
            hooksecurefunc(bags, "CloseAllBags", function()
                addon:SyncBagVisibility()
            end)
        end

        if type(bags.ToggleAllBags) == "function" then
            hooksecurefunc(bags, "ToggleAllBags", function()
                addon:HookCurrentBagFrames()
                addon:SyncBagVisibility()
            end)
        end

        return true
    end,

    HookFrames = function(_, addon)
        addon:HookBagFrame(addon:GetProviderFrame("ELVUI"))
    end,
})
