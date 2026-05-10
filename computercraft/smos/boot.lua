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

local function handleAction(state, action, nativeTerm)
    if action == "toggle_alarm" then
        runtime.toggleManualAlarm(state)
    elseif action == "rename_ship" then
        promptShipName(state, nativeTerm)
    elseif action == "map_helm" then
        runtime.cycleAssignment(state, "helmSignalSide")
    elseif action == "map_fuel" then
        runtime.cycleAssignment(state, "fuelSensorSide")
    elseif action == "map_alarm" then
        runtime.cycleAssignment(state, "alarmOutputSide")
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
        end
    end
end

main()
