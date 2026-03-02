function MoneyFlow:PLAYER_MONEY()
    self:MoneyChanged()
    self:UpdateCharacterGold()
    self:RefreshFrame()
    self:RefreshGoldFrame()
end

function MoneyFlow:PLAYER_ENTERING_WORLD(event, isInitialLogin, isReloadingUi)
    self:dprint("PLAYER_ENTERING_WORLD", "isInitialLogin:", isInitialLogin, "isReloadingUi:", isReloadingUi)

    if isInitialLogin == true then
        self:dprint("Initial login detected -> resetting session")
        self:dprint("Money Track loaded")

        self:InitSession()
        self:UpdateCharacterGold()
        self:RefreshFrame()
        self:RefreshGoldFrame()
    end

    if isReloadingUi == true then
        self:dprint("UI reload detected -> keeping session, refreshing LastMoney baseline")
        self.LastMoney = GetMoney()
        self:UpdateCharacterGold()
        self:RefreshFrame()
        self:RefreshGoldFrame()
    end
end
