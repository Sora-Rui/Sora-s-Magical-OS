local theme = require("smos.app.theme")
local ui = require("smos.app.ui")

local screens = {}

function screens.home(selected)
    ui.frame(theme.brandName, "H Helm  F Factory  A Alarms  S Settings  Q Quit")
    ui.center(3, theme.subtitle, theme.accentLight, theme.accent)
    ui.center(5, "Existing mods only: Create, Redstone, ComputerCraft", theme.text, theme.accent)
    ui.center(7, "Prototype control deck for ship and factory signals", theme.muted, theme.accent)
    ui.jollyRoger(5, 10)
    ui.menu(12, { "Helm", "Factory", "Alarms", "Settings" }, selected)
end

function screens.helm()
    ui.frame("Helm", "B Back")
    ui.center(3, "Airship helm routing over signal channels", theme.accentLight, theme.accent)
    ui.statusRow(6, "Thrust", "Idle", theme.warning)
    ui.statusRow(8, "Heading", "Awaiting redstone bus", theme.text)
    ui.statusRow(10, "Altitude", "Manual only", theme.text)
    ui.statusRow(12, "Failsafe", "Armed", theme.ok)
    ui.statusRow(14, "Next step", "Map helm levers and clutch logic", theme.muted)
end

function screens.factory()
    ui.frame("Factory", "B Back")
    ui.center(3, "Create production overview", theme.accentLight, theme.accent)
    ui.statusRow(6, "Line A", "Standby", theme.text)
    ui.statusRow(8, "Fuel", "Check tank observer", theme.warning)
    ui.statusRow(10, "Cargo", "Pending sensor map", theme.text)
    ui.statusRow(12, "Mode", "Existing mods only", theme.ok)
    ui.statusRow(14, "Next step", "Define startup and shutdown lanes", theme.muted)
end

function screens.alarms()
    ui.frame("Alarms", "B Back")
    ui.center(3, "Jolly Roger warning board", theme.accentLight, theme.accent)
    ui.statusRow(6, "Collision", "No sensor linked", theme.warning)
    ui.statusRow(8, "Fuel", "Threshold unset", theme.warning)
    ui.statusRow(10, "Factory", "No active faults", theme.ok)
    ui.statusRow(12, "Network", "Local deck only", theme.text)
end

function screens.settings()
    ui.frame("Settings", "B Back")
    ui.center(3, "Branding and signal setup", theme.accentLight, theme.accent)
    ui.statusRow(6, "Palette", "Royal Purple", theme.accentLight)
    ui.statusRow(8, "Insignia", "Jolly Roger", theme.text)
    ui.statusRow(10, "Boot target", "Home", theme.text)
    ui.statusRow(12, "Storage", "ComputerCraft disk", theme.ok)
end

return screens
