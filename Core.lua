MoneyFlow = LibStub("AceAddon-3.0"):NewAddon("MoneyFlow", "AceConsole-3.0", "AceEvent-3.0")

function MoneyFlow:OnInitialize()
    self:InitDB()
    self:SetupOptions()
end

function MoneyFlow:OnEnable()
    self:RegisterEvent("PLAYER_MONEY")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("BAG_OPEN", "SyncBagVisibility")
    self:RegisterEvent("BAG_CLOSED", "SyncBagVisibility")
    self:RegisterEvent("ADDON_LOADED")

    self:BuildLayout()
    self:RefreshFrame()
    self:UpdateCharacterGold()
    self:RefreshGoldFrame()
    self:ApplyBagAnchor()

    self:InstallBagToggleHooks()
    self:InstallAllProviderHooks()
    self:HookCurrentBagFrames()
    self:SyncBagVisibility()

    self:RegisterChatCommand("mfdebug", "SlashDebug")
    self:RegisterChatCommand("mf", "SlashToggleFrame")
    self:RegisterChatCommand("mfgold", "SlashGoldFrame")
    self:RegisterChatCommand("mfprovider", "SlashProviderStatus")
    self:RegisterChatCommand("moneyflow", "SlashMainCommand")
    self:RegisterChatCommand("mflow", "SlashMainCommand")
end

function MoneyFlow:ADDON_LOADED(_, addonName)
    if addonName == "Baganator" or addonName == "BetterBags" or addonName == "ElvUI" then
        self:InstallAllProviderHooks()
        self:HookCurrentBagFrames()
        self:SyncBagVisibility()
    end
end
