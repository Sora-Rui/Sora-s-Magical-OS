local theme = require("app.theme")
local runtime = require("app.runtime")
local ui = require("app.ui")

local screens = {}

local ALERT_ROWS = {
    { key = "fuel_low", label = "Treibstoff niedrig", color = colors.yellow },
    { key = "drive_fault", label = "Antrieb gestoert", color = colors.red },
    { key = "helm_disconnected", label = "Helm getrennt", color = colors.red },
    { key = "workshop_overload", label = "Werkstatt ueberlastet", color = colors.orange },
    { key = "enemy_contact", label = "Feindkontakt", color = colors.red },
    { key = "emergency_stop", label = "Not-Aus aktiv", color = colors.red },
}

local function drawChecklist(state, x, y, backgroundColor)
    for index, item in ipairs(state.checklist.items) do
        local row = y + index - 1
        ui.writeAt(x, row, item.ok and "[OK]" or "[--]", item.ok and theme.ok or theme.warning, backgroundColor)
        ui.writeAt(x + 5, row, item.label, theme.text, backgroundColor)
    end
end

local function drawModeButtons(state, y)
    ui.button(state, 4, y, 11, "Parken", "mode_parking", state.mode == "parking")
    ui.button(state, 16, y, 11, "Docking", "mode_docking", state.mode == "docking")
    ui.button(state, 28, y, 11, "Reise", "mode_travel", state.mode == "travel")
    ui.button(state, 40, y, 11, "Gefahr", "mode_danger", state.mode == "danger")
    ui.button(state, 52, y, 12, "Notfall", "mode_emergency", state.mode == "emergency")
end

local function drawCompactModeButtons(state, y)
    ui.button(state, 4, y, 8, "Dock", "mode_docking", state.mode == "docking")
    ui.button(state, 14, y, 8, "Reise", "mode_travel", state.mode == "travel")
    ui.button(state, 24, y, 8, "Gefahr", "mode_danger", state.mode == "danger")
    ui.button(state, 34, y, 8, "Not", "mode_emergency", state.mode == "emergency")
end

local function drawBridgeAlarmButton(state, x, y, width, active)
    local background = colors.red
    local textColor = active and colors.yellow or colors.white
    local topLabel = active and " ALARM AKTIV " or " MANUELLER "
    local bottomLabel = active and " ZUM STOPPEN " or "   ALARM   "

    ui.writeAt(x, y, string.rep(" ", width), textColor, background)
    ui.writeAt(x, y + 1, string.rep(" ", width), textColor, background)
    ui.writeAt(x + math.max(0, math.floor((width - #topLabel) / 2)), y, topLabel, textColor, background)
    ui.writeAt(x + math.max(0, math.floor((width - #bottomLabel) / 2)), y + 1, bottomLabel, textColor, background)

    runtime.registerTouchTarget(state, {
        x = x,
        y = y,
        width = width,
        height = 2,
        action = "toggle_alarm",
    })
end

local function drawAlertRows(state, x, y, backgroundColor)
    for index, alert in ipairs(ALERT_ROWS) do
        local active = state.alerts.active[alert.key]
        ui.writeAt(x, y + index - 1, active and "AKTIV" or "bereit", active and alert.color or theme.ok, backgroundColor)
        ui.writeAt(x + 8, y + index - 1, alert.label, theme.text, backgroundColor)
    end
end

local function clipText(text, width)
    local value = tostring(text or "")
    if #value <= width then
        return value
    end

    if width <= 3 then
        return value:sub(1, width)
    end

    return value:sub(1, width - 3) .. "..."
end

local function formatMessageLine(message, width)
    local direction = message.direction == "out" and ">" or "<"
    local device = tostring(message.device or "?")
    local peerId = tostring(message.peerId or "?")
    local author = tostring(message.author or message.role or "Extern")
    local text = tostring(message.text or "")
    return clipText(direction .. " " .. device .. "#" .. peerId .. " " .. author .. ": " .. text, width)
end

local function drawMessages(state, x, y, maxRows, width, backgroundColor)
    if #state.comms.inbox == 0 then
        ui.writeAt(x, y, "Keine Funknachrichten", theme.muted, backgroundColor)
        return
    end

    for index = 1, math.min(maxRows, #state.comms.inbox) do
        local message = state.comms.inbox[index]
        ui.writeAt(x, y + index - 1, formatMessageLine(message, width), theme.text, backgroundColor)
    end
end

local function drawLogs(state, x, y, maxRows, backgroundColor)
    if #state.logEntries == 0 then
        ui.writeAt(x, y, "Logbuch leer", theme.muted, backgroundColor)
        return
    end

    for index = 1, math.min(maxRows, #state.logEntries) do
        ui.writeAt(x, y + index - 1, state.logEntries[index], theme.text, backgroundColor)
    end
end

function screens.home(state)
    local width, height = term.getSize()
    local checklistText, checklistColor = runtime.checklistStatus(state)
    local alertText, alertColor = runtime.primaryAlert(state)
    local positionText, positionColor = runtime.currentPositionLabel(state)
    local waypoint = runtime.currentWaypoint(state)
    local welcomeText = state.notice ~= "" and state.notice or runtime.welcomeMessage(state)

    if ui.isLargeLayout() then
        ui.monitorFrame(theme.brandName, theme.subtitle, state)
        local navBottom = ui.navTabs(state, 8, "")
        local top = navBottom + 2

        ui.panel(4, top, 23, 10, " Kommando ")
        ui.writeAt(6, top + 2, "Schiff", theme.muted, theme.panel)
        ui.writeAt(15, top + 2, state.shipName, theme.text, theme.panel)
        ui.writeAt(6, top + 3, "Modus", theme.muted, theme.panel)
        ui.writeAt(15, top + 3, runtime.modeLabel(state), runtime.modeColor(state), theme.panel)
        ui.writeAt(6, top + 4, "Rolle", theme.muted, theme.panel)
        ui.writeAt(15, top + 4, runtime.roleLabel(state), theme.text, theme.panel)
        ui.writeAt(6, top + 5, "Check", theme.muted, theme.panel)
        ui.writeAt(15, top + 5, checklistText, checklistColor, theme.panel)
        ui.writeAt(6, top + 6, "Alarm", theme.muted, theme.panel)
        ui.writeAt(15, top + 6, alertText, alertColor, theme.panel)
        ui.writeAt(6, top + 7, "Hinweis", theme.muted, theme.panel)
        ui.writeAt(15, top + 7, welcomeText, theme.text, theme.panel)
        drawBridgeAlarmButton(state, 6, top + 8, 19, state.manualAlarm)

        ui.panel(29, top, 24, 10, " Startcheck ")
        drawChecklist(state, 31, top + 2, theme.panel)
        ui.writeAt(31, top + 8, "Fabrik-Soll: " .. runtime.describeFactoryRequirement(state), theme.muted, theme.panel)

        ui.panel(55, top, 24, 10, " Navigation ")
        ui.writeAt(57, top + 2, "Heimathafen", theme.muted, theme.panel)
        ui.writeAt(57, top + 3, state.navigation.homePort, theme.text, theme.panel)
        ui.writeAt(57, top + 4, "Mom. Pos.", theme.muted, theme.panel)
        ui.writeAt(57, top + 5, positionText, positionColor, theme.panel)
        ui.writeAt(57, top + 6, "Ziel", theme.muted, theme.panel)
        ui.writeAt(57, top + 7, waypoint.name, theme.text, theme.panel)
        ui.writeAt(57, top + 8, waypoint.distance .. " | " .. waypoint.direction, theme.accentLight, theme.panel)

        drawModeButtons(state, height - 2)
        if runtime.isAlarmVisible(state) then
            ui.warningOverlay("ALARM", { "Alarmmatrix meldet Stoerung", "Siehe Alarmzentrale" }, true, state.alarmFlash)
        end
        return
    end

    ui.frame(theme.brandName, "Pfeile wechseln  |  M Alarm  |  Q Ende", state)
    ui.statusBar(state)
    ui.center(7, state.shipName, theme.text, theme.accent)
    ui.statusRow(9, "Modus", runtime.modeLabel(state), runtime.modeColor(state))
    ui.statusRow(10, "Rolle", runtime.roleLabel(state), theme.text)
    ui.statusRow(11, "Check", checklistText, checklistColor)
    ui.statusRow(12, "Alarm", alertText, alertColor)
    ui.statusRow(13, "Ziel", waypoint.name, theme.text)
    ui.statusRow(14, "mom. pos.", positionText, positionColor)
    ui.statusRow(15, "Hinweis", welcomeText, theme.text)

    ui.button(state, 4, height - 3, 10, "Helm", "helm")
    ui.button(state, 16, height - 3, 10, "Fabrik", "factory")
    ui.button(state, 28, height - 3, 10, "Nav", "navigation")
    ui.button(state, 40, height - 3, 10, "Alarm", "alarms")
    ui.button(state, 4, height - 2, 10, "Crew", "crew")
    ui.button(state, 16, height - 2, 10, "Funk", "comms")
    ui.button(state, 28, height - 2, 10, "Log", "log")
    ui.button(state, 40, height - 2, 10, "System", "settings")
    if runtime.isAlarmVisible(state) then
        ui.warningOverlay("ALARM", { "Alarmmatrix meldet Stoerung" }, true, state.alarmFlash)
    end
end

function screens.helm(state)
    local _, height = term.getSize()
    local autopilotText, autopilotColor = runtime.autopilotStatus(state)
    local securityText, securityColor = runtime.securityStatus(state)

    if ui.isLargeLayout() then
        ui.monitorFrame("Steuerung", "Helm, Ruder und Flugmodus", state)
        local top = ui.navTabs(state, 8, "helm") + 2
        ui.metricPanel(4, top, 18, " Schub ", state.helm.thrust, theme.warning, runtime.describeAssignment(state, "thrustOutputSide"))
        ui.metricPanel(24, top, 18, " Kurs ", state.helm.heading, theme.text, runtime.describeAssignment(state, "helmSignalSide"))
        ui.metricPanel(44, top, 18, " Hoehe ", state.helm.altitude, theme.text, runtime.modeLabel(state))
        ui.metricPanel(64, top, 14, " Zugriff ", securityText, securityColor, state.helm.failsafe)

        ui.panel(4, top + 6, 74, 7, " Helmsteuerung ")
        ui.button(state, 8, top + 8, 14, "Schub", "toggle_thrust", state.outputs.thrust)
        ui.button(state, 24, top + 8, 14, "Backbord", "turn_port", state.outputs.turnLeft)
        ui.button(state, 40, top + 8, 16, "Steuerbord", "turn_starboard", state.outputs.turnRight)
        ui.button(state, 58, top + 8, 14, "Still", "turn_stop")
        ui.button(state, 8, top + 10, 14, "Helm I/O", "map_helm")
        ui.button(state, 24, top + 10, 14, "Schub I/O", "map_thrust")
        ui.button(state, 40, top + 10, 16, "Backbord I/O", "map_port")
        ui.button(state, 58, top + 10, 16, "Steuerbord I/O", "map_starboard")
        ui.writeAt(8, top + 12, "Autopilot: " .. runtime.autopilotLabel(state) .. " | " .. autopilotText, autopilotColor, theme.panel)
        if runtime.isAlarmVisible(state) then
            ui.warningOverlay("ALARM", { "Helmdeck im Alarmmodus" }, true, state.alarmFlash)
        end
        return
    end

    ui.frame("Steuerung", "B Home  |  Pfeile Seiten", state)
    ui.statusBar(state)
    ui.statusRow(8, "Schub", state.helm.thrust, theme.warning)
    ui.statusRow(9, "Kurs", state.helm.heading, theme.text)
    ui.statusRow(10, "Hoehe", state.helm.altitude, theme.text)
    ui.statusRow(11, "Zugriff", securityText, securityColor)
    ui.statusRow(12, "Auto", runtime.autopilotLabel(state), autopilotColor)
    ui.statusRow(13, "Signal", runtime.describeAssignment(state, "helmSignalSide"), theme.text)
    ui.button(state, 4, height - 4, 12, "Schub", "toggle_thrust", state.outputs.thrust)
    ui.button(state, 18, height - 4, 12, "Backbord", "turn_port", state.outputs.turnLeft)
    ui.button(state, 32, height - 4, 13, "Steuerbord", "turn_starboard", state.outputs.turnRight)
    ui.button(state, 4, height - 3, 12, "Still", "turn_stop")
    ui.button(state, 18, height - 3, 12, "Helm I/O", "map_helm")
    ui.button(state, 32, height - 3, 13, "Schub I/O", "map_thrust")
    drawCompactModeButtons(state, height - 2)
    if runtime.isAlarmVisible(state) then
        ui.warningOverlay("ALARM", { "Helmdeck im Alarmmodus" }, true, state.alarmFlash)
    end
end

function screens.factory(state)
    local _, height = term.getSize()

    if ui.isLargeLayout() then
        ui.monitorFrame("Maschinenraum", "Fabrik, Generator und Reserve", state)
        local top = ui.navTabs(state, 8, "factory") + 2
        ui.metricPanel(4, top, 17, " Treibstoff ", state.factory.fuel, state.engine.fuelLow and theme.warning or theme.ok, runtime.describeAssignment(state, "fuelSensorSide"))
        ui.metricPanel(23, top, 17, " Generator ", state.engine.generatorOnline and "Online" or "Offline", state.engine.generatorOnline and theme.ok or theme.warning, runtime.describeAssignment(state, "generatorSensorSide"))
        ui.metricPanel(42, top, 17, " Fabrik ", state.factory.mode, theme.text, runtime.describeAssignment(state, "factoryOutputSide"))
        ui.metricPanel(61, top, 17, " Reserve ", state.outputs.reserveMode and "Aktiv" or "Aus", state.outputs.reserveMode and theme.ok or theme.text, runtime.describeAssignment(state, "reserveOutputSide"))

        ui.panel(4, top + 6, 74, 7, " Maschinenraum ")
        ui.button(state, 8, top + 8, 16, "Fabrik an/aus", "toggle_factory", state.outputs.factoryEnabled)
        ui.button(state, 27, top + 8, 16, "Reserve", "toggle_reserve", state.outputs.reserveMode)
        ui.button(state, 46, top + 8, 16, "Fabrik-Soll", "cycle_factory_requirement")
        ui.button(state, 65, top + 8, 10, "Not-Aus", "map_emergency_stop")
        ui.button(state, 8, top + 10, 16, "Fuel I/O", "map_fuel")
        ui.button(state, 27, top + 10, 16, "Gen I/O", "map_generator")
        ui.button(state, 46, top + 10, 16, "Fabrik I/O", "map_factory_output")
        ui.button(state, 65, top + 10, 10, "Res I/O", "map_reserve")
        ui.writeAt(8, top + 12, state.engine.emergencyStop and "Physischer Not-Aus aktiv" or "Not-Aus bereit", state.engine.emergencyStop and theme.warning or theme.ok, theme.panel)
        if runtime.isAlarmVisible(state) then
            ui.warningOverlay("ALARM", { "Maschinenraum im Alarmmodus" }, true, state.alarmFlash)
        end
        return
    end

    ui.frame("Maschinenraum", "B Home  |  Pfeile Seiten", state)
    ui.statusBar(state)
    ui.statusRow(8, "Fuel", state.factory.fuel, state.engine.fuelLow and theme.warning or theme.ok)
    ui.statusRow(9, "Generator", state.engine.generatorOnline and "Online" or "Offline", state.engine.generatorOnline and theme.ok or theme.warning)
    ui.statusRow(10, "Fabrik", state.factory.mode, theme.text)
    ui.statusRow(11, "Reserve", state.outputs.reserveMode and "Aktiv" or "Aus", theme.text)
    ui.statusRow(12, "Not-Aus", state.engine.emergencyStop and "Aktiv" or "Bereit", state.engine.emergencyStop and theme.warning or theme.ok)
    ui.statusRow(13, "Soll", runtime.describeFactoryRequirement(state), theme.text)
    ui.button(state, 4, height - 3, 14, "Fabrik", "toggle_factory", state.outputs.factoryEnabled)
    ui.button(state, 20, height - 3, 14, "Reserve", "toggle_reserve", state.outputs.reserveMode)
    ui.button(state, 36, height - 3, 14, "Soll", "cycle_factory_requirement")
    ui.button(state, 4, height - 2, 14, "Fuel I/O", "map_fuel")
    ui.button(state, 20, height - 2, 14, "Gen I/O", "map_generator")
    ui.button(state, 36, height - 2, 14, "Not-Aus", "map_emergency_stop")
    if runtime.isAlarmVisible(state) then
        ui.warningOverlay("ALARM", { "Maschinenraum im Alarmmodus" }, true, state.alarmFlash)
    end
end

function screens.navigation(state)
    local _, height = term.getSize()
    local waypoint = runtime.currentWaypoint(state)
    local autopilotText, autopilotColor = runtime.autopilotStatus(state)

    if ui.isLargeLayout() then
        ui.monitorFrame("Navigation", "Wegpunkte und Autopilot-Light", state)
        local top = ui.navTabs(state, 8, "navigation") + 2
        ui.metricPanel(4, top, 17, " Ziel ", waypoint.name, theme.text, "Aktiver Wegpunkt")
        ui.metricPanel(23, top, 17, " Distanz ", waypoint.distance, theme.accentLight, "Schaetzung")
        ui.metricPanel(42, top, 17, " Richtung ", waypoint.direction, theme.text, "Kurs")
        ui.metricPanel(61, top, 17, " Heimathafen ", state.navigation.homePort, theme.text, autopilotText)

        ui.panel(4, top + 6, 74, 7, " Navigation und Makros ")
        ui.button(state, 8, top + 8, 14, "Vorheriger", "waypoint_prev")
        ui.button(state, 24, top + 8, 14, "Naechster", "waypoint_next")
        ui.button(state, 40, top + 8, 16, "Wegpunkt", "edit_waypoint")
        ui.button(state, 58, top + 8, 16, "Heimathafen", "set_home_port")
        ui.button(state, 8, top + 10, 16, "Programm", "cycle_autopilot_program")
        ui.button(state, 27, top + 10, 14, "Start", "start_autopilot", state.autopilot.running)
        ui.button(state, 44, top + 10, 14, "Stop", "stop_autopilot")
        ui.writeAt(8, top + 12, "Autopilot: " .. runtime.autopilotLabel(state) .. " | Schritt: " .. state.autopilot.currentStepLabel, autopilotColor, theme.panel)
        if runtime.isAlarmVisible(state) then
            ui.warningOverlay("ALARM", { "Navigation im Alarmmodus" }, true, state.alarmFlash)
        end
        return
    end

    ui.frame("Navigation", "B Home  |  Pfeile Seiten", state)
    ui.statusBar(state)
    ui.statusRow(8, "Ziel", waypoint.name, theme.text)
    ui.statusRow(9, "Distanz", waypoint.distance, theme.accentLight)
    ui.statusRow(10, "Richtung", waypoint.direction, theme.text)
    ui.statusRow(11, "Heimat", state.navigation.homePort, theme.text)
    ui.statusRow(12, "Auto", runtime.autopilotLabel(state), autopilotColor)
    ui.statusRow(13, "Schritt", state.autopilot.currentStepLabel, theme.text)
    ui.button(state, 4, height - 3, 12, "Zurueck", "waypoint_prev")
    ui.button(state, 18, height - 3, 12, "Weiter", "waypoint_next")
    ui.button(state, 32, height - 3, 14, "Wegpunkt", "edit_waypoint")
    ui.button(state, 4, height - 2, 14, "Programm", "cycle_autopilot_program")
    ui.button(state, 20, height - 2, 12, "Start", "start_autopilot", state.autopilot.running)
    ui.button(state, 34, height - 2, 12, "Stop", "stop_autopilot")
    if runtime.isAlarmVisible(state) then
        ui.warningOverlay("ALARM", { "Navigation im Alarmmodus" }, true, state.alarmFlash)
    end
end

function screens.alarms(state)
    local _, height = term.getSize()
    local alarmText, alarmColor = runtime.alarmStatus(state)
    local speakerText, speakerColor = runtime.speakerStatus(state)
    local radioText, radioColor = runtime.radioStatus(state)
    local audioStatus = clipText(runtime.audioLastMethod(state) .. ": " .. runtime.audioLastResult(state), 26)

    if ui.isLargeLayout() then
        ui.monitorFrame("Alarmzentrale", "Alarmmatrix und Stoerungen", state)
        local top = ui.navTabs(state, 8, "alarms") + 2
        ui.metricPanel(4, top, 17, " Alarm ", alarmText, alarmColor, state.manualAlarm and "Manuell" or "Automatik")
        local primaryAlert, primaryColor = runtime.primaryAlert(state)
        ui.metricPanel(23, top, 17, " Hauptalarm ", primaryAlert, primaryColor, tostring(runtime.activeAlertCount(state)) .. " aktiv")
        ui.metricPanel(42, top, 17, " Speaker ", speakerText, speakerColor, "Alarm I/O: " .. runtime.describeAssignment(state, "alarmOutputSide"))
        ui.metricPanel(61, top, 17, " Funk ", radioText, radioColor, state.comms.lastPeer)

        ui.panel(4, top + 6, 74, 9, " Alarmmatrix ")
        drawAlertRows(state, 8, top + 8, theme.panel)
        ui.button(state, 48, top + 8, 14, "Alarm", "toggle_alarm", state.manualAlarm)
        ui.button(state, 64, top + 8, 10, "Alarm I/O", "map_alarm")
        ui.button(state, 48, top + 10, 14, "Gefahr", "mode_danger", state.mode == "danger")
        ui.button(state, 64, top + 10, 10, "Notfall", "mode_emergency", state.mode == "emergency")
        ui.button(state, 48, top + 12, 14, "Feind I/O", "map_enemy")
        ui.button(state, 64, top + 12, 10, "Last I/O", "map_overload")
        ui.button(state, 48, top + 14, 14, "Speaker-Test", "test_speaker")
        ui.writeAt(8, top + 14, "Audio: " .. clipText(runtime.audioLastMethod(state) .. ": " .. runtime.audioLastResult(state), 33), theme.muted, theme.panel)
        ui.warningOverlay("ALARM", { "Sirene und Alarmmatrix aktiv" }, runtime.isAlarmVisible(state), state.alarmFlash)
        return
    end

    ui.frame("Alarmzentrale", "B Home  |  Pfeile Seiten", state)
    ui.statusBar(state)
    ui.statusRow(8, "Alarm", alarmText, alarmColor)
    ui.statusRow(9, "Speaker", speakerText, speakerColor)
    ui.statusRow(10, "Funk", radioText, radioColor)
    ui.statusRow(11, "Hauptalarm", runtime.primaryAlert(state), theme.warning)
    ui.statusRow(12, "Audio", audioStatus, theme.muted)
    drawAlertRows(state, 4, 13, theme.accent)
    ui.button(state, 4, height - 2, 10, "Alarm", "toggle_alarm", state.manualAlarm)
    ui.button(state, 16, height - 2, 10, "Test", "test_speaker")
    ui.button(state, 28, height - 2, 10, "Gefahr", "mode_danger", state.mode == "danger")
    ui.button(state, 40, height - 2, 10, "Notfall", "mode_emergency", state.mode == "emergency")
    ui.warningOverlay("ALARM", { "Sirene und Alarmmatrix aktiv" }, runtime.isAlarmVisible(state), state.alarmFlash)
end

function screens.crew(state)
    local _, height = term.getSize()
    local securityText, securityColor = runtime.securityStatus(state)
    local loginText, loginColor = runtime.loginStatus(state)
    local crewEntries = runtime.crewListEntries(state, 3)
    local selectedUserName = runtime.selectedCrewUserName(state)
    local selectedUserRoles = runtime.selectedCrewUserRoles(state)

    if ui.isLargeLayout() then
        ui.monitorFrame("Crew", "Login, Rollenbereiche und Tablet-Anbindung", state)
        local top = ui.navTabs(state, 8, "crew") + 2
        ui.metricPanel(4, top, 17, " Login ", loginText, loginColor, runtime.operatorLabel(state))
        ui.metricPanel(23, top, 17, " Rolle ", runtime.roleLabel(state), theme.text, runtime.roleFocus(state))
        ui.metricPanel(42, top, 17, " Auswahl ", runtime.selectedRoleLabel(state), theme.text, runtime.selectedRoleFocus(state))
        ui.metricPanel(61, top, 17, " Zugriff ", securityText, securityColor, runtime.securitySourceLabel(state))

        ui.panel(4, top + 6, 74, 7, " Crew-Login und Bereiche ")
        ui.button(state, 8, top + 8, 10, "Pilot", "role_pilot", state.crew.selectedRole == "pilot")
        ui.button(state, 20, top + 8, 8, "Ing", "role_engineer", state.crew.selectedRole == "engineer")
        ui.button(state, 30, top + 8, 10, "Alarm", "role_alarm", state.crew.selectedRole == "alarm")
        ui.button(state, 42, top + 8, 10, "Capt", "role_captain", state.crew.selectedRole == "captain")
        ui.button(state, 54, top + 8, 12, "Co-Capt", "role_co_captain", state.crew.selectedRole == "co_captain")
        ui.button(state, 8, top + 10, 10, "Login", "login_role")
        ui.button(state, 20, top + 10, 10, "Logout", "logout_role")
        ui.writeAt(32, top + 10, "Nur Rollen-Login aktiv", theme.muted, theme.panel)
        ui.writeAt(8, top + 12, runtime.securitySummary(state), theme.muted, theme.panel)

        ui.panel(4, top + 14, 74, 7, " Captain-Verwaltung ")
        if #crewEntries == 0 then
            ui.writeAt(8, top + 16, "Noch keine Crew-Konten vorhanden", theme.muted, theme.panel)
        else
            for index, entry in ipairs(crewEntries) do
                local founderTag = entry.founder and " [Gruender]" or ""
                local rowLabel = clipText(entry.name .. founderTag .. " | " .. entry.roles, 44)
                ui.button(state, 8, top + 14 + index, 46, rowLabel, "select_user:" .. entry.key, entry.selected)
            end
        end
        ui.button(state, 58, top + 15, 10, "< Crew", "select_prev_user")
        ui.button(state, 58, top + 16, 10, "Crew >", "select_next_user")
        ui.writeAt(8, top + 18, clipText("Auswahl: " .. selectedUserName .. " | " .. selectedUserRoles, 66), theme.muted, theme.panel)
        ui.button(state, 8, top + 19, 12, "User+", "save_user")
        ui.button(state, 22, top + 19, 12, "User-", "delete_user")
        ui.button(state, 36, top + 19, 12, "Rolle+", "assign_selected_role")
        ui.button(state, 50, top + 19, 12, "Rolle-", "remove_selected_role")
        if runtime.isAlarmVisible(state) then
            ui.warningOverlay("ALARM", { "Crewpage zeigt Sicherheitszustand" }, true, state.alarmFlash)
        end
        return
    end

    ui.frame("Crew", "B Home  |  Login auf Crew", state)
    ui.statusBar(state)
    ui.statusRow(8, "Login", loginText, loginColor)
    ui.statusRow(9, "Benutzer", runtime.currentUsername(state), theme.text)
    ui.statusRow(10, "Rolle", runtime.roleLabel(state), theme.text)
    ui.statusRow(11, "Auswahl", runtime.selectedRoleLabel(state), theme.text)
    ui.statusRow(12, "Zugriff", securityText, securityColor)
    ui.statusRow(13, "Crew", clipText(selectedUserName .. " | " .. selectedUserRoles, 28), theme.text)
    ui.button(state, 4, height - 5, 8, "Pilot", "role_pilot", state.crew.selectedRole == "pilot")
    ui.button(state, 14, height - 5, 6, "Ing", "role_engineer", state.crew.selectedRole == "engineer")
    ui.button(state, 22, height - 5, 8, "Alarm", "role_alarm", state.crew.selectedRole == "alarm")
    ui.button(state, 32, height - 5, 8, "Capt", "role_captain", state.crew.selectedRole == "captain")
    ui.button(state, 42, height - 5, 6, "Co", "role_co_captain", state.crew.selectedRole == "co_captain")
    ui.button(state, 4, height - 4, 10, "Login", "login_role")
    ui.button(state, 16, height - 4, 10, "Logout", "logout_role")
    ui.button(state, 4, height - 3, 10, "User+", "save_user")
    ui.button(state, 16, height - 3, 10, "User-", "delete_user")
    ui.button(state, 28, height - 3, 10, "Rolle+", "assign_selected_role")
    ui.button(state, 40, height - 3, 10, "Rolle-", "remove_selected_role")
    ui.button(state, 4, height - 2, 12, "< Crew", "select_prev_user")
    ui.button(state, 18, height - 2, 12, "Crew >", "select_next_user")
    if runtime.isAlarmVisible(state) then
        ui.warningOverlay("ALARM", { "Crewpage zeigt Sicherheitszustand" }, true, state.alarmFlash)
    end
end

function screens.comms(state)
    local _, height = term.getSize()
    local radioText, radioColor = runtime.radioStatus(state)

    if ui.isLargeLayout() then
        ui.monitorFrame("Funk und Tablet", "Kommunikation und Remote-Steuerung", state)
        local top = ui.navTabs(state, 8, "comms") + 2
        ui.metricPanel(4, top, 17, " Funk ", radioText, radioColor, tostring(#state.comms.modemSides) .. " Modems")
        ui.metricPanel(23, top, 17, " Letzter Peer ", state.comms.lastPeer, theme.text, state.comms.lastContact)
        ui.metricPanel(42, top, 17, " Tablet ", runtime.linkedTabletLabel(state), theme.text, "tablet.lua")
        ui.metricPanel(61, top, 17, " Rolle ", runtime.roleLabel(state), theme.text, "Remote-Profil")

        ui.panel(4, top + 6, 74, 9, " Funkprotokoll ")
        ui.writeAt(8, top + 8, "Das Protokoll zeigt eingehende und ausgehende Nachrichten mit Autor sowie PC-Typ T/BC und ID.", theme.muted, theme.panel)
        ui.writeAt(8, top + 9, "Pocket braucht ein Wireless Modem; Rollen vergibt der Captain auf Crew.", theme.muted, theme.panel)
        drawMessages(state, 8, top + 11, 3, 66, theme.panel)
        ui.button(state, 60, top + 14, 14, "Nachricht", "send_message")
        if runtime.isAlarmVisible(state) then
            ui.warningOverlay("ALARM", { "Funkverkehr priorisiert" }, true, state.alarmFlash)
        end
        return
    end

    ui.frame("Funk und Tablet", "B Home  |  Pfeile Seiten", state)
    ui.statusBar(state)
    ui.statusRow(8, "Funk", radioText, radioColor)
    ui.statusRow(9, "Peer", state.comms.lastPeer, theme.text)
    ui.statusRow(10, "Kontakt", state.comms.lastContact, theme.text)
    ui.statusRow(11, "Tablet", runtime.linkedTabletLabel(state), theme.text)
    drawMessages(state, 4, 13, 4, 44, theme.accent)
    ui.button(state, 4, height - 2, 16, "Nachricht", "send_message")
    if runtime.isAlarmVisible(state) then
        ui.warningOverlay("ALARM", { "Funkverkehr priorisiert" }, true, state.alarmFlash)
    end
end

function screens.log(state)
    if ui.isLargeLayout() then
        ui.monitorFrame("Logbuch", "Ereignisse und Historie", state)
        local top = ui.navTabs(state, 8, "log") + 2
        ui.panel(4, top, 74, 13, " Logbuch ")
        drawLogs(state, 6, top + 2, 11, theme.panel)
        return
    end

    ui.frame("Logbuch", "B Home  |  Pfeile Seiten", state)
    ui.statusBar(state)
    drawLogs(state, 4, 8, 10, theme.accent)
end

function screens.settings(state)
    local _, height = term.getSize()
    local speakerText, speakerColor = runtime.speakerStatus(state)
    local radioText, radioColor = runtime.radioStatus(state)
    local positionText, positionColor = runtime.currentPositionLabel(state)
    local cueText = runtime.audioCueLabel(state)
    local lastAudioText = runtime.audioLastResult(state)

    if ui.isLargeLayout() then
        ui.monitorFrame("System", "Visuals, Peripherals und Verkabelung", state)
        local top = ui.navTabs(state, 8, "settings") + 2
        ui.panel(4, top, 24, 10, " Schiff ")
        ui.writeAt(6, top + 2, "Name", theme.muted, theme.panel)
        ui.writeAt(15, top + 2, state.shipName, theme.text, theme.panel)
        ui.writeAt(6, top + 4, "Palette", theme.muted, theme.panel)
        ui.writeAt(15, top + 4, runtime.paletteName(state), theme.text, theme.panel)
        ui.writeAt(6, top + 6, "Symbol", theme.muted, theme.panel)
        ui.writeAt(15, top + 6, runtime.describeSymbol(state), theme.text, theme.panel)

        ui.panel(30, top, 24, 10, " Peripherals ")
        ui.writeAt(32, top + 2, "Monitor", theme.muted, theme.panel)
        ui.writeAt(42, top + 2, state.monitor and "Verbunden" or "Fehlt", state.monitor and theme.ok or theme.warning, theme.panel)
        ui.writeAt(32, top + 3, clipText(runtime.monitorLabel(state), 20), theme.muted, theme.panel)
        ui.writeAt(32, top + 5, "Speaker", theme.muted, theme.panel)
        ui.writeAt(42, top + 5, speakerText, speakerColor, theme.panel)
        ui.writeAt(32, top + 6, clipText(runtime.speakerLabel(state), 20), theme.muted, theme.panel)
        ui.writeAt(32, top + 8, "Funk", theme.muted, theme.panel)
        ui.writeAt(42, top + 8, radioText, radioColor, theme.panel)

        ui.panel(56, top, 22, 10, " Debug ")
        ui.writeAt(58, top + 2, clipText("GPS: " .. positionText, 18), positionColor, theme.panel)
        ui.writeAt(58, top + 4, clipText("Cue: " .. cueText, 18), theme.text, theme.panel)
        ui.writeAt(58, top + 6, clipText("Audio: " .. lastAudioText, 18), theme.muted, theme.panel)
        ui.writeAt(58, top + 8, clipText("Custom: " .. tostring(runtime.customAudioCount(state)) .. " | Alarm I/O: " .. runtime.describeAssignment(state, "alarmOutputSide"), 18), theme.muted, theme.panel)

        ui.writeAt(4, height - 6, clipText("Eigene Audios: /smos/audio/*.dfpwm | Live-Debug liegt parallel auf dem Computer-Terminal", 74), theme.muted, theme.accent)
        ui.button(state, 4, height - 4, 12, "Name", "rename_ship")
        ui.button(state, 18, height - 4, 12, "Palette", "cycle_palette")
        ui.button(state, 32, height - 4, 12, "Symbol", "edit_symbol")
        ui.button(state, 46, height - 4, 12, "Cue <", "audio_prev")
        ui.button(state, 60, height - 4, 12, "Cue >", "audio_next")
        ui.button(state, 4, height - 2, 12, "Play Cue", "play_audio_cue")
        ui.button(state, 18, height - 2, 14, "Speaker-Test", "test_speaker")
        ui.button(state, 34, height - 2, 12, "Alarm I/O", "map_alarm")
        ui.button(state, 48, height - 2, 12, "Helm I/O", "map_helm")
        ui.button(state, 62, height - 2, 12, "Schub I/O", "map_thrust")
        if runtime.isAlarmVisible(state) then
            ui.warningOverlay("ALARM", { "Systemseite gesperrt" }, true, state.alarmFlash)
        end
        return
    end

    ui.frame("System", "B Home  |  Pfeile Seiten", state)
    ui.statusBar(state)
    ui.statusRow(8, "Name", state.shipName, theme.text)
    ui.statusRow(9, "Palette", runtime.paletteName(state), theme.text)
    ui.statusRow(10, "Symbol", runtime.describeSymbol(state), theme.text)
    ui.statusRow(11, "Monitor", state.monitor and "Verbunden" or "Fehlt", state.monitor and theme.ok or theme.warning)
    ui.statusRow(12, "Speaker", speakerText, speakerColor)
    ui.statusRow(13, "Cue", clipText(cueText, 28), theme.text)
    if height >= 19 then
        ui.statusRow(14, "Audio", clipText(lastAudioText, 28), theme.muted)
    end
    ui.button(state, 4, height - 3, 10, "Name", "rename_ship")
    ui.button(state, 16, height - 3, 10, "Palette", "cycle_palette")
    ui.button(state, 28, height - 3, 8, "Cue<", "audio_prev")
    ui.button(state, 38, height - 3, 8, "Cue>", "audio_next")
    ui.button(state, 4, height - 2, 10, "Play", "play_audio_cue")
    ui.button(state, 16, height - 2, 10, "Test", "test_speaker")
    ui.button(state, 28, height - 2, 12, "Alarm I/O", "map_alarm")
    if runtime.isAlarmVisible(state) then
        ui.warningOverlay("ALARM", { "Systemseite gesperrt" }, true, state.alarmFlash)
    end
end

return screens