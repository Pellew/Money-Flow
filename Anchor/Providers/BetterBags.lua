-- Anchor/Providers/BetterBags.lua

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

local function GetAddon()
    local aceAddon = LibStub and LibStub("AceAddon-3.0", true)
    if aceAddon and aceAddon.GetAddon then
        return aceAddon:GetAddon("BetterBags", true)
    end
    return nil
end

local function GetBagObject()
    local addon = GetAddon()
    if addon and addon.Bags and addon.Bags.Backpack then
        return addon.Bags.Backpack
    end
    return nil
end

MoneyFlow:RegisterAnchorProvider("BETTERBAGS", {
    GetFrame = function(_, addon)
        local bag = GetBagObject()
        if bag and IsFrameObject(bag.frame) then
            return bag.frame
        end
        if IsFrameObject(_G.BetterBagsBagBackpack) then
            return _G.BetterBagsBagBackpack
        end
        return nil
    end,

    IsVisible = function(_, addon)
        local frame = addon:GetProviderFrame("BETTERBAGS")
        return frame and frame:IsVisible() or false
    end,

    InstallHooks = function(_, addon)
        local bb = GetAddon()
        if not bb then
            return false
        end

        if type(bb.ToggleAllBags) == "function" then
            hooksecurefunc(bb, "ToggleAllBags", function()
                addon:HookCurrentBagFrames()
                addon:SyncBagVisibility()
            end)
        end

        local bag = GetBagObject()
        if bag then
            if type(bag.Show) == "function" then
                hooksecurefunc(bag, "Show", function()
                    addon:ForceShowForBagOpen()
                end)
            end
            if type(bag.Hide) == "function" then
                hooksecurefunc(bag, "Hide", function()
                    addon:SyncBagVisibility()
                end)
            end
        end

        return true
    end,

    HookFrames = function(_, addon)
        addon:HookBagFrame(addon:GetProviderFrame("BETTERBAGS"))
    end,
})
