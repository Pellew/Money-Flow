function MoneyFlow:InitSession()
    self.db.profile.Session.StartMoney = GetMoney()
    self.db.profile.Session.Earned = 0
    self.db.profile.Session.Spent = 0
    self.db.profile.Session.Net = 0
    self.LastMoney = GetMoney()
end

-- Handling all the data for MoneyChanged
function MoneyFlow:MoneyChanged()
    -- Guard to make sure self.LastMoney doesn't return a nil
    if not self.LastMoney then
        self.LastMoney = GetMoney()
        return
    end

    self.CurrentMoney = GetMoney()

    local earned = 0
    local spent = 0

    if self.CurrentMoney > self.LastMoney then
        earned = self.CurrentMoney - self.LastMoney
        self.db.profile.Session.Earned = self.db.profile.Session.Earned + earned
    elseif
        self.CurrentMoney < self.LastMoney then
        spent = self.LastMoney - self.CurrentMoney
        self.db.profile.Session.Spent = self.db.profile.Session.Spent + spent
    end
    self.LastMoney = self.CurrentMoney
    self.db.profile.Session.Net = self.db.profile.Session.Earned - self.db.profile.Session.Spent

    -- Debug print
    local session = self:GetSessionData()

    self:dprint("StartMoney: ", session.StartMoney)
    self:dprint("Earned: ", session.Earned)
    self:dprint("Spent: ", session.Spent)
    self:dprint("Net: ", session.Net)
end

-- Helper function to reset session data
function MoneyFlow:ResetSessionData()
    self.db.profile.Session.StartMoney = GetMoney()
    self.db.profile.Session.Earned = 0
    self.db.profile.Session.Spent = 0
    self.db.profile.Session.Net = 0
    self.LastMoney = GetMoney()
end

-- Helper function to return session data
function MoneyFlow:GetSessionData()
    local data = {
        StartMoney = self.db.profile.Session.StartMoney,
        Earned = self.db.profile.Session.Earned,
        Spent = self.db.profile.Session.Spent,
        Net = self.db.profile.Session.Net,
    }
    return data
end
