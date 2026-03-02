-- UI/Layout.lua

function MoneyFlow:BuildLayout()
    local frame = self.moneyFrame
    local titleBar = self.titleBar

    if not frame or not titleBar then
        return
    end

    -- Avoid creating widgets multiple times
    if frame.layoutBuilt then
        return
    end
    frame.layoutBuilt = true

    frame.playerName = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.playerName:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 8, -6)
    frame.playerName:SetText("Character: " ..
        UnitName("player") .. "-" .. GetRealmName() .. " - Level: " .. UnitLevel("player"))

    frame.earnedLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.earnedLabel:SetPoint("TOPLEFT", frame.playerName, "BOTTOMLEFT", 0, -10)
    frame.earnedLabel:SetText("Gold Income:")

    frame.earnedValue = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.earnedValue:SetPoint("LEFT", frame.earnedLabel, "RIGHT", 10, 0)

    frame.spentLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.spentLabel:SetPoint("TOPLEFT", frame.earnedLabel, "BOTTOMLEFT", 0, -10)
    frame.spentLabel:SetText("Gold Spent:")

    frame.spentValue = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.spentValue:SetPoint("LEFT", frame.spentLabel, "RIGHT", 10, 0)

    frame.netLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.netLabel:SetPoint("TOPLEFT", frame.spentLabel, "BOTTOMLEFT", 0, -10)
    frame.netLabel:SetText("Net:")

    frame.netValue = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.netValue:SetPoint("LEFT", frame.netLabel, "RIGHT", 10, 0)
end

function MoneyFlow:RefreshFrame()
    local frame = self.moneyFrame
    if not frame then
        return
    end

    -- Ensure layout exists before updating text
    self:BuildLayout()

    local data = self:GetSessionData()
    if not data then
        return
    end

    local netText, r, g, b = self:FormatNet(data.Net or 0)
    frame.netValue:SetText(netText)
    frame.netValue:SetTextColor(r, g, b)

    frame.earnedValue:SetText(C_CurrencyInfo.GetCoinTextureString(data.Earned or 0))
    frame.spentValue:SetText(C_CurrencyInfo.GetCoinTextureString(data.Spent or 0))
end
