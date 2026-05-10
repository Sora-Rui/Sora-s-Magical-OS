local theme = require("smos.app.theme")

local ui = {}

local function centerX(text)
    local width = term.getSize()
    return math.max(1, math.floor((width - #text) / 2) + 1)
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

function ui.frame(title, footer)
    local width, height = term.getSize()
    ui.clear(theme.accent)
    ui.fillLine(1, theme.shadow)
    ui.center(1, " " .. title .. " ", theme.text, theme.shadow)
    ui.fillLine(height, theme.shadow)
    if footer then
        ui.center(height, footer, theme.muted, theme.shadow)
    end
    for y = 3, height - 2 do
        ui.writeAt(3, y, string.rep(" ", width - 4), theme.text, theme.accent)
    end
end

function ui.jollyRoger(x, y)
    local art = {
        "   .-^-.",
        "  /_/_\\_\\",
        "  \\_o o_/",
        "   / ^ \\",
        "  /|===|\\",
        "    | |",
        "   /   \\",
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

function ui.statusRow(y, label, value, valueColor)
    ui.writeAt(6, y, label .. ":", theme.muted, theme.accent)
    ui.writeAt(22, y, value, valueColor or theme.text, theme.accent)
end

return ui
