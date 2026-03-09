local anchorPoints = {
    TOPLEFT = "Top Left",
    TOP = "Top",
    TOPRIGHT = "Top Right",
    LEFT = "Left",
    CENTER = "Center",
    RIGHT = "Right",
    BOTTOMLEFT = "Bottom Left",
    BOTTOM = "Bottom",
    BOTTOMRIGHT = "Bottom Right",
}

local providerValues = {
    AUTO = "Auto (BetterBags -> ElvUI -> Baganator -> Blizzard -> UIParent)",
    BETTERBAGS = "BetterBags",
    ELVUI = "ElvUI",
    BAGANATOR = "Baganator",
    BLIZZARD = "Blizzard Bags",
    MANUAL = "Manual Frame Name",
}

local strataValues = {
    BACKGROUND = "Background",
    LOW = "Low",
    MEDIUM = "Medium",
    HIGH = "High",
    DIALOG = "Dialog",
    FULLSCREEN = "Fullscreen",
    FULLSCREEN_DIALOG = "Fullscreen Dialog",
    TOOLTIP = "Tooltip",
}

function MoneyFlow:SetupOptions()
    if self.optionsCategoryID then
        return
    end

    local options = {
        type = "group",
        name = "Money Flow",
        childGroups = "tab",
        args = {
            general = {
                type = "group",
                name = "General",
                order = 1,
                args = {
                    openWithBags = {
                        type = "toggle",
                        name = "Open With Bags",
                        desc = "Show/hide Money Flow with bag window actions.",
                        order = 1,
                        get = function() return self.db.profile.MainFrame.OpenWithBags end,
                        set = function(_, value)
                            self.db.profile.MainFrame.OpenWithBags = value
                            if not value and self.moneyFrame then
                                self.moneyFrame:Hide()
                            end
                        end,
                    },
                    anchorToBags = {
                        type = "toggle",
                        name = "Anchor To Bags",
                        desc = "Attach Money Flow to bag target frame.",
                        order = 2,
                        get = function() return self.db.profile.MainFrame.AnchorToBags end,
                        set = function(_, value)
                            self.db.profile.MainFrame.AnchorToBags = value
                            self:ApplyBagAnchor()
                        end,
                    },
                    provider = {
                        type = "select",
                        name = "Anchor Provider",
                        values = providerValues,
                        order = 3,
                        get = function() return self.db.profile.Anchor.Provider end,
                        set = function(_, value)
                            self.db.profile.Anchor.Provider = value
                            self:ApplyBagAnchor()
                        end,
                    },
                    manualFrameName = {
                        type = "input",
                        name = "Manual Frame Name",
                        desc = "Example: ContainerFrameCombinedBags",
                        order = 4,
                        disabled = function() return self.db.profile.Anchor.Provider ~= "MANUAL" end,
                        get = function() return self.db.profile.Anchor.ManualFrameName or "" end,
                        set = function(_, value)
                            self.db.profile.Anchor.ManualFrameName = value
                            self:ApplyBagAnchor()
                        end,
                    },
                    parentAnchor = {
                        type = "select",
                        name = "Target Anchor Point",
                        values = anchorPoints,
                        order = 5,
                        get = function() return self.db.profile.MainFrame.ParentAnchor end,
                        set = function(_, value)
                            self.db.profile.MainFrame.ParentAnchor = value
                            self:ApplyBagAnchor()
                        end,
                    },
                    moneyTrackAnchor = {
                        type = "select",
                        name = "Money Flow Anchor Point",
                        values = anchorPoints,
                        order = 6,
                        get = function()
                            return self.db.profile.MainFrame.MoneyFlowAnchor or
                                self.db.profile.MainFrame.MoneyTrackAnchor
                        end,
                        set = function(_, value)
                            self.db.profile.MainFrame.MoneyFlowAnchor = value
                            self:ApplyBagAnchor()
                        end,
                    },
                    xOffset = {
                        type = "range",
                        name = "X Offset",
                        min = -500,
                        max = 500,
                        step = 1,
                        order = 7,
                        get = function() return self.db.profile.MainFrame.XOffset end,
                        set = function(_, value)
                            self.db.profile.MainFrame.XOffset = value
                            self:ApplyBagAnchor()
                        end,
                    },
                    yOffset = {
                        type = "range",
                        name = "Y Offset",
                        min = -500,
                        max = 500,
                        step = 1,
                        order = 8,
                        get = function() return self.db.profile.MainFrame.YOffset end,
                        set = function(_, value)
                            self.db.profile.MainFrame.YOffset = value
                            self:ApplyBagAnchor()
                        end,
                    },
                    frameLayer = {
                        type = "select",
                        name = "Frame Layer",
                        desc = "Choose how high/low Money Flow is drawn in the UI.",
                        values = strataValues,
                        order = 9,
                        get = function()
                            return self.db.profile.MainFrame.FrameStrata or "DIALOG"
                        end,
                        set = function(_, value)
                            self.db.profile.MainFrame.FrameStrata = value
                            self:ApplyFrameStrata()
                        end,
                    },
                },
            },

            commands = {
                type = "group",
                name = "Commands",
                order = 2,
                args = {
                    intro = {
                        type = "description",
                        order = 1,
                        fontSize = "medium",
                        name = "Available slash commands:",
                    },
                    c1 = { type = "description", order = 2, name = "/mf - Toggle Money Flow frame" },
                    c2 = { type = "description", order = 3, name = "/mfdebug - Toggle debug ON/OFF" },
                    c3 = { type = "description", order = 4, name = "/mfprovider - Show provider status" },
                    c4 = { type = "description", order = 5, name = "/mfgold - Toggle Gold Info frame" },
                    c5 = { type = "description", order = 6, name = "/moneyflow - Toggle frame" },
                    c6 = { type = "description", order = 7, name = "/moneyflow provider - Show provider status" },
                    c7 = { type = "description", order = 8, name = "/moneyflow debug - Toggle debug ON/OFF" },
                    c8 = { type = "description", order = 9, name = "/moneyflow gold - Toggle Gold Info frame" },
                },
            },

            gold = {
                type = "group",
                name = "Gold",
                order = 3,
                args = {
                    openGoldFrame = {
                        type = "execute",
                        name = "Open Gold Info Frame",
                        order = 1,
                        func = function()
                            self:ToggleGoldFrame()
                        end,
                    },
                    hoverPreview = {
                        type = "toggle",
                        name = "Show Gold Preview On Hover",
                        desc = "Show Gold Info as a preview when you mouse over the Gold Info button.",
                        order = 2,
                        get = function()
                            return self.db.profile.GoldFrame.PreviewOnHover
                        end,
                        set = function(_, value)
                            self.db.profile.GoldFrame.PreviewOnHover = value
                            if not value then
                                self:HideGoldPreview()
                            end
                        end,
                    },
                    resetGoldData = {
                        type = "execute",
                        name = "Reset Saved Gold Data",
                        confirm = true,
                        confirmText = "Reset all saved character gold data?",
                        order = 3,
                        func = function()
                            self:ResetGoldInfo()
                        end,
                    },
                    summaryHeader = {
                        type = "description",
                        order = 4,
                        fontSize = "medium",
                        name = "Saved Characters",
                    },
                    summary = {
                        type = "description",
                        order = 5,
                        fontSize = "small",
                        name = function()
                            return self:GetGoldSummaryText()
                        end,
                    },
                },
            },

            profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db, true),
        },
    }

    options.args.profiles.order = 4
    options.args.profiles.name = "Profiles"

    LibStub("AceConfig-3.0"):RegisterOptionsTable("MoneyFlow", options)
    local _, categoryID = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("MoneyFlow", "Money Flow")
    self.optionsCategoryID = categoryID
end

function MoneyFlow:OpenOptions()
    if InCombatLockdown() then
        self:Print("Options are disabled during combat.")
        return
    end

    if Settings and Settings.OpenToCategory and self.optionsCategoryID then
        Settings.OpenToCategory(self.optionsCategoryID)
    end
end
