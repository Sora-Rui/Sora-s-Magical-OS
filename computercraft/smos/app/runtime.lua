local runtime = {}

local screenOrder = {
    "home",
    "helm",
    "factory",
    "alarms",
    "settings",
}

local alarmNotes = {
    { instrument = "bass", pitch = 8 },
    { instrument = "bell", pitch = 16 },
}

local function findSpeaker()
    if not peripheral or not peripheral.find then
        return nil
    end

    return peripheral.find("speaker")
end

function runtime.newState(theme)
    return {
        theme = theme,
        shipName = theme.shipName,
        screenOrder = screenOrder,
        activeScreen = "home",
        selectedIndex = 1,
        speaker = findSpeaker(),
        manualAlarm = false,
        signalOnline = false,
        alarmPulse = 1,
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

function runtime.tick(state)
    runtime.refreshPeripherals(state)

    if not state.manualAlarm or not state.speaker then
        return
    end

    local note = alarmNotes[state.alarmPulse]
    state.speaker.playNote(note.instrument, 3, note.pitch)
    state.alarmPulse = state.alarmPulse + 1
    if state.alarmPulse > #alarmNotes then
        state.alarmPulse = 1
    end
end

return runtime
