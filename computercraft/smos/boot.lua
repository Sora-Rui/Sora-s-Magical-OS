local theme = require("app.theme")
local runtime = require("app.runtime")
local screens = require("app.screens")

local hotkeys = {
    h = "helm",
    f = "factory",
    a = "alarms",
    s = "settings",
}

local function promptShipName(state, nativeTerm)
    term.redirect(nativeTerm)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
    print("Sora's Magical OS")
    print("Neuen Schiffsnamen eingeben:")
    write("> ")
    local value = read()
    if value and value ~= "" then
        runtime.setShipName(state, value)
    end
end

local function promptSymbol(state, nativeTerm)
    term.redirect(nativeTerm)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
    print("Sora's Magical OS")
    print("Eigenes Symbol zeichnen")
    print("7 Zeilen, leer = alte Zeile behalten")

    local lines = {}
    for index = 1, 7 do
        write(index .. "> ")
        local value = read()
        if value == "" then
            lines[index] = state.customSymbol[index] or ""
        else
            lines[index] = value
        end
    end

    runtime.setCustomSymbol(state, lines)
end

local function handleAction(state, action, nativeTerm)
    if not action then
        return
    elseif action == "toggle_alarm" then
        runtime.toggleManualAlarm(state)
    elseif action == "rename_ship" then
        promptShipName(state, nativeTerm)
    elseif action == "edit_symbol" then
        promptSymbol(state, nativeTerm)
    elseif action == "cycle_palette" then
        runtime.cyclePalette(state)
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
    elseif action == "home" or action == "helm" or action == "factory" or action == "alarms" or action == "settings" then
        runtime.setScreen(state, action)
    end
end

local function render(state)
    runtime.resetTouchTargets(state)
    local screenName = state.activeScreen
    if screenName == "home" then
        screens.home(state)
        return
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
            end

            if p1 == "b" then
                runtime.setScreen(state, "home")
            elseif p1 == "m" then
                runtime.toggleManualAlarm(state)
            elseif p1 == "n" then
                promptShipName(state, nativeTerm)
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
                runtime.toggleManualAlarm(state)
            elseif p1 == keys.enter and state.activeScreen == "settings" then
                promptShipName(state, nativeTerm)
            end
        elseif event == "monitor_touch" then
            handleAction(state, runtime.resolveTouch(state, p1, p2, p3), nativeTerm)
        elseif event == "mouse_click" then
            handleAction(state, runtime.resolveTouch(state, nil, p2, p3), nativeTerm)
        end
    end
end

main()
