local theme = require("app.theme")
local runtime = require("app.runtime")
local ui = require("app.ui")

local screens = {}

local function shipTime()
    return textutils.formatTime(os.time(), true)
end

function screens.home(selected)
    ui.frame(theme.brandName, "Pfeile Seiten  M/Leertaste Alarm  Q Ende")
    ui.statusBar(selected)
    ui.center(7, theme.subtitle, theme.accentLight, theme.accent)
    ui.right(7, shipTime(), theme.text, theme.accent)
    ui.center(8, "Nur mit vorhandenen Mods: Create, Redstone, ComputerCraft", theme.text, theme.accent)
    ui.center(9, selected.shipName, theme.muted, theme.accent)

    ui.panel(4, 10, 18, 8, " Schiff ")
    ui.skull(7, 12)

    ui.panel(24, 10, 25, 8, " Status ")
    ui.kv(26, 12, "Schub", selected.helm.thrust, theme.warning)
    ui.kv(38, 12, "Kurs", selected.helm.heading, theme.text)
    ui.kv(26, 15, "Fabrik", selected.factory.lineA, theme.ok)
    local alarmText, alarmColor = runtime.alarmStatus(selected)
    ui.kv(38, 15, "Alarm", alarmText, alarmColor)

    ui.center(20, "Schnellzugriff", theme.accentLight, theme.accent)
    ui.menu(21, { "Steuerung", "Fabrik", "Alarmzentrale", "System" }, selected.selectedIndex - 1)
end

function screens.helm(state)
    ui.frame("Steuerung", "B Zurueck")
    ui.statusBar(state)
    ui.center(7, "Luftschiff-Steuerung ueber Signalleitungen", theme.accentLight, theme.accent)
    ui.statusRow(10, "Schub", state.helm.thrust, theme.warning)
    ui.statusRow(12, "Kurs", state.helm.heading, theme.text)
    ui.statusRow(14, "Hoehe", state.helm.altitude, theme.text)
    ui.statusRow(16, "Sicherheitsmodus", state.helm.failsafe, theme.ok)
    ui.statusRow(18, "Naechster Schritt", "Hebel und Kupplungen zuordnen", theme.muted)
    ui.statusRow(20, "Alarmtaste", "M oder Leertaste", theme.accentLight)
end

function screens.factory(state)
    ui.frame("Fabrik", "B Zurueck")
    ui.statusBar(state)
    ui.center(7, "Create-Produktionsuebersicht", theme.accentLight, theme.accent)
    ui.statusRow(10, "Linie A", state.factory.lineA, theme.text)
    ui.statusRow(12, "Treibstoff", state.factory.fuel, theme.warning)
    ui.statusRow(14, "Lager", state.factory.storage, theme.text)
    ui.statusRow(16, "Modus", state.factory.mode, theme.ok)
    ui.statusRow(18, "Naechster Schritt", "Start- und Stoplinien festlegen", theme.muted)
end

function screens.alarms(state)
    ui.frame("Alarmzentrale", "B Zurueck")
    ui.statusBar(state)
    ui.center(7, "Warnungen, Stoerungen und manueller Alarm", theme.accentLight, theme.accent)
    local alarmText, alarmColor = runtime.alarmStatus(state)
    local speakerText, speakerColor = runtime.speakerStatus(state)
    ui.statusRow(10, "Manueller Alarm", alarmText, alarmColor)
    ui.statusRow(12, "Speaker", speakerText, speakerColor)
    ui.statusRow(14, "Kollision", "Kein Sensor verbunden", theme.warning)
    ui.statusRow(16, "Treibstoff", "Grenzwert fehlt", theme.warning)
    ui.statusRow(18, "Bedienung", "M oder Leertaste schaltet Sirene", theme.muted)
end

function screens.settings(state)
    ui.frame("System", "B Zurueck")
    ui.statusBar(state)
    ui.center(7, "Branding und Signalsetup", theme.accentLight, theme.accent)
    ui.statusRow(10, "Palette", "Magisches Lila", theme.accentLight)
    ui.statusRow(12, "Symbol", "Totenkopf", theme.text)
    ui.statusRow(14, "Startseite", "Hauptmenue", theme.text)
    ui.statusRow(16, "Speicher", "ComputerCraft-Datentraeger", theme.ok)
end

return screens
