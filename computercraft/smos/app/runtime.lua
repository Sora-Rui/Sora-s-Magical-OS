local runtime = {}

local CONFIG_PATH = "/smos/config.txt"
local ASSIGNABLE_SIDES = { "none", "top", "bottom", "left", "right", "front", "back" }

local screenOrder = {
    "home",
    "helm",
    "factory",
    "alarms",
    "settings",
}

local alarmNotes = {
    { instrument = "bass", pitch = 4 },
    { instrument = "didgeridoo", pitch = 7 },
    { instrument = "bell", pitch = 17 },
    { instrument = "bass", pitch = 2 },
}

local function loadConfig()
    if not fs.exists(CONFIG_PATH) then
        return {}
    end

    local handle = fs.open(CONFIG_PATH, "r")
    if not handle then
        return {}
    end

    local raw = handle.readAll()
    handle.close()
    local decoded = textutils.unserialize(raw)
    if type(decoded) ~= "table" then
        return {}
    end

    return decoded
end

local function saveConfig(state)
    fs.makeDir("/smos")
    local handle = fs.open(CONFIG_PATH, "w")
    if not handle then
        return false
    end

    handle.write(textutils.serialize({
        shipName = state.shipName,
        assignments = state.assignments,
        preferMonitor = state.preferMonitor,
    }))
    handle.close()
    return true
end

local function findMonitor()
    if not peripheral or not peripheral.find then
        return nil, nil
    end

    return peripheral.find("monitor")
end

local function findSpeaker()
    if not peripheral or not peripheral.find then
        return nil
    end

    return peripheral.find("speaker")
end

function runtime.newState(theme)
    local config = loadConfig()
    local monitor, monitorName = findMonitor()

    return {
        theme = theme,
        shipName = config.shipName or theme.shipName,
        screenOrder = screenOrder,
        activeScreen = "home",
        selectedIndex = 1,
        speaker = findSpeaker(),
        monitor = monitor,
        monitorName = monitorName,
        preferMonitor = config.preferMonitor ~= false,
        manualAlarm = false,
        signalOnline = false,
        alarmPulse = 1,
        alarmFlash = false,
        touchTargets = {},
        assignments = config.assignments or {
            helmSignalSide = "back",
            fuelSensorSide = "left",
            alarmOutputSide = "right",
        },
        helm = {
            thrust = "Leerlauf",
            heading = "Still",
            altitude = "Noch manuell",
            failsafe = "Aktiv",
        },
        factory = {
            lineA = "Bereit",
            fuel = "Tankbeobachter pruefen",
            storage = "Sensorschema offen",
            mode = "Nur vorhandene Mods",
        },
    }
end

function runtime.refreshPeripherals(state)
    state.speaker = findSpeaker()
    state.monitor, state.monitorName = findMonitor()
end

function runtime.save(state)
    saveConfig(state)
end

function runtime.setShipName(state, shipName)
    if shipName and shipName ~= "" then
        state.shipName = shipName
        saveConfig(state)
    end
end

function runtime.cycleAssignment(state, assignmentKey)
    local current = state.assignments[assignmentKey] or "none"
    local nextIndex = 1
    for index, side in ipairs(ASSIGNABLE_SIDES) do
        if side == current then
            nextIndex = index + 1
            break
        end
    end

    if nextIndex > #ASSIGNABLE_SIDES then
        nextIndex = 1
    end

    state.assignments[assignmentKey] = ASSIGNABLE_SIDES[nextIndex]
    saveConfig(state)
    return state.assignments[assignmentKey]
end

function runtime.screenIndex(state)
    for index, name in ipairs(state.screenOrder) do
        if name == state.activeScreen then
            return index
        end
    end

    return 1
end

function runtime.setScreen(state, screenName)
    for index, name in ipairs(state.screenOrder) do
        if name == screenName then
            state.activeScreen = screenName
            state.selectedIndex = index
            return true
        end
    end

    return false
end

function runtime.nextScreen(state)
    local nextIndex = runtime.screenIndex(state) + 1
    if nextIndex > #state.screenOrder then
        nextIndex = 1
    end

    runtime.setScreen(state, state.screenOrder[nextIndex])
end

function runtime.previousScreen(state)
    local previousIndex = runtime.screenIndex(state) - 1
    if previousIndex < 1 then
        previousIndex = #state.screenOrder
    end

    runtime.setScreen(state, state.screenOrder[previousIndex])
end

function runtime.toggleManualAlarm(state)
    state.manualAlarm = not state.manualAlarm
    if not state.manualAlarm then
        state.alarmFlash = false
    end
    return state.manualAlarm
end

function runtime.alarmStatus(state)
    if state.manualAlarm then
        return "Manuell aktiv", state.theme.warning
    end

    return "Keine", state.theme.ok
end

function runtime.speakerStatus(state)
    if state.speaker then
        return "Verbunden", state.theme.ok
    end

    return "Nicht gefunden", state.theme.warning
end

function runtime.signalStatus(state)
    if state.signalOnline then
        return "Online", state.theme.ok
    end

    return "Standby", state.theme.muted
end

function runtime.describeAssignment(state, key)
    local value = state.assignments[key] or "none"
    if value == "none" then
        return "Nicht zugeordnet"
    end

    return value
end

function runtime.isAlarmVisible(state)
    return state.manualAlarm and state.alarmFlash
end

function runtime.prepareDisplay(state, nativeTerm)
    if state.preferMonitor and state.monitor then
        state.monitor.setTextScale(0.5)
        term.redirect(state.monitor)
        return state.monitor
    end

    term.redirect(nativeTerm)
    return nativeTerm
end

function runtime.resetTouchTargets(state)
    state.touchTargets = {}
end

function runtime.registerTouchTarget(state, target)
    table.insert(state.touchTargets, target)
end

function runtime.resolveTouch(state, side, x, y)
    if state.monitorName and side ~= state.monitorName then
        return nil
    end

    for _, target in ipairs(state.touchTargets) do
        if x >= target.x and x <= target.x + target.width - 1 and y >= target.y and y <= target.y + target.height - 1 then
            return target.action
        end
    end

    return nil
end

local function readAssignmentInput(state)
    local helmSide = state.assignments.helmSignalSide
    local fuelSide = state.assignments.fuelSensorSide
    state.signalOnline = (helmSide and helmSide ~= "none" and redstone.getInput(helmSide)) or (fuelSide and fuelSide ~= "none" and redstone.getInput(fuelSide)) or false

    if helmSide and helmSide ~= "none" and redstone.getInput(helmSide) then
        state.helm.heading = "Signal erkannt"
    else
        state.helm.heading = "Still"
    end

    if fuelSide and fuelSide ~= "none" and redstone.getInput(fuelSide) then
        state.factory.fuel = "Tank okay"
    else
        state.factory.fuel = "Tank pruefen"
    end
end

function runtime.tick(state)
    runtime.refreshPeripherals(state)
    readAssignmentInput(state)

    local alarmOutputSide = state.assignments.alarmOutputSide
    if alarmOutputSide and alarmOutputSide ~= "none" then
        redstone.setOutput(alarmOutputSide, state.manualAlarm and state.alarmFlash)
    end

    if not state.manualAlarm or not state.speaker then
        state.alarmFlash = false
        return
    end

    state.alarmFlash = not state.alarmFlash
    local note = alarmNotes[state.alarmPulse]
    state.speaker.playNote(note.instrument, 3, note.pitch)
    state.alarmPulse = state.alarmPulse + 1
    if state.alarmPulse > #alarmNotes then
        state.alarmPulse = 1
    end
end

return runtime
