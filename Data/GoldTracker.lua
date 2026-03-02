local function getCharacterKey()
    local name = UnitName("player") or "Unknown"
    local realm = GetRealmName() or "UnknownRealm"
    return realm .. "-" .. name
end

function MoneyFlow:UpdateCharacterGold()
    if not self.db or not self.db.global then
        return
    end

    self.db.global.Characters = self.db.global.Characters or {}

    local key = getCharacterKey()
    local className, classFile = UnitClass("player")
    local name = UnitName("player") or "Unknown"
    local realm = GetRealmName() or "UnknownRealm"

    self.db.global.Characters[key] = self.db.global.Characters[key] or {}
    local entry = self.db.global.Characters[key]

    entry.key = key
    entry.name = name
    entry.realm = realm
    entry.class = classFile
    entry.className = className
    entry.gold = GetMoney() or 0
    entry.lastUpdate = time()
end

function MoneyFlow:GetGoldCharactersList()
    local list = {}
    if not self.db or not self.db.global or not self.db.global.Characters then
        return list
    end

    for key, data in pairs(self.db.global.Characters) do
        list[#list + 1] = {
            key = key,
            name = data.name or "?",
            realm = data.realm or "?",
            class = data.class,
            gold = tonumber(data.gold) or 0,
            lastUpdate = data.lastUpdate,
        }
    end

    table.sort(list, function(a, b)
        if a.gold == b.gold then
            return a.key < b.key
        end
        return a.gold > b.gold
    end)

    return list
end

function MoneyFlow:GetGoldTotal()
    local total = 0
    local rows = self:GetGoldCharactersList()
    for i = 1, #rows do
        total = total + (rows[i].gold or 0)
    end
    return total
end

function MoneyFlow:ResetGoldInfo()
    if not self.db or not self.db.global then
        return
    end

    self.db.global.Characters = {}
    self:UpdateCharacterGold()

    self:RefreshGoldFrame()

    local AceConfigRegistry = LibStub("AceConfigRegistry-3.0", true)
    if AceConfigRegistry then
        AceConfigRegistry:NotifyChange("MoneyFlow")
    end
end

function MoneyFlow:GetGoldSummaryText()
    local rows = self:GetGoldCharactersList()
    if #rows == 0 then
        return "Ingen characters registreret endnu."
    end

    local lines = {}
    for i = 1, #rows do
        local row = rows[i]
        local moneyText = GetMoneyString(row.gold or 0, true) or "0"
        lines[#lines + 1] = string.format("%s-%s: %s", row.name, row.realm, moneyText)
    end

    lines[#lines + 1] = " "
    lines[#lines + 1] = "Total: " .. (GetMoneyString(self:GetGoldTotal(), true) or "0")
    return table.concat(lines, "\n")
end
