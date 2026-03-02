local defaults = {
    profile = {
        MainFrame = {
            ParentFrameName = "UIParent",
            ParentSelectMode = "UIParent",
            ParentAnchor = "CENTER",
            MoneyFlowAnchor = "CENTER",
            XOffset = 0,
            YOffset = 0,
            Width = 300,
            Height = 180,
            Locked = false,
            Shown = true,
            OpenWithBags = true,
            AnchorToBags = true,
        },

        GoldFrame = {
            Width = 360,
            Height = 360,
            PreviewOnHover = true,
        },

        Display = {
            ShowSession = true,
            ShowCurrentGold = true,
            ShortFormat = false,
        },

        Session = {
            StartMoney = 0,
            Earned = 0,
            Spent = 0,
            Net = 0,
        },

        Anchor = {
            Mode = "AUTO",
            Provider = "AUTO",
            ManualFrameName = "",
            ParentAnchor = "TOPRIGHT",
            MoneyFlowAnchor = "TOPRIGHT",
            XOffset = 4,
            YOffset = 0,
        },

        Debug = false,
    },

    global = {
        Characters = {},
    },
}

function MoneyFlow:InitDB()
    -- One-time migration path after rename: reuse old saved data if new key is empty.
    if type(_G.MoneyFlowDB) ~= "table" and type(_G.MoneyTrackDB) == "table" then
        _G.MoneyFlowDB = _G.MoneyTrackDB
    end

    self.db = LibStub("AceDB-3.0"):New("MoneyFlowDB", defaults, true)

    -- Backward compatibility for pre-rename anchor keys in existing profiles.
    local profile = self.db and self.db.profile
    if profile and profile.MainFrame and profile.MainFrame.MoneyFlowAnchor == nil and profile.MainFrame.MoneyTrackAnchor ~= nil then
        profile.MainFrame.MoneyFlowAnchor = profile.MainFrame.MoneyTrackAnchor
    end
    if profile and profile.Anchor and profile.Anchor.MoneyFlowAnchor == nil and profile.Anchor.MoneyTrackAnchor ~= nil then
        profile.Anchor.MoneyFlowAnchor = profile.Anchor.MoneyTrackAnchor
    end
end
