-- UI/Format.lua

function MoneyFlow:FormatNet(net)
    net = tonumber(net) or 0

    if net < 0 then
        return "-" .. C_CurrencyInfo.GetCoinTextureString(math.abs(net)), 1, 0, 0
    elseif net > 0 then
        return C_CurrencyInfo.GetCoinTextureString(net), 0, 1, 0
    else
        return C_CurrencyInfo.GetCoinTextureString(0), 1.0, 0.82, 0.0
    end
end
