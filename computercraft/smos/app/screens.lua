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
    if ui.isLargeLayout() then
        ui.monitorFrame(theme.brandName, theme.subtitle, selected)
        ui.navTabs(selected, 8, "home")

        ui.panel(4, 10, 22, 11, " Symbol ")
        ui.drawSymbol(selected, 8, 13)

        ui.metricPanel(28, 10, 16, " Schub ", selected.helm.thrust, theme.warning, "Antrieb")
        ui.metricPanel(46, 10, 16, " Kurs ", selected.helm.heading, theme.text, "Ruder")
        local alarmText, alarmColor = runtime.alarmStatus(selected)
        ui.metricPanel(64, 10, 16, " Alarm ", alarmText, alarmColor, "Status")

        ui.panel(28, 16, 52, 9, " Brueckensteuerung ")
        ui.writeAt(30, 18, "Schiffsname", theme.muted, theme.panel)
        ui.writeAt(30, 19, selected.shipName, theme.text, theme.panel)
        ui.writeAt(30, 21, "Touch auf eine Karte oder nutze die Leiste oben.", theme.muted, theme.panel)
        ui.button(selected, 30, 23, 16, "Name aendern", "rename_ship")
        ui.button(selected, 49, 23, 15, "Alarm", "toggle_alarm", selected.manualAlarm)
        ui.button(selected, 67, 23, 11, "System", "settings")

        if runtime.isAlarmVisible(selected) then
            ui.warningOverlay("ALARM", { "Brueckenalarm aktiv", "Touch auf Alarm zum Stummschalten" }, true)
        end
        return
    end

    ui.frame(theme.brandName, "Pfeile/Touch  M Alarm  N Name  Q Ende", selected)
    ui.statusBar(selected)
    ui.center(7, theme.subtitle, theme.accentLight, theme.accent)
    ui.right(7, shipTime(), theme.text, theme.accent)
    ui.center(8, selected.shipName, theme.text, theme.accent)

    ui.panel(3, 10, 14, 8, " Schiff ")
    ui.drawSymbol(selected, 5, 12)

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
    if ui.isLargeLayout() then
        ui.monitorFrame("Steuerung", "Helm und Redstone-Ausgaenge", state)
        ui.navTabs(state, 8, "helm")
        ui.metricPanel(4, 10, 16, " Schub ", state.helm.thrust, theme.warning, runtime.describeAssignment(state, "thrustOutputSide"))
        ui.metricPanel(22, 10, 16, " Kurs ", state.helm.heading, theme.text, runtime.describeAssignment(state, "helmSignalSide"))
        ui.metricPanel(40, 10, 16, " Hoehe ", state.helm.altitude, theme.text, "Manuell")
        ui.metricPanel(58, 10, 20, " Sicherheit ", state.helm.failsafe, theme.ok, "Failsafe")

        ui.panel(4, 16, 74, 9, " Helmsteuerung ")
        ui.button(state, 8, 18, 14, "Schub", "toggle_thrust", state.outputs.thrust)
        ui.button(state, 24, 18, 14, "Backbord", "turn_port", state.outputs.turnLeft)
        ui.button(state, 40, 18, 16, "Steuerbord", "turn_starboard", state.outputs.turnRight)
        ui.button(state, 58, 18, 14, "Still", "turn_stop")
        ui.button(state, 8, 21, 14, "Helmsignal", "map_helm")
        ui.button(state, 24, 21, 14, "Schub I/O", "map_thrust")
        ui.button(state, 40, 21, 16, "Backbord I/O", "map_port")
        ui.button(state, 58, 21, 16, "Steuerbord I/O", "map_starboard")

        if runtime.isAlarmVisible(state) then
            ui.warningOverlay("ALARM", { "Steuerdeck im Alarmmodus" }, true)
        end
        return
    end

    ui.frame("Steuerung", "B Zurueck", state)
    ui.statusBar(state)
    ui.center(7, "Steuerung ueber Signalleitungen", theme.accentLight, theme.accent)
    ui.statusRow(10, "Schub", state.helm.thrust, theme.warning)
    ui.statusRow(12, "Kurs", state.helm.heading, theme.text)
    ui.statusRow(14, "Hoehe", state.helm.altitude, theme.text)
    ui.statusRow(16, "Sicherheitsmodus", state.helm.failsafe, theme.ok)
    ui.statusRow(18, "Helmsignal", runtime.describeAssignment(state, "helmSignalSide"), theme.text)
    ui.button(state, 4, buttonY - 1, 12, "Schub", "toggle_thrust", state.outputs.thrust)
    ui.button(state, 18, buttonY - 1, 12, "Backbord", "turn_port", state.outputs.turnLeft)
    ui.button(state, 32, buttonY - 1, 13, "Steuerbord", "turn_starboard", state.outputs.turnRight)
    ui.button(state, 4, buttonY, 12, "Still", "turn_stop")
    ui.button(state, 18, buttonY, 12, "Signal", "map_helm")
    ui.button(state, 32, buttonY, 13, "Schub I/O", "map_thrust")
    if runtime.isAlarmVisible(state) then
        ui.warningOverlay("ALARM", { "Steuerdeck im Alarmmodus" }, true)
    end
end

function screens.factory(state)
    local _, height = term.getSize()
    local buttonY = height - 2
    if ui.isLargeLayout() then
        ui.monitorFrame("Fabrik", "Maschinen, Sensoren und Hauptschalter", state)
        ui.navTabs(state, 8, "factory")
        ui.metricPanel(4, 10, 18, " Linie A ", state.factory.lineA, theme.text, "Produktionsstatus")
        ui.metricPanel(24, 10, 18, " Treibstoff ", state.factory.fuel, theme.warning, runtime.describeAssignment(state, "fuelSensorSide"))
        ui.metricPanel(44, 10, 18, " Modus ", state.factory.mode, theme.ok, "Fabrik")
        ui.metricPanel(64, 10, 14, " Lager ", state.factory.storage, theme.text, "Sensor")

        ui.panel(4, 16, 74, 9, " Fabriksteuerung ")
        ui.button(state, 8, 18, 16, "Fabrik an/aus", "toggle_factory", state.outputs.factoryEnabled)
        ui.button(state, 27, 18, 15, "Tanksensor", "map_fuel")
        ui.button(state, 45, 18, 16, "Fabrik I/O", "map_factory_output")
        ui.writeAt(8, 21, "Verbinde den Fabrik-Ausgang mit einem Redstone-Glied,", theme.muted, theme.panel)
        ui.writeAt(8, 22, "das deine Create-Anlage freischaltet oder sperrt.", theme.muted, theme.panel)

        if runtime.isAlarmVisible(state) then
            ui.warningOverlay("ALARM", { "Fabrik im Alarmmodus" }, true)
        end
        return
    end

    ui.frame("Fabrik", "B Zurueck", state)
    ui.statusBar(state)
    ui.center(7, "Create-Uebersicht", theme.accentLight, theme.accent)
    ui.statusRow(10, "Linie A", state.factory.lineA, theme.text)
    ui.statusRow(12, "Treibstoff", state.factory.fuel, theme.warning)
    ui.statusRow(14, "Lager", state.factory.storage, theme.text)
    ui.statusRow(16, "Modus", state.factory.mode, theme.ok)
    ui.statusRow(18, "Tanksensor", runtime.describeAssignment(state, "fuelSensorSide"), theme.text)
    ui.button(state, 4, buttonY - 1, 15, "Fabrik an/aus", "toggle_factory", state.outputs.factoryEnabled)
    ui.button(state, 21, buttonY - 1, 14, "Tanksensor", "map_fuel")
    ui.button(state, 37, buttonY - 1, 11, "Fabrik I/O", "map_factory_output")
    if runtime.isAlarmVisible(state) then
        ui.warningOverlay("ALARM", { "Fabrik im Alarmmodus" }, true)
    end
end

function screens.alarms(state)
    local _, height = term.getSize()
    local buttonY = height - 2
    if ui.isLargeLayout() then
        ui.monitorFrame("Alarmzentrale", "Sirene, Speaker und Warnzustand", state)
        ui.navTabs(state, 8, "alarms")
        local alarmText, alarmColor = runtime.alarmStatus(state)
        local speakerText, speakerColor = runtime.speakerStatus(state)
        ui.metricPanel(4, 10, 18, " Alarm ", alarmText, alarmColor, "Manuell")
        ui.metricPanel(24, 10, 18, " Speaker ", speakerText, speakerColor, "Peripheral")
        ui.metricPanel(44, 10, 18, " Ausgang ", runtime.describeAssignment(state, "alarmOutputSide"), theme.text, "Redstone")
        ui.metricPanel(64, 10, 14, " Blinkung ", state.manualAlarm and "Aktiv" or "Aus", state.manualAlarm and theme.warning or theme.ok, "Overlay")

        ui.panel(4, 16, 74, 9, " Alarmsteuerung ")
        ui.button(state, 8, 18, 16, "Alarm an/aus", "toggle_alarm", state.manualAlarm)
        ui.button(state, 27, 18, 16, "Alarmseite", "map_alarm")
        ui.writeAt(8, 21, "Speaker und Redstone-Ausgang laufen parallel.", theme.muted, theme.panel)
        ui.writeAt(8, 22, "Fuer eine echte Sirene: Ausgang an Glocke, Lampe oder Hupe klemmen.", theme.muted, theme.panel)
        ui.warningOverlay("ALARM", { "Sirene aktivieren mit Touch", "oder Taste M" }, runtime.isAlarmVisible(state))
        return
    end

    ui.frame("Alarmzentrale", "B Zurueck", state)
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
    if ui.isLargeLayout() then
        ui.monitorFrame("System", "Schiff, Symbole und Verdrahtung", state)
        ui.navTabs(state, 8, "settings")
        ui.panel(4, 10, 24, 12, " Schiff ")
        ui.writeAt(6, 12, "Name", theme.muted, theme.panel)
        ui.writeAt(6, 13, state.shipName, theme.text, theme.panel)
        ui.writeAt(6, 15, "Palette", theme.muted, theme.panel)
        ui.writeAt(6, 16, runtime.paletteName(state), theme.text, theme.panel)
        ui.writeAt(6, 18, "Symbol", theme.muted, theme.panel)
        ui.writeAt(6, 19, runtime.describeSymbol(state), theme.text, theme.panel)

        ui.panel(30, 10, 48, 12, " Verdrahtung ")
        ui.writeAt(32, 12, "Alarm", theme.muted, theme.panel)
        ui.writeAt(44, 12, runtime.describeAssignment(state, "alarmOutputSide"), theme.text, theme.panel)
        ui.writeAt(32, 14, "Backbord", theme.muted, theme.panel)
        ui.writeAt(44, 14, runtime.describeAssignment(state, "portOutputSide"), theme.text, theme.panel)
        ui.writeAt(32, 16, "Steuerbord", theme.muted, theme.panel)
        ui.writeAt(44, 16, runtime.describeAssignment(state, "starboardOutputSide"), theme.text, theme.panel)
        ui.writeAt(32, 18, "Fabrik", theme.muted, theme.panel)
        ui.writeAt(44, 18, runtime.describeAssignment(state, "factoryOutputSide"), theme.text, theme.panel)

        ui.button(state, 6, 24, 16, "Name aendern", "rename_ship")
        ui.button(state, 24, 24, 12, "Palette", "cycle_palette")
        ui.button(state, 38, 24, 12, "Symbol", "edit_symbol")
        ui.button(state, 52, 24, 12, "Alarm I/O", "map_alarm")
        ui.button(state, 66, 24, 12, "Fabrik I/O", "map_factory_output")

        if runtime.isAlarmVisible(state) then
            ui.warningOverlay("ALARM", { "Systemoberflaeche gesperrt" }, true)
        end
        return
    end

    ui.frame("System", "B Zurueck", state)
    ui.statusBar(state)
    ui.center(7, "Schiff und Konfiguration", theme.accentLight, theme.accent)
    ui.statusRow(10, "Schiffsname", state.shipName, theme.text)
    ui.statusRow(12, "Monitor", state.monitor and "Verbunden" or "Nicht gefunden", state.monitor and theme.ok or theme.warning)
    ui.statusRow(14, "Palette", runtime.paletteName(state), theme.text)
    ui.statusRow(16, "Symbol", runtime.describeSymbol(state), theme.text)
    ui.statusRow(18, "Alarm I/O", runtime.describeAssignment(state, "alarmOutputSide"), theme.text)
    ui.button(state, 4, buttonY - 1, 16, "Name aendern", "rename_ship")
    ui.button(state, 22, buttonY - 1, 12, "Palette", "cycle_palette")
    ui.button(state, 36, buttonY - 1, 12, "Symbol", "edit_symbol")
    ui.button(state, 4, buttonY, 13, "Alarmseite", "map_alarm")
    ui.button(state, 19, buttonY, 13, "Backbord I/O", "map_port")
    ui.button(state, 34, buttonY, 15, "Steuerbord I/O", "map_starboard")
    if runtime.isAlarmVisible(state) then
        ui.warningOverlay("ALARM", { "Systemoberflaeche gesperrt" }, true)
    end
end

return screens
