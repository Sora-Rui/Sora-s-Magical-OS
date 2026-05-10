local theme = require("app.theme")
local runtime = require("app.runtime")
local screens = require("app.screens")

local hotkeys = {
    h = "helm",
    f = "factory",
    g = "navigation",
    a = "alarms",
    c = "crew",
    k = "comms",
    l = "log",
    s = "settings",
}

local function beginPrompt(nativeTerm, title, instructions)
    term.redirect(nativeTerm)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
    print("Sora's Magical OS")
    print(title)
    if instructions then
        for _, line in ipairs(instructions) do
            print(line)
        end
    end
end

local function promptField(label, defaultValue, secret)
    write(label)
    if defaultValue and defaultValue ~= "" then
        write(" [" .. defaultValue .. "]")
    end
    write(": ")
    local value = secret and read("*") or read()
    if value == "" or value == nil then
        return defaultValue
    end
    return value
end

local function promptShipName(state, nativeTerm)
    beginPrompt(nativeTerm, "Schiffsname aendern", { "Neuen Namen eingeben." })
    local value = promptField("Name", state.shipName)
    if value and value ~= "" then
        runtime.setShipName(state, value)
    end
end

local function promptSymbol(state, nativeTerm)
    beginPrompt(nativeTerm, "Eigenes Symbol", { "7 Zeilen, leer = alte Zeile behalten." })
    local lines = {}
    for index = 1, 7 do
        lines[index] = promptField(tostring(index), state.customSymbol[index] or "")
    end
    runtime.setCustomSymbol(state, lines)
end

local function promptWaypoint(state, nativeTerm)
    local waypoint = runtime.currentWaypoint(state)
    beginPrompt(nativeTerm, "Wegpunkt bearbeiten", { "Name, Distanz und Richtung anpassen." })
    local name = promptField("Ziel", waypoint.name)
    local distance = promptField("Distanz", waypoint.distance)
    local direction = promptField("Richtung", waypoint.direction)
    runtime.updateWaypoint(state, {
        name = name,
        distance = distance,
        direction = direction,
    })
end

local function promptHomePort(state, nativeTerm)
    beginPrompt(nativeTerm, "Heimathafen", { "Name des Heimathafens eingeben." })
    local value = promptField("Heimathafen", state.navigation.homePort)
    runtime.setHomePort(state, value)
end

local function promptRoleLogin(state, nativeTerm)
    local instructions = {
        "Rolle: " .. runtime.selectedRoleLabel(state),
        "Benutzername und Passwort eingeben.",
    }
    if state.crew.selectedRole == "captain" and not runtime.hasCaptain(state) then
        instructions[#instructions + 1] = "Der erste Captain wird bei Erfolg automatisch angelegt."
    end
    beginPrompt(nativeTerm, "Crew-Login", instructions)
    local defaultUser = runtime.currentUsername(state) ~= "-" and runtime.currentUsername(state) or ""
    local username = promptField("Benutzer", defaultUser)
    local password = promptField("Passwort", "", true)
    runtime.loginRole(state, state.crew.selectedRole, username, password)
end

local function promptSaveUser(state, nativeTerm)
    beginPrompt(nativeTerm, "Crew-Konto", {
        "Captain legt hier Benutzername und Passwort fest.",
        "Bestehender Benutzer wird mit neuem Passwort aktualisiert.",
    })
    local username = promptField("Benutzer", "")
    local first = promptField("Passwort", "", true)
    local second = promptField("Wiederholen", "", true)
    if first ~= second then
        runtime.setNotice(state, "Passwort stimmt nicht ueberein", 24)
        runtime.log(state, "Crew-Konto fehlgeschlagen", "SEC")
        return
    end
    local ok, reason = runtime.saveCrewUser(state, username, first)
    if not ok then
        runtime.setNotice(state, reason or "Crew-Konto fehlgeschlagen", 24)
        runtime.log(state, "Crew-Konto fehlgeschlagen", "SEC")
    end
end

local function promptAssignRole(state, nativeTerm)
    beginPrompt(nativeTerm, "Rolle vergeben", {
        "Rolle: " .. runtime.selectedRoleLabel(state),
        "Captain weist die aktuell gewaehlte Rolle einem Benutzer zu.",
    })
    local username = promptField("Benutzer", "")
    local ok, reason = runtime.assignRoleToUser(state, username, state.crew.selectedRole)
    if not ok then
        runtime.setNotice(state, reason or "Rollenzuweisung fehlgeschlagen", 24)
        runtime.log(state, "Rollenzuweisung fehlgeschlagen", "SEC")
    end
end

local function promptUnlock(state, nativeTerm)
    beginPrompt(nativeTerm, "PIN-Freigabe", { "PIN eingeben, um kritische Funktionen freizugeben." })
    local pin = promptField("PIN", "", true)
    runtime.unlockWithPin(state, pin)
end

local function promptSetPin(state, nativeTerm)
    beginPrompt(nativeTerm, "Neue PIN", { "Neue PIN zweimal eingeben." })
    local first = promptField("Neue PIN", "", true)
    local second = promptField("Wiederholen", "", true)
    if first ~= second then
        runtime.setNotice(state, "PIN stimmt nicht ueberein", 24)
        runtime.log(state, "PIN-Aenderung fehlgeschlagen", "SEC")
        return
    end
    runtime.setPin(state, first)
end

local function promptMessage(state, nativeTerm)
    beginPrompt(nativeTerm, "Funknachricht", { "Ziel-ID leer lassen fuer Broadcast." })
    local targetRaw = promptField("Ziel-ID", "")
    local text = promptField("Text", "")
    local targetId = nil
    if targetRaw and targetRaw ~= "" then
        targetId = tonumber(targetRaw)
    end
    local ok, errorMessage = runtime.sendOperatorMessage(state, targetId, text)
    if ok then
        runtime.setNotice(state, "Funk gesendet", 20)
    else
        runtime.setNotice(state, errorMessage or "Funk fehlgeschlagen", 24)
    end
end

local function denyAction(state, action, reason, context)
    runtime.setNotice(state, reason, 24)
    runtime.log(state, "Aktion blockiert: " .. action .. " (" .. reason .. ")", context and context.source == "remote" and "COMMS" or "SEC")
end

local function handleAction(state, action, nativeTerm, context)
    context = context or { source = "local" }
    if not action then
        return
    end

    local allowed, reason = runtime.authorizeAction(state, action, context)
    if not allowed then
        denyAction(state, action, reason, context)
        return
    end

    if action == "toggle_alarm" then
        runtime.toggleManualAlarm(state)
    elseif action == "rename_ship" then
        promptShipName(state, nativeTerm)
    elseif action == "edit_symbol" then
        promptSymbol(state, nativeTerm)
    elseif action == "login_role" then
        promptRoleLogin(state, nativeTerm)
    elseif action == "logout_role" then
        runtime.logoutRole(state)
    elseif action == "edit_waypoint" then
        promptWaypoint(state, nativeTerm)
    elseif action == "set_home_port" then
        promptHomePort(state, nativeTerm)
    elseif action == "unlock_security" then
        promptUnlock(state, nativeTerm)
    elseif action == "set_pin" then
        promptSetPin(state, nativeTerm)
    elseif action == "save_user" then
        promptSaveUser(state, nativeTerm)
    elseif action == "assign_selected_role" then
        promptAssignRole(state, nativeTerm)
    elseif action == "set_role_code" then
        runtime.setNotice(state, "Rollencodes wurden durch Crew-Konten ersetzt", 28)
    elseif action == "send_message" then
        promptMessage(state, nativeTerm)
    elseif action == "cycle_palette" then
        runtime.cyclePalette(state)
    elseif action == "cycle_factory_requirement" then
        runtime.cycleFactoryRequirement(state)
    elseif action == "cycle_autopilot_program" then
        runtime.cycleAutopilotProgram(state)
    elseif action == "start_autopilot" then
        runtime.startAutopilot(state)
    elseif action == "stop_autopilot" then
        runtime.stopAutopilot(state, context.source == "remote" and "Funkstopp" or "Manuell")
    elseif action == "toggle_thrust" then
        runtime.toggleThrust(state)
    elseif action == "turn_port" then
        runtime.turnPort(state)
    elseif action == "turn_starboard" then
        runtime.turnStarboard(state)
    elseif action == "turn_stop" then
        runtime.stopTurn(state)
    elseif action == "toggle_factory" then
        runtime.toggleFactory(state)
    elseif action == "toggle_reserve" then
        runtime.toggleReserve(state)
    elseif action == "waypoint_prev" then
        runtime.cycleWaypoint(state, -1)
    elseif action == "waypoint_next" then
        runtime.cycleWaypoint(state, 1)
    elseif action == "mode_parking" then
        runtime.setMode(state, "parking")
    elseif action == "mode_docking" then
        runtime.setMode(state, "docking")
    elseif action == "mode_travel" then
        runtime.setMode(state, "travel")
    elseif action == "mode_danger" then
        runtime.setMode(state, "danger")
    elseif action == "mode_emergency" then
        runtime.setMode(state, "emergency")
    elseif action == "role_pilot" then
        runtime.selectRole(state, "pilot")
    elseif action == "role_engineer" then
        runtime.selectRole(state, "engineer")
    elseif action == "role_alarm" then
        runtime.selectRole(state, "alarm")
    elseif action == "role_captain" then
        runtime.selectRole(state, "captain")
    elseif action == "map_helm" then
        runtime.cycleAssignment(state, "helmSignalSide")
    elseif action == "map_fuel" then
        runtime.cycleAssignment(state, "fuelSensorSide")
    elseif action == "map_alarm" then
        runtime.cycleAssignment(state, "alarmOutputSide")
    elseif action == "map_thrust" then
        runtime.cycleAssignment(state, "thrustOutputSide")
    elseif action == "map_port" then
        runtime.cycleAssignment(state, "portOutputSide")
    elseif action == "map_starboard" then
        runtime.cycleAssignment(state, "starboardOutputSide")
    elseif action == "map_factory_output" then
        runtime.cycleAssignment(state, "factoryOutputSide")
    elseif action == "map_generator" then
        runtime.cycleAssignment(state, "generatorSensorSide")
    elseif action == "map_overload" then
        runtime.cycleAssignment(state, "overloadSensorSide")
    elseif action == "map_enemy" then
        runtime.cycleAssignment(state, "enemySensorSide")
    elseif action == "map_key_switch" then
        runtime.cycleAssignment(state, "keySwitchSide")
    elseif action == "map_emergency_stop" then
        runtime.cycleAssignment(state, "emergencyStopSide")
    elseif action == "map_reserve" then
        runtime.cycleAssignment(state, "reserveOutputSide")
    elseif action == "home" or action == "helm" or action == "factory" or action == "navigation" or action == "alarms" or action == "crew" or action == "comms" or action == "log" or action == "settings" then
        runtime.setScreen(state, action)
    end
end

local function render(state)
    runtime.resetTouchTargets(state)
    local screenName = state.activeScreen
    if not screens[screenName] then
        screenName = "home"
    end
    screens[screenName](state)
end

local function shutdown()
    local nativeTerm = term.native()
    term.redirect(nativeTerm)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
    print(theme.brandName .. " shutdown")
end

local function main()
    local nativeTerm = term.native()
    local state = runtime.newState(theme)
    runtime.prepareDisplay(state, nativeTerm)
    runtime.tick(state)
    local tickTimer = os.startTimer(0.2)

    while true do
        runtime.prepareDisplay(state, nativeTerm)
        render(state)
        local event, p1, p2, p3 = os.pullEvent()

        if event == "timer" and p1 == tickTimer then
            runtime.tick(state)
            tickTimer = os.startTimer(0.2)
        elseif event == "char" then
            if p1 == "q" then
                shutdown()
                return
            elseif p1 == "b" then
                runtime.setScreen(state, "home")
            elseif p1 == "m" then
                handleAction(state, "toggle_alarm", nativeTerm)
            elseif p1 == "n" then
                handleAction(state, "rename_ship", nativeTerm)
            elseif p1 == "u" then
                handleAction(state, "unlock_security", nativeTerm)
            elseif p1 == "o" then
                handleAction(state, "set_pin", nativeTerm)
            elseif hotkeys[p1] then
                runtime.setScreen(state, hotkeys[p1])
            elseif state.activeScreen == "home" and tonumber(p1) then
                local nextScreen = state.screenOrder[tonumber(p1) + 1]
                if nextScreen then
                    runtime.setScreen(state, nextScreen)
                end
            end
        elseif event == "key" then
            if p1 == keys.left then
                runtime.previousScreen(state)
            elseif p1 == keys.right then
                runtime.nextScreen(state)
            elseif p1 == keys.space then
                handleAction(state, "toggle_alarm", nativeTerm)
            elseif p1 == keys.enter and state.activeScreen == "settings" then
                handleAction(state, "rename_ship", nativeTerm)
            end
        elseif event == "monitor_touch" then
            handleAction(state, runtime.resolveTouch(state, p1, p2, p3), nativeTerm)
        elseif event == "mouse_click" then
            handleAction(state, runtime.resolveTouch(state, nil, p2, p3), nativeTerm)
        elseif event == "rednet_message" then
            local remoteAction = runtime.handleCommsPacket(state, p1, p2)
            if remoteAction and remoteAction.action then
                handleAction(state, remoteAction.action, nativeTerm, remoteAction)
            end
        end
    end
end

main()