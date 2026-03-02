-- Debug printer helper
function MoneyFlow:dprint(...)
    local DEBUG = self.db.profile.Debug

    if DEBUG then
        print("|cff00ff00MoneyFlow:|r", ...)
    end
end
