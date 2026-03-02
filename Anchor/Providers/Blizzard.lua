-- Anchor/Providers/Blizzard.lua

MoneyFlow:RegisterAnchorProvider("BLIZZARD", {
    GetFrame = function(_, addon)
        if _G.ContainerFrameCombinedBags then
            return _G.ContainerFrameCombinedBags
        end
        if _G.ContainerFrame1 then
            return _G.ContainerFrame1
        end
        return nil
    end,

    IsVisible = function(_, addon)
        local frame = addon:GetProviderFrame("BLIZZARD")
        return frame and frame:IsVisible() or false
    end,

    InstallHooks = function(_, addon)
        return true
    end,

    HookFrames = function(_, addon)
        addon:HookBagFrame(addon:GetProviderFrame("BLIZZARD"))
    end,
})
