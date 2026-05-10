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

local function centerX(width, text)
    return math.max(1, math.floor((width - #text) / 2) + 1)
end

local function setPromptCancelled(state)
    runtime.setNotice(state, "Eingabe abgebrochen", 20)
end

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

local function drawMonitorPromptOverlay(state, title)
    if not state.monitor or not state.monitorName then
        return nil
    end

    local current = term.current()
    term.redirect(state.monitor)
    local width, height = term.getSize()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()

    term.setCursorPos(1, 1)
    term.setBackgroundColor(runtime.modeColor(state))
    term.write(string.rep(" ", width))
    term.setBackgroundColor(colors.black)

    local titleText = "Eingabe aktiv"
    local message = "Bitte Eingabe im Computer ausfuehren"
    local cancelLabel = " Abbrechen "
    local buttonX = centerX(width, cancelLabel)
    local buttonY = math.max(6, math.min(height - 2, math.floor(height * 0.7)))

    term.setCursorPos(centerX(width, titleText), 2)
    term.setTextColor(colors.white)
    term.write(titleText)

    term.setCursorPos(centerX(width, message), 4)
    term.setTextColor(colors.orange)
    term.write(message)

    term.setCursorPos(centerX(width, title or ""), 5)
    term.setTextColor(colors.lightGray)
    term.write(title or "")

    term.setCursorPos(buttonX, buttonY)
    term.setBackgroundColor(colors.red)
    term.setTextColor(colors.white)
    term.write(cancelLabel)

    term.redirect(current)
    return {
        side = state.monitorName,
        x = buttonX,
        y = buttonY,
        width = #cancelLabel,
        height = 1,
    }
end

local function renderPromptField(nativeTerm, title, instructions, label, defaultValue, currentValue, secret)
    beginPrompt(nativeTerm, title, instructions)
    local shownDefault = defaultValue and defaultValue ~= "" and (" [" .. tostring(defaultValue) .. "]") or ""
    print("")
    print(label .. shownDefault)
    local shownValue = secret and string.rep("*", #currentValue) or currentValue
    print("> " .. shownValue)
    print("")
    print("Enter bestaetigt | Backspace loescht")
    print("Esc oder Monitor-Button bricht ab")
end

local function promptField(state, nativeTerm, title, instructions, label, defaultValue, secret)
    local currentValue = ""
    local cancelTarget = drawMonitorPromptOverlay(state, title)

    while true do
        renderPromptField(nativeTerm, title, instructions, label, defaultValue, currentValue, secret)
        local event, p1, p2, p3 = os.pullEvent()

        if event == "char" then
            currentValue = currentValue .. p1
        elseif event == "paste" then
            currentValue = currentValue .. tostring(p1 or "")
        elseif event == "key" then
            if p1 == keys.enter then
                if currentValue == "" then
                    return defaultValue, false
                end
                return currentValue, false
            elseif p1 == keys.backspace then
                currentValue = currentValue:sub(1, math.max(0, #currentValue - 1))
            elseif p1 == keys.delete then
                currentValue = ""
            elseif p1 == keys.escape then
                return nil, true
            end
        elseif event == "monitor_touch" and cancelTarget and p1 == cancelTarget.side then
            if p2 >= cancelTarget.x and p2 <= cancelTarget.x + cancelTarget.width - 1 and p3 == cancelTarget.y then
                return nil, true
            end
        end
    end
end

local function promptShipName(state, nativeTerm)
    local value, cancelled = promptField(state, nativeTerm, "Schiffsname aendern", { "Neuen Namen eingeben." }, "Name", state.shipName)
    if cancelled then
        setPromptCancelled(state)
        return
    end
    if value and value ~= "" then
        runtime.setShipName(state, value)
    end
end

local function promptSymbol(state, nativeTerm)
    local lines = {}
    for index = 1, 7 do
        local value, cancelled = promptField(state, nativeTerm, "Eigenes Symbol", { "7 Zeilen, leer = alte Zeile behalten." }, tostring(index), state.customSymbol[index] or "")
        if cancelled then
            setPromptCancelled(state)
            return
        end
        lines[index] = value
    end
    runtime.setCustomSymbol(state, lines)
end

local function promptWaypoint(state, nativeTerm)
    local waypoint = runtime.currentWaypoint(state)
    local promptLines = { "Name, Distanz und Richtung anpassen." }
    local name, cancelled = promptField(state, nativeTerm, "Wegpunkt bearbeiten", promptLines, "Ziel", waypoint.name)
    if cancelled then
        setPromptCancelled(state)
        return
    end
    local distance
    distance, cancelled = promptField(state, nativeTerm, "Wegpunkt bearbeiten", promptLines, "Distanz", waypoint.distance)
    if cancelled then
        setPromptCancelled(state)
        return
    end
    local direction
    direction, cancelled = promptField(state, nativeTerm, "Wegpunkt bearbeiten", promptLines, "Richtung", waypoint.direction)
    if cancelled then
        setPromptCancelled(state)
        return
    end
    runtime.updateWaypoint(state, {
        name = name,
        distance = distance,
        direction = direction,
    })
end

local function promptHomePort(state, nativeTerm)
    local value, cancelled = promptField(state, nativeTerm, "Heimathafen", { "Name des Heimathafens eingeben." }, "Heimathafen", state.navigation.homePort)
    if cancelled then
        setPromptCancelled(state)
        return
    end
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
    local defaultUser = runtime.currentUsername(state) ~= "-" and runtime.currentUsername(state) or ""
    local username, cancelled = promptField(state, nativeTerm, "Crew-Login", instructions, "Benutzer", defaultUser)
    if cancelled then
        setPromptCancelled(state)
        return
    end
    local password
    password, cancelled = promptField(state, nativeTerm, "Crew-Login", instructions, "Passwort", "", true)
    if cancelled then
        setPromptCancelled(state)
        return
    end
    runtime.loginRole(state, state.crew.selectedRole, username, password)
end

local function promptSaveUser(state, nativeTerm)
    local instructions = {
        "Crew-Leitung legt hier Benutzername und Passwort fest.",
        "Bestehender Benutzer wird mit neuem Passwort aktualisiert.",
    }
    local username, cancelled = promptField(state, nativeTerm, "Crew-Konto", instructions, "Benutzer", "")
    if cancelled then
        setPromptCancelled(state)
        return
    end
    local first
    first, cancelled = promptField(state, nativeTerm, "Crew-Konto", instructions, "Passwort", "", true)
    if cancelled then
        setPromptCancelled(state)
        return
    end
    local second
    second, cancelled = promptField(state, nativeTerm, "Crew-Konto", instructions, "Wiederholen", "", true)
    if cancelled then
        setPromptCancelled(state)
        return
    end
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
    local instructions = {
        "Rolle: " .. runtime.selectedRoleLabel(state),
        "Die aktuell gewaehlte Rolle wird einem Benutzer zugewiesen.",
    }
    local username, cancelled = promptField(state, nativeTerm, "Rolle vergeben", instructions, "Benutzer", "")
    if cancelled then
        setPromptCancelled(state)
        return
    end
    local ok, reason = runtime.assignRoleToUser(state, username, state.crew.selectedRole)
    if not ok then
        runtime.setNotice(state, reason or "Rollenzuweisung fehlgeschlagen", 24)
        runtime.log(state, "Rollenzuweisung fehlgeschlagen", "SEC")
    end
end

local function promptRemoveRole(state, nativeTerm)
    local instructions = {
        "Rolle: " .. runtime.selectedRoleLabel(state),
        "Die aktuell gewaehlte Rolle wird vom Benutzer entfernt.",
    }
    local username, cancelled = promptField(state, nativeTerm, "Rolle entziehen", instructions, "Benutzer", "")
    if cancelled then
        setPromptCancelled(state)
        return
    end
    local ok, reason = runtime.removeRoleFromUser(state, username, state.crew.selectedRole)
    if not ok then
        runtime.setNotice(state, reason or "Rollenentzug fehlgeschlagen", 24)
        runtime.log(state, "Rollenentzug fehlgeschlagen", "SEC")
    end
end

local function promptDeleteUser(state, nativeTerm)
    local instructions = {
        "Benutzername eingeben.",
        "Gruender-Captain und eigenes Konto sind geschuetzt.",
    }
    local username, cancelled = promptField(state, nativeTerm, "Crew-Konto loeschen", instructions, "Benutzer", "")
    if cancelled then
        setPromptCancelled(state)
        return
    end
    local ok, reason = runtime.deleteCrewUser(state, username)
    if not ok then
        runtime.setNotice(state, reason or "Loeschen fehlgeschlagen", 24)
        runtime.log(state, "Crew-Loeschung fehlgeschlagen", "SEC")
    end
end

local function promptUnlock(state, nativeTerm)
    local pin, cancelled = promptField(state, nativeTerm, "PIN-Freigabe", { "PIN eingeben, um kritische Funktionen freizugeben." }, "PIN", "", true)
    if cancelled then
        setPromptCancelled(state)
        return
    end
    runtime.unlockWithPin(state, pin)
end

local function promptSetPin(state, nativeTerm)
    local instructions = { "Neue PIN zweimal eingeben." }
    local first, cancelled = promptField(state, nativeTerm, "Neue PIN", instructions, "Neue PIN", "", true)
    if cancelled then
        setPromptCancelled(state)
        return
    end
    local second
    second, cancelled = promptField(state, nativeTerm, "Neue PIN", instructions, "Wiederholen", "", true)
    if cancelled then
        setPromptCancelled(state)
        return
    end
    if first ~= second then
        runtime.setNotice(state, "PIN stimmt nicht ueberein", 24)
        runtime.log(state, "PIN-Aenderung fehlgeschlagen", "SEC")
        return
    end
    runtime.setPin(state, first)
end

local function promptMessage(state, nativeTerm)
    local instructions = { "Ziel-ID leer lassen fuer Broadcast." }
    local targetRaw, cancelled = promptField(state, nativeTerm, "Funknachricht", instructions, "Ziel-ID", "")
    if cancelled then
        setPromptCancelled(state)
        return
    end
    local text
    text, cancelled = promptField(state, nativeTerm, "Funknachricht", instructions, "Text", "")
    if cancelled then
        setPromptCancelled(state)
        return
    end
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
    elseif action == "remove_selected_role" then
        promptRemoveRole(state, nativeTerm)
    elseif action == "delete_user" then
        promptDeleteUser(state, nativeTerm)
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
    elseif action == "role_co_captain" then
        runtime.selectRole(state, "co_captain")
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