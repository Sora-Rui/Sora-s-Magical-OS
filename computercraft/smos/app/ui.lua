local theme = require("app.theme")
local runtime = require("app.runtime")

local ui = {}

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

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
    local width, height = term.getSize()
    if y < 1 or y > height then
        return
    end

    local safeX = clamp(x, 1, width)
    local maxLength = width - safeX + 1
    if maxLength <= 0 then
        return
    end

    local renderedText = text
    if #renderedText > maxLength then
        renderedText = renderedText:sub(1, maxLength)
    end

    term.setCursorPos(safeX, y)
    term.setTextColor(textColor or theme.text)
    term.setBackgroundColor(backgroundColor or theme.accent)
    term.write(renderedText)
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
    if width < 4 or height < 2 then
        return
    end

    for row = 0, height - 1 do
        ui.writeAt(x, y + row, string.rep(" ", width), theme.text, theme.panel)
    end

    if title and title ~= "" then
        ui.writeAt(x + 1, y, " " .. title .. " ", theme.text, theme.panelDark)
    end
end

function ui.button(state, x, y, width, label, action, active)
    local backgroundColor = active and theme.accentLight or theme.panelDark
    local textColor = active and theme.shadow or theme.text
    local rendered = " " .. label .. " "
    local padding = math.max(0, width - #rendered)
    rendered = rendered .. string.rep(" ", padding)
    ui.writeAt(x, y, rendered, textColor, backgroundColor)
    if state then
        runtime.registerTouchTarget(state, {
            x = x,
            y = y,
            width = math.max(width, #rendered),
            height = 1,
            action = action,
        })
    end
end

function ui.skull(x, y)
    local art = {
        "   .-^^-.",
        " .' x  x '.",
        "/    --    \\",
        "|  .____.  |",
        "|  |____|  |",
        " \\  __  //",
        "  '.__.'",
    }

    for index, line in ipairs(art) do
        ui.writeAt(x, y + index - 1, line, theme.accentLight, theme.accent)
    end
end

function ui.warningOverlay(title, lines, blinkOn)
    local width, height = term.getSize()
    if not blinkOn then
        return
    end

    local overlayWidth = math.max(20, math.min(width - 6, 30))
    local overlayHeight = math.max(6, math.min(height - 6, 9))
    local originX = math.floor((width - overlayWidth) / 2) + 1
    local originY = math.floor((height - overlayHeight) / 2) + 1

    for row = 0, overlayHeight - 1 do
        ui.writeAt(originX, originY + row, string.rep(" ", overlayWidth), theme.text, theme.warning)
    end

    ui.center(originY + 1, "/!\\  " .. title .. "  /!\\", theme.text, theme.warning)
    for index, line in ipairs(lines) do
        ui.center(originY + 2 + index, line, theme.shadow, theme.warning)
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

    local width = term.getSize()
    local panelX = 2
    local panelWidth = math.max(18, width - 2)
    ui.panel(panelX, 3, panelWidth, 3, " Status ")

    if width >= 48 then
        ui.kv(4, 4, "Signal", signalText, signalColor)
        ui.kv(18, 4, "Alarm", alarmText, alarmColor)
        ui.kv(32, 4, "Speaker", speakerText, speakerColor)
    else
        ui.kv(4, 4, "Alarm", alarmText, alarmColor)
        ui.kv(20, 4, "Speaker", speakerText, speakerColor)
    end
end

function ui.statusRow(y, label, value, valueColor)
    ui.writeAt(6, y, label .. ":", theme.muted, theme.accent)
    ui.writeAt(22, y, value, valueColor or theme.text, theme.accent)
end

return ui
