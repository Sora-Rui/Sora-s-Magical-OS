local theme = require("app.theme")
local runtime = require("app.runtime")
local ui = require("app.ui")

local screens = {}

local function shipTime()
    return textutils.formatTime(os.time(), true)
end

function screens.home(selected)
    local width, height = term.getSize()
    local buttonY = height - 2
    ui.frame(theme.brandName, "Pfeile/Touch  M Alarm  N Name  Q Ende")
    ui.statusBar(selected)
    ui.center(7, theme.subtitle, theme.accentLight, theme.accent)
    ui.right(7, shipTime(), theme.text, theme.accent)
    ui.center(8, selected.shipName, theme.text, theme.accent)

    ui.panel(3, 10, 14, 8, " Schiff ")
    ui.skull(6, 12)

    ui.panel(19, 10, width - 21, 8, " Uebersicht ")
    ui.kv(21, 12, "Schub", selected.helm.thrust, theme.warning)
    ui.kv(math.max(31, width - 15), 12, "Kurs", selected.helm.heading, theme.text)
    local alarmText, alarmColor = runtime.alarmStatus(selected)
    ui.kv(21, 15, "Alarm", alarmText, alarmColor)
    ui.kv(math.max(31, width - 15), 15, "Speaker", runtime.speakerStatus(selected))

    ui.button(selected, 3, buttonY, 10, "Steuerung", "helm", selected.activeScreen == "helm")
    ui.button(selected, 15, buttonY, 8, "Fabrik", "factory", selected.activeScreen == "factory")
    ui.button(selected, 25, buttonY, 7, "Alarm", "alarms", selected.activeScreen == "alarms")
    ui.button(selected, 34, buttonY, 8, "System", "settings", selected.activeScreen == "settings")
    if runtime.isAlarmVisible(selected) then
        ui.warningOverlay("ALARM", { "Manueller Alarm aktiv", "Speaker und Alarmausgang laufen" }, true)
    end
end

function screens.helm(state)
    local _, height = term.getSize()
    local buttonY = height - 2
    ui.frame("Steuerung", "B Zurueck")
    ui.statusBar(state)
    ui.center(7, "Steuerung ueber Signalleitungen", theme.accentLight, theme.accent)
    ui.statusRow(10, "Schub", state.helm.thrust, theme.warning)
    ui.statusRow(12, "Kurs", state.helm.heading, theme.text)
    ui.statusRow(14, "Hoehe", state.helm.altitude, theme.text)
    ui.statusRow(16, "Sicherheitsmodus", state.helm.failsafe, theme.ok)
    ui.statusRow(18, "Helmsignal", runtime.describeAssignment(state, "helmSignalSide"), theme.text)
    ui.button(state, 6, buttonY, 16, "Signalseite", "map_helm")
    if runtime.isAlarmVisible(state) then
        ui.warningOverlay("ALARM", { "Steuerdeck im Alarmmodus" }, true)
    end
end

function screens.factory(state)
    local _, height = term.getSize()
    local buttonY = height - 2
    ui.frame("Fabrik", "B Zurueck")
    ui.statusBar(state)
    ui.center(7, "Create-Uebersicht", theme.accentLight, theme.accent)
    ui.statusRow(10, "Linie A", state.factory.lineA, theme.text)
    ui.statusRow(12, "Treibstoff", state.factory.fuel, theme.warning)
    ui.statusRow(14, "Lager", state.factory.storage, theme.text)
    ui.statusRow(16, "Modus", state.factory.mode, theme.ok)
    ui.statusRow(18, "Tanksensor", runtime.describeAssignment(state, "fuelSensorSide"), theme.text)
    ui.button(state, 6, buttonY, 16, "Tanksensor", "map_fuel")
    if runtime.isAlarmVisible(state) then
        ui.warningOverlay("ALARM", { "Fabrik im Alarmmodus" }, true)
    end
end

function screens.alarms(state)
    local _, height = term.getSize()
    local buttonY = height - 2
    ui.frame("Alarmzentrale", "B Zurueck")
    ui.statusBar(state)
    ui.center(7, "Warnungen und Sirene", theme.accentLight, theme.accent)
    local alarmText, alarmColor = runtime.alarmStatus(state)
    local speakerText, speakerColor = runtime.speakerStatus(state)
    ui.statusRow(10, "Manueller Alarm", alarmText, alarmColor)
    ui.statusRow(12, "Speaker", speakerText, speakerColor)
    ui.statusRow(14, "Alarmausgang", runtime.describeAssignment(state, "alarmOutputSide"), theme.text)
    ui.button(state, 6, buttonY, 14, "Alarm an/aus", "toggle_alarm", state.manualAlarm)
    ui.button(state, 23, buttonY, 13, "Alarmseite", "map_alarm")
    ui.warningOverlay("ALARM", { "Sirene aktivieren mit M", "oder Touch auf Alarm an/aus" }, runtime.isAlarmVisible(state))
end

function screens.settings(state)
    local _, height = term.getSize()
    local buttonY = height - 2
    ui.frame("System", "B Zurueck")
    ui.statusBar(state)
    ui.center(7, "Schiff und Zuordnung", theme.accentLight, theme.accent)
    ui.statusRow(10, "Schiffsname", state.shipName, theme.text)
    ui.statusRow(12, "Monitor", state.monitor and "Verbunden" or "Nicht gefunden", state.monitor and theme.ok or theme.warning)
    ui.statusRow(14, "Helm", runtime.describeAssignment(state, "helmSignalSide"), theme.text)
    ui.statusRow(16, "Tank", runtime.describeAssignment(state, "fuelSensorSide"), theme.text)
    ui.statusRow(18, "Alarm", runtime.describeAssignment(state, "alarmOutputSide"), theme.text)
    ui.button(state, 4, buttonY, 16, "Name aendern", "rename_ship")
    ui.button(state, 22, buttonY, 11, "Helmseite", "map_helm")
    ui.button(state, 35, buttonY, 10, "Tankseite", "map_fuel")
    if runtime.isAlarmVisible(state) then
        ui.warningOverlay("ALARM", { "Systemoberflaeche gesperrt" }, true)
    end
end

return screens
