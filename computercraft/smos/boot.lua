local theme = require("smos.app.theme")
local screens = require("smos.app.screens")

local screenOrder = {
    "home",
    "helm",
    "factory",
    "alarms",
    "settings",
}

local hotkeys = {
    h = "helm",
    f = "factory",
    a = "alarms",
    s = "settings",
}

local function screenIndex(name)
    for index, value in ipairs(screenOrder) do
        if value == name then
            return index
        end
    end

    return 1
end

local function render(activeScreen)
    if activeScreen == "home" then
        screens.home(1)
        return
    end

    screens[activeScreen]()
end

local function shutdown()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
    print(theme.brandName .. " shutdown")
end

local function main()
    local activeScreen = "home"

    while true do
        render(activeScreen)
        local _, key = os.pullEvent("char")
        if key == "q" then
            shutdown()
            return
        end

        if key == "b" then
            activeScreen = "home"
        elseif hotkeys[key] then
            activeScreen = hotkeys[key]
        elseif activeScreen == "home" and tonumber(key) then
            local nextScreen = screenOrder[tonumber(key) + 1]
            if nextScreen then
                activeScreen = nextScreen
            end
        end
    end
end

main()
