local theme = require("app.theme")
local runtime = require("app.runtime")
local screens = require("app.screens")

local hotkeys = {
    h = "helm",
    f = "factory",
    a = "alarms",
    s = "settings",
}

local function render(state)
    local screenName = state.activeScreen
    if screenName == "home" then
        screens.home(state)
        return
    end

    screens[screenName](state)
end

local function shutdown()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
    print(theme.brandName .. " shutdown")
end

local function main()
    local state = runtime.newState(theme)
    local tickTimer = os.startTimer(1)

    while true do
        render(state)
        local event, key = os.pullEvent()

        if event == "timer" and key == tickTimer then
            runtime.tick(state)
            tickTimer = os.startTimer(1)
        elseif event == "char" then
            if key == "q" then
                shutdown()
                return
            end

            if key == "b" then
                runtime.setScreen(state, "home")
            elseif key == "m" then
                runtime.toggleManualAlarm(state)
            elseif hotkeys[key] then
                runtime.setScreen(state, hotkeys[key])
            elseif state.activeScreen == "home" and tonumber(key) then
                local nextScreen = state.screenOrder[tonumber(key) + 1]
                if nextScreen then
                    runtime.setScreen(state, nextScreen)
                end
            end
        elseif event == "key" then
            if key == keys.left then
                runtime.previousScreen(state)
            elseif key == keys.right then
                runtime.nextScreen(state)
            elseif key == keys.space then
                runtime.toggleManualAlarm(state)
            end
        end
    end
end

main()
