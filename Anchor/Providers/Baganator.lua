local Addon = _G.MoneyFlow
if not Addon or type(Addon.RegisterAnchorProvider) ~= "function" then
    return
end
-- Anchor/Providers/Baganator.lua

local FRAME_CANDIDATES = {
    "Baganator_SingleViewBackpackViewFrame",
    "Baganator_CategoryViewBackpackViewFrame",
    "Baganator_SingleViewBackpackViewFrameBlizzard",
    "Baganator_CategoryViewBackpackViewFrameBlizzard",
}

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

local function GetFrames(addon)
    local out, seen = {}, {}

    local function addFrame(f)
        if not IsAnchorFrame(f) or seen[f] then
            return
        end
        seen[f] = true
        out[#out + 1] = f
    end

    local b = _G.Baganator
    if b and b.ViewManagement and b.ViewManagement.GetBackpackFrame then
        local ok, frame = pcall(b.ViewManagement.GetBackpackFrame)
        if ok then
            addFrame(frame)
        end
    end

    for _, name in ipairs(FRAME_CANDIDATES) do
        addFrame(_G[name])
    end

    for name, obj in pairs(_G) do
        if type(name) == "string"
            and name:match("^Baganator_[A-Za-z]+ViewBackpackViewFrame[A-Za-z0-9_]*$")
            and not name:find("CloseButton")
            and not name:find("NineSlice") then
            addFrame(obj)
        end
    end

    return out
end

Addon:RegisterAnchorProvider("BAGANATOR", {
    GetFrames = function(_, addon)
        return GetFrames(addon)
    end,

    GetFrame = function(self, addon)
        local frames = self:GetFrames(addon)
        for _, f in ipairs(frames) do
            if f:IsVisible() then
                return f
            end
        end
        return frames[1]
    end,

    IsVisible = function(self, addon)
        local frames = self:GetFrames(addon)
        for _, f in ipairs(frames) do
            if f:IsVisible() then
                return true
            end
        end
        return false
    end,

    InstallHooks = function(self, addon)
        local b = _G.Baganator
        if not (b and b.CallbackRegistry and b.CallbackRegistry.RegisterCallback) then
            return false
        end

        b.CallbackRegistry:RegisterCallback("BagShow", function()
            addon:HookCurrentBagFrames()
            addon:ForceShowForBagOpen()
        end)

        b.CallbackRegistry:RegisterCallback("BagHide", function()
            if addon.moneyFrame and addon:OpenWithBags() then
                addon.moneyFrame:Hide()
            end
        end)

        b.CallbackRegistry:RegisterCallback("BackpackFrameChanged", function(_, frame)
            addon:HookBagFrame(frame)
            addon:HookCurrentBagFrames()

            if addon.moneyFrame and addon.moneyFrame:IsShown() and addon:AnchorToBags() then
                C_Timer.After(0, function()
                    addon:ApplyBagAnchor()
                end)
            end
        end)

        return true
    end,

    HookFrames = function(self, addon)
        for _, f in ipairs(self:GetFrames(addon)) do
            addon:HookBagFrame(f)
        end
    end,
})
