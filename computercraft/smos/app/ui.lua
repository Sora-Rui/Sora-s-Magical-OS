local theme = require("app.theme")
local runtime = require("app.runtime")

local ui = {}

local NAV_TABS = {
    { label = "Helm", action = "helm" },
    { label = "Fabrik", action = "factory" },
    { label = "Navigation", action = "navigation" },
    { label = "Alarm", action = "alarms" },
    { label = "Crew", action = "crew" },
    { label = "Funk", action = "comms" },
    { label = "Log", action = "log" },
    { label = "System", action = "settings" },
}

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

function ui.isLargeLayout()
    local width, height = term.getSize()
    return width >= 70 and height >= 24
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

    local renderedText = text or ""
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

function ui.frame(title, footer, state)
    local width, height = term.getSize()
    local frameColor = state and runtime.modeColor(state) or theme.shadow
    ui.clear(theme.accent)
    ui.fillLine(1, frameColor)
    if state and state.activeScreen ~= "home" then
        ui.button(state, 2, 1, 6, "Home", "home")
    end
    ui.center(1, " " .. title .. " ", theme.text, frameColor)
    ui.fillLine(height, frameColor)
    if footer then
        ui.writeAt(2, height, footer, theme.muted, frameColor)
    end
    ui.writeAt(rightX(theme.credit, 1), height, theme.credit, colors.gray, frameColor)
    for y = 3, height - 2 do
        ui.writeAt(2, y, string.rep(" ", math.max(1, width - 1)), theme.text, theme.accent)
    end
end

function ui.monitorFrame(title, subtitle, state)
    local width = term.getSize()
    local radioText, radioColor = runtime.radioStatus(state)
    local positionText, positionColor = runtime.headerPositionLabel(state)
    ui.frame(title, "Touch aktiv  |  M Alarm  |  Q Ende", state)
    ui.panel(2, 3, width - 2, 4, " Bruecke ")
    ui.writeAt(4, 4, subtitle or "", theme.accentLight, theme.panel)
    ui.right(4, textutils.formatTime(os.time(), true), theme.text, theme.panel)
    ui.writeAt(4, 5, state.shipName or theme.shipName, theme.text, theme.panel)
    ui.writeAt(30, 5, "Modus: " .. runtime.modeLabel(state), theme.text, theme.panel)
    ui.writeAt(4, 6, "Rolle: " .. runtime.roleLabel(state), theme.muted, theme.panel)
    ui.writeAt(30, 6, radioText, radioColor, theme.panel)
    ui.right(5, positionText, positionColor, theme.panel)
end

function ui.panel(x, y, width, height, title)
    if width < 4 or height < 2 then
        return
    end

    for row = 0, height - 1 do
        ui.writeAt(x, y + row, string.rep(" ", width), theme.text, theme.panel)
    end

    if title and title ~= "" then
        ui.writeAt(x + 1, y, " " .. title .. " ", theme.text, theme.accent)
    end
end

function ui.button(state, x, y, width, label, action, active)
    local backgroundColor = active and theme.accentLight or theme.panelDark
    local textColor = active and theme.shadow or theme.text
    local rendered = " " .. label .. " "
    local paddedWidth = math.max(width, #rendered)
    rendered = rendered .. string.rep(" ", paddedWidth - #rendered)
    ui.writeAt(x, y, rendered, textColor, backgroundColor)
    if state then
        runtime.registerTouchTarget(state, {
            x = x,
            y = y,
            width = paddedWidth,
            height = 1,
            action = action,
        })
    end
end

function ui.navTabs(state, startY, activeScreen)
    local width = term.getSize()
    local x = 4
    local y = startY
    for _, tab in ipairs(NAV_TABS) do
        local buttonWidth = #tab.label + 3
        if x + buttonWidth > width - 2 then
            x = 4
            y = y + 1
        end
        if runtime.canAccessScreen(state, tab.action) then
            ui.button(state, x, y, buttonWidth, tab.label, tab.action, activeScreen == tab.action)
        else
            ui.writeAt(x, y, " " .. tab.label .. " ", theme.muted, theme.panel)
        end
        x = x + buttonWidth + 1
    end
    return y
end

function ui.drawSymbol(state, x, y, backgroundColor)
    local art = state.customSymbol or {
        "   .-^^-.",
        " .' x  x '.",
        "/    --    \\",
        "|  .____.  |",
        "|  |____|  |",
        " \\  __  //",
        "  '.__.'",
    }

    for index, line in ipairs(art) do
        ui.writeAt(x, y + index - 1, line, theme.accentLight, backgroundColor or theme.panel)
    end
end

function ui.warningOverlay(title, lines, blinkOn, pulseOn)
    local width, height = term.getSize()
    if not blinkOn then
        return
    end

    if pulseOn == nil then
        pulseOn = true
    end

    local background = pulseOn and theme.warning or theme.shadow
    local titleColor = pulseOn and theme.text or theme.warning
    local textColor = pulseOn and theme.shadow or theme.text

    local overlayWidth = math.max(20, math.min(width - 6, 34))
    local overlayHeight = math.max(6, math.min(height - 6, 10))
    local originX = math.floor((width - overlayWidth) / 2) + 1
    local originY = math.floor((height - overlayHeight) / 2) + 1

    for row = 0, overlayHeight - 1 do
        ui.writeAt(originX, originY + row, string.rep(" ", overlayWidth), titleColor, background)
    end

    ui.center(originY + 1, "/!\\  " .. title .. "  /!\\", titleColor, background)
    for index, line in ipairs(lines) do
        ui.center(originY + 2 + index, line, textColor, background)
    end
end

function ui.kv(x, y, label, value, valueColor, backgroundColor)
    ui.writeAt(x, y, label, theme.muted, backgroundColor or theme.panel)
    ui.writeAt(x, y + 1, value, valueColor or theme.text, backgroundColor or theme.panel)
end

function ui.metricPanel(x, y, width, title, value, valueColor, subtitle)
    ui.panel(x, y, width, 5, title)
    ui.writeAt(x + 2, y + 2, value, valueColor or theme.text, theme.panel)
    if subtitle then
        ui.writeAt(x + 2, y + 3, subtitle, theme.muted, theme.panel)
    end
end

function ui.statusBar(state)
    local alarmText, alarmColor = runtime.alarmStatus(state)
    local radioText, radioColor = runtime.radioStatus(state)
    local width = term.getSize()
    local panelX = 2
    local panelWidth = math.max(18, width - 2)
    ui.panel(panelX, 3, panelWidth, 3, " Status ")
    ui.kv(4, 4, "Modus", runtime.modeLabel(state), runtime.modeColor(state))
    ui.kv(18, 4, "Alarm", alarmText, alarmColor)
    ui.kv(34, 4, "Funk", radioText, radioColor)
    if width >= 60 then
        ui.kv(50, 4, "Rolle", runtime.roleLabel(state), theme.text)
    end
end

function ui.statusRow(y, label, value, valueColor)
    ui.writeAt(4, y, label .. ":", theme.muted, theme.accent)
    ui.writeAt(20, y, value, valueColor or theme.text, theme.accent)
end

return ui