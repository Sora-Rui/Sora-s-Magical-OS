local theme = require("app.theme")
local runtime = require("app.runtime")

local ui = {}

local function centerX(text)
    local width = term.getSize()
    return math.max(1, math.floor((width - #text) / 2) + 1)
end

local function rightX(text, padding)
    local width = term.getSize()
    return math.max(1, width - #text - (padding or 0))
end

function ui.clear(backgroundColor)
    term.setBackgroundColor(backgroundColor or theme.accent)
    term.clear()
    term.setCursorPos(1, 1)
end

function ui.writeAt(x, y, text, textColor, backgroundColor)
    term.setCursorPos(x, y)
    term.setTextColor(textColor or theme.text)
    term.setBackgroundColor(backgroundColor or theme.accent)
    term.write(text)
end

function ui.center(y, text, textColor, backgroundColor)
    ui.writeAt(centerX(text), y, text, textColor, backgroundColor)
end

function ui.fillLine(y, backgroundColor)
    local width = term.getSize()
    ui.writeAt(1, y, string.rep(" ", width), theme.text, backgroundColor or theme.accent)
end

function ui.right(y, text, textColor, backgroundColor, padding)
    ui.writeAt(rightX(text, padding or 1), y, text, textColor, backgroundColor)
end

function ui.frame(title, footer)
    local width, height = term.getSize()
    ui.clear(theme.accent)
    ui.fillLine(1, theme.shadow)
    ui.center(1, " " .. title .. " ", theme.text, theme.shadow)
    ui.fillLine(height, theme.shadow)
    if footer then
        ui.writeAt(2, height, footer, theme.muted, theme.shadow)
    end
    ui.writeAt(rightX(theme.credit, 1), height, theme.credit, colors.gray, theme.shadow)
    for y = 3, height - 2 do
        ui.writeAt(3, y, string.rep(" ", width - 4), theme.text, theme.accent)
    end
end

function ui.panel(x, y, width, height, title)
    for row = 0, height - 1 do
        ui.writeAt(x, y + row, string.rep(" ", width), theme.text, theme.panel)
    end

    if title and title ~= "" then
        ui.writeAt(x + 1, y, " " .. title .. " ", theme.text, theme.panelDark)
    end
end

function ui.skull(x, y)
    local art = {
        "    .-^^-.",
        "  .'/ .-. \\",
        " / /  o o  \\",
        " | |   ^   | |",
        " | |  ---  | |",
        " \\ \\_____// /",
        "  '._____.'",
    }

    for index, line in ipairs(art) do
        ui.writeAt(x, y + index - 1, line, theme.accentLight, theme.accent)
    end
end

function ui.menu(startY, options, selected)
    for index, option in ipairs(options) do
        local active = index == selected
        local backgroundColor = active and theme.accentLight or theme.panel
        local textColor = active and theme.shadow or theme.text
        ui.center(startY + (index - 1) * 2, "[ " .. option .. " ]", textColor, backgroundColor)
    end
end

function ui.kv(x, y, label, value, valueColor, backgroundColor)
    ui.writeAt(x, y, label, theme.muted, backgroundColor or theme.panel)
    ui.writeAt(x, y + 1, value, valueColor or theme.text, backgroundColor or theme.panel)
end

function ui.statusBar(state)
    local alarmText, alarmColor = runtime.alarmStatus(state)
    local speakerText, speakerColor = runtime.speakerStatus(state)
    local signalText, signalColor = runtime.signalStatus(state)

    ui.panel(4, 3, 46, 3, " Statusleiste ")
    ui.kv(6, 4, "Signal", signalText, signalColor)
    ui.kv(20, 4, "Alarm", alarmText, alarmColor)
    ui.kv(34, 4, "Speaker", speakerText, speakerColor)
end

function ui.statusRow(y, label, value, valueColor)
    ui.writeAt(6, y, label .. ":", theme.muted, theme.accent)
    ui.writeAt(22, y, value, valueColor or theme.text, theme.accent)
end

return ui
