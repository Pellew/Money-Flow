-- Anchor/Providers/Registry.lua

MoneyFlow.AnchorProviders = MoneyFlow.AnchorProviders or {}

function MoneyFlow:RegisterAnchorProvider(id, provider)
    if type(id) ~= "string" or id == "" or type(provider) ~= "table" then
        return
    end
    self.AnchorProviders[id:upper()] = provider
end

function MoneyFlow:GetAnchorProvider(id)
    if type(id) ~= "string" then
        return nil
    end
    return self.AnchorProviders[id:upper()]
end

function MoneyFlow:GetProviderFrame(id)
    local provider = self:GetAnchorProvider(id)
    if not provider or type(provider.GetFrame) ~= "function" then
        return nil
    end

    local ok, frame = pcall(provider.GetFrame, provider, self)
    if ok then
        return frame
    end
    return nil
end

function MoneyFlow:IsProviderVisible(id)
    local provider = self:GetAnchorProvider(id)
    if not provider then
        return false
    end

    if type(provider.IsVisible) == "function" then
        local ok, visible = pcall(provider.IsVisible, provider, self)
        return ok and visible == true or false
    end

    local frame = self:GetProviderFrame(id)
    return frame and frame:IsVisible() or false
end

function MoneyFlow:InstallProviderHooks(id)
    self._providerHooksInstalled = self._providerHooksInstalled or {}

    local key = (id or ""):upper()
    if key == "" or self._providerHooksInstalled[key] then
        return
    end

    local provider = self:GetAnchorProvider(key)
    if not provider or type(provider.InstallHooks) ~= "function" then
        self._providerHooksInstalled[key] = true
        return
    end

    local ok, result = pcall(provider.InstallHooks, provider, self)
    if ok and result ~= false then
        self._providerHooksInstalled[key] = true
    end
end

function MoneyFlow:HookProviderFrames(id)
    local provider = self:GetAnchorProvider(id)
    if not provider then
        return
    end

    if type(provider.HookFrames) == "function" then
        pcall(provider.HookFrames, provider, self)
        return
    end

    local frame = self:GetProviderFrame(id)
    if frame then
        self:HookBagFrame(frame)
    end
end
