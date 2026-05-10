local runtime = {}

local CONFIG_PATH = "/smos/config.txt"
local LOG_PATH = "/smos/log.txt"
local AUDIO_DIR = "/smos/audio"
local ASSIGNABLE_SIDES = { "none", "top", "bottom", "left", "right", "front", "back" }
local PALETTES = {
    crimson = {
        accent = colors.red,
        accentLight = colors.orange,
        text = colors.white,
        muted = colors.lightGray,
        shadow = colors.black,
        warning = colors.yellow,
        ok = colors.lime,
        panel = colors.gray,
        panelDark = colors.brown,
    },
    ocean = {
        accent = colors.blue,
        accentLight = colors.lightBlue,
        text = colors.white,
        muted = colors.lightGray,
        shadow = colors.black,
        warning = colors.red,
        ok = colors.lime,
        panel = colors.gray,
        panelDark = colors.cyan,
    },
    royal = {
        accent = colors.purple,
        accentLight = colors.magenta,
        text = colors.white,
        muted = colors.lightGray,
        shadow = colors.black,
        warning = colors.red,
        ok = colors.lime,
        panel = colors.gray,
        panelDark = colors.lightBlue,
    },
}
local PALETTE_ORDER = { "crimson", "ocean", "royal" }
local DEFAULT_SYMBOL = {
    "   .-'''-.",
    "  /  .-.  \\",
    " |  /   \\  |",
    " | |  X  | |",
    " | | --- | |",
    "  \\ '---' //",
    "   '.___.'",
}

local SCREEN_ORDER = {
    "home",
    "helm",
    "factory",
    "navigation",
    "alarms",
    "crew",
    "comms",
    "log",
    "settings",
}

local ASSIGNMENT_DEFAULTS = {
    helmSignalSide = "back",
    fuelSensorSide = "left",
    alarmOutputSide = "right",
    thrustOutputSide = "top",
    portOutputSide = "front",
    starboardOutputSide = "bottom",
    factoryOutputSide = "none",
    generatorSensorSide = "none",
    overloadSensorSide = "none",
    enemySensorSide = "none",
    keySwitchSide = "none",
    emergencyStopSide = "none",
    reserveOutputSide = "none",
}

local alarmNotes = {
    { instrument = "bass", pitch = 4 },
    { instrument = "didgeridoo", pitch = 7 },
    { instrument = "bell", pitch = 17 },
    { instrument = "bass", pitch = 2 },
}

local alarmSounds = {
    { name = "block.bell.use", pitch = 0.9 },
    { name = "entity.creeper.primed", pitch = 1.0 },
    { name = "block.beacon.power_select", pitch = 0.9 },
    { name = "block.bell.use", pitch = 1.1 },
}

local DEFAULT_AUDIO_CUES = {
    {
        key = "builtin:bridge_bell",
        label = "Bruecken-Gong",
        kind = "sound",
        sound = "block.bell.use",
        volume = 3,
        pitch = 1.1,
    },
    {
        key = "builtin:red_alert",
        label = "Roter Alarm",
        kind = "sound",
        sound = "entity.creeper.primed",
        volume = 3,
        pitch = 1.0,
    },
    {
        key = "builtin:beacon_ping",
        label = "Beacon Ping",
        kind = "sound",
        sound = "block.beacon.power_select",
        volume = 3,
        pitch = 0.9,
    },
}

local MODE_DEFINITIONS = {
    parking = {
        label = "Parken",
        description = "Antrieb gesichert, Fabrik in Ruhe",
        color = colors.gray,
        reserveMode = false,
        factoryEnabled = false,
        modeAlarm = false,
        stopMotion = true,
    },
    docking = {
        label = "Docking",
        description = "Praeziser Naeherungsmodus",
        color = colors.lightBlue,
        reserveMode = false,
        factoryEnabled = false,
        modeAlarm = false,
        stopMotion = false,
    },
    travel = {
        label = "Reise",
        description = "Reiseflug mit Brueckenfokus",
        color = colors.orange,
        reserveMode = false,
        factoryEnabled = false,
        modeAlarm = false,
        stopMotion = false,
    },
    danger = {
        label = "Gefahr",
        description = "Kampf- oder Gefahrenlage",
        color = colors.red,
        reserveMode = true,
        factoryEnabled = false,
        modeAlarm = true,
        stopMotion = false,
    },
    emergency = {
        label = "Notfall",
        description = "Notfallprotokoll aktiv",
        color = colors.yellow,
        reserveMode = true,
        factoryEnabled = false,
        modeAlarm = true,
        stopMotion = true,
    },
}

local CHECKLIST_FACTORY_ORDER = { "Standby", "Produktion", "Beliebig" }
local GUEST_SCREENS = {
    home = true,
    crew = true,
}

local ROLE_DEFINITIONS = {
    pilot = {
        label = "Pilot",
        focus = "Helm, Modi, Navigation",
        defaultCode = "1111",
        screens = {
            home = true,
            crew = true,
            helm = true,
            navigation = true,
            comms = true,
            log = true,
        },
        actions = {
            toggle_thrust = true,
            turn_port = true,
            turn_starboard = true,
            turn_stop = true,
            start_autopilot = true,
            stop_autopilot = true,
            cycle_autopilot_program = true,
            waypoint_prev = true,
            waypoint_next = true,
            edit_waypoint = true,
            set_home_port = true,
            mode_parking = true,
            mode_docking = true,
            mode_travel = true,
            mode_danger = true,
            mode_emergency = true,
            map_helm = true,
            map_thrust = true,
            map_port = true,
            map_starboard = true,
            send_message = true,
        },
    },
    engineer = {
        label = "Ingenieur",
        focus = "Maschinenraum, Reserve, Fabrik",
        defaultCode = "2222",
        screens = {
            home = true,
            crew = true,
            factory = true,
            settings = true,
            comms = true,
            log = true,
        },
        actions = {
            toggle_factory = true,
            toggle_reserve = true,
            cycle_factory_requirement = true,
            rename_ship = true,
            edit_symbol = true,
            cycle_palette = true,
            audio_prev = true,
            audio_next = true,
            play_audio_cue = true,
            test_speaker = true,
            map_fuel = true,
            map_factory_output = true,
            map_generator = true,
            map_emergency_stop = true,
            map_reserve = true,
            map_key_switch = true,
            set_role_code = true,
            set_pin = true,
            send_message = true,
        },
    },
    alarm = {
        label = "Alarmzentrale",
        focus = "Warnungen, Sirenen, Funk",
        defaultCode = "3333",
        screens = {
            home = true,
            crew = true,
            alarms = true,
            comms = true,
            log = true,
        },
        actions = {
            toggle_alarm = true,
            mode_danger = true,
            mode_emergency = true,
            map_alarm = true,
            map_enemy = true,
            map_overload = true,
            test_speaker = true,
            send_message = true,
        },
    },
    captain = {
        label = "Captain",
        focus = "Vollzugriff auf alle Bereiche",
        defaultCode = "4444",
        screens = {
            home = true,
            helm = true,
            factory = true,
            navigation = true,
            alarms = true,
            crew = true,
            comms = true,
            log = true,
            settings = true,
        },
        actions = {
            toggle_thrust = true,
            turn_port = true,
            turn_starboard = true,
            turn_stop = true,
            start_autopilot = true,
            stop_autopilot = true,
            cycle_autopilot_program = true,
            waypoint_prev = true,
            waypoint_next = true,
            edit_waypoint = true,
            set_home_port = true,
            mode_parking = true,
            mode_docking = true,
            mode_travel = true,
            mode_danger = true,
            mode_emergency = true,
            map_helm = true,
            map_thrust = true,
            map_port = true,
            map_starboard = true,
            toggle_factory = true,
            toggle_reserve = true,
            cycle_factory_requirement = true,
            rename_ship = true,
            edit_symbol = true,
            cycle_palette = true,
            audio_prev = true,
            audio_next = true,
            play_audio_cue = true,
            map_fuel = true,
            map_factory_output = true,
            map_generator = true,
            map_emergency_stop = true,
            map_reserve = true,
            map_key_switch = true,
            set_role_code = true,
            set_pin = true,
            toggle_alarm = true,
            map_alarm = true,
            map_enemy = true,
            map_overload = true,
            test_speaker = true,
            save_user = true,
            assign_selected_role = true,
            remove_selected_role = true,
            delete_user = true,
            send_message = true,
        },
    },
    co_captain = {
        label = "Co-Captain",
        focus = "Vollzugriff unter dem Gruender-Captain",
        defaultCode = "5555",
        screens = {
            home = true,
            helm = true,
            factory = true,
            navigation = true,
            alarms = true,
            crew = true,
            comms = true,
            log = true,
            settings = true,
        },
        actions = {
            toggle_thrust = true,
            turn_port = true,
            turn_starboard = true,
            turn_stop = true,
            start_autopilot = true,
            stop_autopilot = true,
            cycle_autopilot_program = true,
            waypoint_prev = true,
            waypoint_next = true,
            edit_waypoint = true,
            set_home_port = true,
            mode_parking = true,
            mode_docking = true,
            mode_travel = true,
            mode_danger = true,
            mode_emergency = true,
            map_helm = true,
            map_thrust = true,
            map_port = true,
            map_starboard = true,
            toggle_factory = true,
            toggle_reserve = true,
            cycle_factory_requirement = true,
            rename_ship = true,
            edit_symbol = true,
            cycle_palette = true,
            audio_prev = true,
            audio_next = true,
            play_audio_cue = true,
            map_fuel = true,
            map_factory_output = true,
            map_generator = true,
            map_emergency_stop = true,
            map_reserve = true,
            map_key_switch = true,
            set_pin = true,
            toggle_alarm = true,
            map_alarm = true,
            map_enemy = true,
            map_overload = true,
            test_speaker = true,
            save_user = true,
            assign_selected_role = true,
            remove_selected_role = true,
            delete_user = true,
            send_message = true,
        },
    },
}

local ALERT_DEFINITIONS = {
    fuel_low = {
        label = "Treibstoff niedrig",
        color = colors.yellow,
        critical = false,
    },
    drive_fault = {
        label = "Antrieb gestoert",
        color = colors.red,
        critical = true,
    },
    helm_disconnected = {
        label = "Helm getrennt",
        color = colors.red,
        critical = true,
    },
    workshop_overload = {
        label = "Werkstatt ueberlastet",
        color = colors.orange,
        critical = false,
    },
    enemy_contact = {
        label = "Feindkontakt",
        color = colors.red,
        critical = true,
    },
    emergency_stop = {
        label = "Not-Aus aktiv",
        color = colors.red,
        critical = true,
    },
}

local AUTOPILOT_ORDER = { "departure", "docking", "patrol" }
local AUTOPILOT_PROGRAMS = {
    departure = {
        label = "Abflugsequenz",
        steps = {
            { label = "Schub an", ticks = 10, thrust = true, heading = "Still", altitude = "Startlauf" },
            { label = "Steigflug 5s", ticks = 25, thrust = true, heading = "Still", altitude = "Steigflug" },
            { label = "Geradeaus", ticks = 15, thrust = true, heading = "Geradeaus", altitude = "Reiseflug" },
            { label = "Backbord 2s", ticks = 10, thrust = true, turnLeft = true, heading = "Backbord", altitude = "Kurswechsel" },
            { label = "Motor aus", ticks = 5, thrust = false, heading = "Still", altitude = "Stabil" },
        },
    },
    docking = {
        label = "Dockingkurs",
        steps = {
            { label = "Anflug bremsen", ticks = 10, thrust = false, heading = "Still", altitude = "Feinfahrt" },
            { label = "Backbord 2s", ticks = 10, thrust = false, turnLeft = true, heading = "Backbord", altitude = "Ausrichten" },
            { label = "Kurzanschub", ticks = 8, thrust = true, heading = "Geradeaus", altitude = "Docking" },
            { label = "Stillsetzen", ticks = 8, thrust = false, heading = "Still", altitude = "Docking" },
        },
    },
    patrol = {
        label = "Patrouille",
        steps = {
            { label = "Schub halten", ticks = 15, thrust = true, heading = "Geradeaus", altitude = "Patrouille" },
            { label = "Steuerbord 2s", ticks = 10, thrust = true, turnRight = true, heading = "Steuerbord", altitude = "Patrouille" },
            { label = "Geradeaus", ticks = 15, thrust = true, heading = "Geradeaus", altitude = "Patrouille" },
            { label = "Backbord 2s", ticks = 10, thrust = true, turnLeft = true, heading = "Backbord", altitude = "Patrouille" },
            { label = "Stabilisieren", ticks = 10, thrust = false, heading = "Still", altitude = "Halteflug" },
        },
    },
}

local function loadSerialized(path)
    if not fs.exists(path) then
        return nil
    end

    local handle = fs.open(path, "r")
    if not handle then
        return nil
    end

    local raw = handle.readAll()
    handle.close()
    local decoded = textutils.unserialize(raw)
    if type(decoded) ~= "table" then
        return nil
    end

    return decoded
end

local function saveSerialized(path, value)
    fs.makeDir("/smos")
    local handle = fs.open(path, "w")
    if not handle then
        return false
    end

    handle.write(textutils.serialize(value))
    handle.close()
    return true
end

local function loadConfig()
    return loadSerialized(CONFIG_PATH) or {}
end

local function loadLog()
    local entries = loadSerialized(LOG_PATH)
    if type(entries) ~= "table" then
        return {}
    end

    return entries
end

local function nowStamp()
    return textutils.formatTime(os.time(), true) .. " | Tag " .. tostring(os.day())
end

local function normalizeShipName(value)
    local normalized = tostring(value or "")
    normalized = normalized:gsub("^%s+", "")
    normalized = normalized:gsub("%s+$", "")
    normalized = normalized:gsub("%s+", " ")
    return string.lower(normalized)
end

local function trimText(value)
    local normalized = tostring(value or "")
    normalized = normalized:gsub("^%s+", "")
    normalized = normalized:gsub("%s+$", "")
    normalized = normalized:gsub("%s+", " ")
    return normalized
end

local function normalizeUserKey(value)
    return string.lower(trimText(value))
end

local function defaultWaypoints(homePort)
    return {
        {
            name = homePort or "Sora Haven",
            distance = "0 km",
            direction = "Dock",
        },
        {
            name = "Wolkenroute",
            distance = "12 km",
            direction = "Nordost",
        },
        {
            name = "Werkinsel",
            distance = "4 km",
            direction = "Sued",
        },
    }
end

local function normalizeAssignments(raw)
    local assignments = {}
    for key, value in pairs(ASSIGNMENT_DEFAULTS) do
        assignments[key] = value
    end

    if type(raw) == "table" then
        for key, value in pairs(raw) do
            assignments[key] = value
        end
    end

    return assignments
end

local function normalizeWaypoints(raw, homePort)
    local normalized = {}
    if type(raw) == "table" then
        for _, waypoint in ipairs(raw) do
            if type(waypoint) == "table" then
                normalized[#normalized + 1] = {
                    name = waypoint.name or "Wegpunkt",
                    distance = waypoint.distance or "Unbekannt",
                    direction = waypoint.direction or "Kurs offen",
                }
            end
        end
    end

    if #normalized == 0 then
        normalized = defaultWaypoints(homePort)
    end

    return normalized
end

local function normalizeNavigation(raw, homePort)
    raw = raw or {}
    local navigation = {
        homePort = raw.homePort or homePort or "Sora Haven",
        activeIndex = tonumber(raw.activeIndex) or 1,
        waypoints = normalizeWaypoints(raw.waypoints, raw.homePort or homePort),
    }

    if navigation.activeIndex < 1 or navigation.activeIndex > #navigation.waypoints then
        navigation.activeIndex = 1
    end

    return navigation
end

local function normalizeUserRoles(raw)
    local roles = {}
    if type(raw) == "table" then
        for roleName, enabled in pairs(raw) do
            if enabled and ROLE_DEFINITIONS[roleName] then
                roles[roleName] = true
            end
        end
    elseif type(raw) == "string" and ROLE_DEFINITIONS[raw] then
        roles[raw] = true
    end

    return roles
end

local function normalizeCrewUsers(raw)
    local users = {}
    if type(raw) ~= "table" then
        return users
    end

    for key, rawUser in pairs(raw) do
        if type(rawUser) == "table" then
            local displayName = trimText(rawUser.name or key)
            local userKey = normalizeUserKey(displayName)
            if userKey ~= "" then
                users[userKey] = {
                    name = displayName,
                    password = tostring(rawUser.password or ""),
                    roles = normalizeUserRoles(rawUser.roles or rawUser.role),
                }
            end
        end
    end

    return users
end

local function normalizeFounderUser(raw, users)
    local founderKey = normalizeUserKey(raw)
    if founderKey ~= "" and users[founderKey] and users[founderKey].roles and users[founderKey].roles.captain then
        return founderKey
    end

    local firstKey = nil
    for key, user in pairs(users or {}) do
        if user.roles and user.roles.captain then
            if not firstKey or tostring(user.name or key) < tostring(users[firstKey].name or firstKey) then
                firstKey = key
            end
        end
    end

    return firstKey
end

local function normalizeCaptainHierarchy(users, founderKey)
    local changed = false
    if not founderKey or not users[founderKey] then
        return changed
    end

    for key, user in pairs(users) do
        user.roles = user.roles or {}
        if key == founderKey then
            if not user.roles.captain then
                user.roles.captain = true
                changed = true
            end
        elseif user.roles.captain then
            user.roles.captain = nil
            user.roles.co_captain = true
            changed = true
        end
    end

    return changed
end

local function userTableHasRole(users, roleName)
    for _, user in pairs(users or {}) do
        if type(user.roles) == "table" and user.roles[roleName] then
            return true
        end
    end

    return false
end

local function findCrewUser(state, username)
    local userKey = normalizeUserKey(username)
    if userKey == "" then
        return nil, nil
    end

    return userKey, state.crew.users[userKey]
end

local function anyCrewUserHasRole(state, roleName)
    return userTableHasRole(state.crew and state.crew.users or {}, roleName)
end

local function userHasLeadership(user)
    return type(user) == "table"
        and type(user.roles) == "table"
        and (user.roles.captain == true or user.roles.co_captain == true)
end

local function currentCrewUser(state)
    if not state.crew or not state.crew.session or not state.crew.session.username then
        return nil, nil
    end

    local userKey = state.crew.session.username
    return userKey, state.crew.users[userKey]
end

local function roleLabelsForUser(user)
    local labels = {}
    for _, roleName in ipairs({ "captain", "co_captain", "pilot", "engineer", "alarm" }) do
        if user.roles and user.roles[roleName] and ROLE_DEFINITIONS[roleName] then
            labels[#labels + 1] = ROLE_DEFINITIONS[roleName].label
        end
    end

    if #labels == 0 then
        return "keine Rolle"
    end

    return table.concat(labels, ", ")
end

local function sortedCrewUserKeys(state)
    local keys = {}
    for key in pairs(state.crew.users or {}) do
        keys[#keys + 1] = key
    end

    table.sort(keys, function(left, right)
        local leftUser = state.crew.users[left]
        local rightUser = state.crew.users[right]
        local leftWeight = left == state.crew.founderUser and 0 or (leftUser.roles and leftUser.roles.co_captain and 1 or 2)
        local rightWeight = right == state.crew.founderUser and 0 or (rightUser.roles and rightUser.roles.co_captain and 1 or 2)
        if leftWeight ~= rightWeight then
            return leftWeight < rightWeight
        end
        return tostring(leftUser.name or left) < tostring(rightUser.name or right)
    end)

    return keys
end

local function ensureSelectedCrewUser(state)
    local keys = sortedCrewUserKeys(state)
    if #keys == 0 then
        state.crew.selectedUser = nil
        return keys, nil
    end

    local selectedKey = state.crew.selectedUser
    if not selectedKey or not state.crew.users[selectedKey] then
        selectedKey = keys[1]
        state.crew.selectedUser = selectedKey
    end

    for index, key in ipairs(keys) do
        if key == selectedKey then
            return keys, index
        end
    end

    state.crew.selectedUser = keys[1]
    return keys, 1
end

local function findMonitor()
    if not peripheral then
        return nil, nil
    end

    if peripheral.isPresent and peripheral.getType and peripheral.wrap then
        for _, side in ipairs(ASSIGNABLE_SIDES) do
            if side ~= "none" and peripheral.isPresent(side) and peripheral.getType(side) == "monitor" then
                return peripheral.wrap(side), side
            end
        end
    end

    if peripheral.find then
        local monitor = peripheral.find("monitor")
        if monitor and peripheral.getName then
            local ok, name = pcall(peripheral.getName, monitor)
            if ok then
                return monitor, name
            end
        end
        return monitor, nil
    end

    return nil, nil
end

local function findSpeaker()
    if not peripheral then
        return nil, nil
    end

    if peripheral.isPresent and peripheral.getType and peripheral.wrap then
        for _, side in ipairs(ASSIGNABLE_SIDES) do
            if side ~= "none" and peripheral.isPresent(side) and peripheral.getType(side) == "speaker" then
                return peripheral.wrap(side), side
            end
        end
    end

    if peripheral.find then
        local speaker = peripheral.find("speaker")
        if speaker and peripheral.getName then
            local ok, name = pcall(peripheral.getName, speaker)
            if ok then
                return speaker, name
            end
        end
        return speaker, nil
    end

    return nil, nil
end

local function speakerInvoke(state, method, ...)
    if not state or not state.speaker then
        return false, "Kein Speaker"
    end

    if state.speakerName and peripheral and peripheral.call then
        return pcall(peripheral.call, state.speakerName, method, ...)
    end

    local member = state.speaker[method]
    if type(member) ~= "function" then
        return false, "Methode fehlt"
    end

    return pcall(member, ...)
end

local function playAlarmTone(state)
    if not state.speaker then
        return
    end

    local alarmCue = { label = "Alarm" }
    local sound = alarmSounds[state.alarmPulse]
    local played = false
    if sound then
        local ok, result = speakerInvoke(state, "playSound", sound.name, 3, sound.pitch)
        played = ok and result ~= false
        if played then
            recordAudioResult(state, alarmCue, true, "Sound", "Alarmton spielt")
        end
    end

    if not played then
        local note = alarmNotes[state.alarmPulse]
        if note then
            local ok, result = speakerInvoke(state, "playNote", note.instrument, 3, note.pitch)
            played = ok and result ~= false
            if played then
                recordAudioResult(state, alarmCue, true, "Note", "Alarmton spielt")
            end
        end
    end

    if not played then
        recordAudioResult(state, alarmCue, false, "Alarm", "Alarmton blockiert oder stumm")
    end

    state.alarmPulse = state.alarmPulse + 1
    if state.alarmPulse > #alarmNotes then
        state.alarmPulse = 1
    end
end

local function refreshAudioCatalog(state)
    local cues = {}
    for _, cue in ipairs(DEFAULT_AUDIO_CUES) do
        cues[#cues + 1] = {
            key = cue.key,
            label = cue.label,
            kind = cue.kind,
            sound = cue.sound,
            volume = cue.volume,
            pitch = cue.pitch,
        }
    end

    if fs and fs.makeDir and fs.list then
        fs.makeDir(AUDIO_DIR)
        local customFiles = {}
        for _, fileName in ipairs(fs.list(AUDIO_DIR)) do
            if tostring(fileName):lower():match("%.dfpwm$") then
                customFiles[#customFiles + 1] = fileName
            end
        end

        table.sort(customFiles)
        for _, fileName in ipairs(customFiles) do
            cues[#cues + 1] = {
                key = "dfpwm:" .. string.lower(fileName),
                label = fileName:gsub("%.dfpwm$", ""),
                kind = "dfpwm",
                path = AUDIO_DIR .. "/" .. fileName,
            }
        end
    end

    state.audio.cues = cues
    if #cues == 0 then
        state.audio.selectedCue = nil
        return
    end

    for _, cue in ipairs(cues) do
        if cue.key == state.audio.selectedCue then
            return
        end
    end

    state.audio.selectedCue = cues[1].key
end

local function findAudioCue(state, cueKey)
    for _, cue in ipairs(state.audio.cues or {}) do
        if cue.key == cueKey then
            return cue
        end
    end

    return nil
end

local function recordAudioResult(state, cue, ok, method, message)
    state.audio.lastCue = cue and cue.label or "-"
    state.audio.lastResult = message or (ok and "Audio gespielt" or "Audio fehlgeschlagen")
    state.audio.lastMethod = method or "-"
    state.audio.lastTime = nowStamp()
end

local function playDfpwmCue(state, cue)
    if not state.speaker then
        return false, "DFPWM nicht verfuegbar"
    end

    if not fs or not fs.exists or not fs.exists(cue.path) then
        return false, "Datei fehlt"
    end

    local okRequire, dfpwm = pcall(require, "cc.audio.dfpwm")
    if not okRequire or not dfpwm or not dfpwm.make_decoder then
        return false, "cc.audio.dfpwm fehlt"
    end

    local handle = fs.open(cue.path, "rb") or fs.open(cue.path, "r")
    if not handle then
        return false, "Audio kann nicht geoeffnet werden"
    end

    local decoder = dfpwm.make_decoder()
    while true do
        local chunk = handle.read(16 * 1024)
        if not chunk then
            break
        end

        local buffer = decoder(chunk)
        while true do
            local ok, result = speakerInvoke(state, "playAudio", buffer, 1.0)
            if ok and result ~= false then
                break
            end
            os.pullEvent("speaker_audio_empty")
        end
    end

    handle.close()
    return true, "DFPWM"
end

local function playAudioCue(state, cue)
    if not state.speaker then
        return false, "Kein Speaker", "-"
    end

    if cue.kind == "sound" and state.speaker.playSound then
        local ok, result = pcall(state.speaker.playSound, cue.sound, cue.volume or 3, cue.pitch or 1)
        if ok and result ~= false then
            return true, "Sound", cue.label .. " gespielt"
        end
        return false, "Sound", cue.label .. " blockiert"
    end

    if cue.kind == "dfpwm" then
        local ok, methodOrReason = playDfpwmCue(state, cue)
        if ok then
            return true, methodOrReason, cue.label .. " gespielt"
        end
        return false, "DFPWM", methodOrReason
    end

    return false, "-", "Cue nicht abspielbar"
end

local function sideInput(side)
    return side and side ~= "none" and redstone.getInput(side) or false
end

local function setOutput(side, enabled)
    if side and side ~= "none" then
        redstone.setOutput(side, enabled)
    end
end

local function roundCoordinate(value)
    if value >= 0 then
        return math.floor(value + 0.5)
    end

    return math.ceil(value - 0.5)
end

local function refreshGpsPosition(state)
    if not gps or type(gps.locate) ~= "function" then
        state.position.online = false
        state.position.status = "Kein GPS API"
        return
    end

    local ok, x, y, z = pcall(gps.locate, 0.05, false)
    if ok and x and y and z then
        state.position.online = true
        state.position.x = roundCoordinate(x)
        state.position.y = roundCoordinate(y)
        state.position.z = roundCoordinate(z)
        state.position.status = "Online"
        return
    end

    state.position.online = false
    state.position.status = "GPS offline"
end

local function trimInbox(inbox)
    while #inbox > 12 do
        table.remove(inbox)
    end
end

local function deviceCode(client)
    if client == "tablet" then
        return "T"
    end

    return "BC"
end

local function peerLabel(peerId, client)
    if not peerId then
        return "Unbekannt"
    end

    return "ID " .. tostring(peerId) .. " " .. deviceCode(client)
end

local function inboxAuthor(entry)
    local author = trimText(entry.author or "")
    if author ~= "" then
        return author
    end

    if ROLE_DEFINITIONS[entry.role or ""] then
        return ROLE_DEFINITIONS[entry.role].label
    end

    return "Extern"
end

local function pushInboxEntry(state, entry)
    entry.time = entry.time or nowStamp()
    entry.device = entry.device or deviceCode(entry.client)
    entry.peer = entry.peer or peerLabel(entry.peerId, entry.client)
    entry.author = inboxAuthor(entry)
    table.insert(state.comms.inbox, 1, entry)
    trimInbox(state.comms.inbox)
end

local function trimLog(entries)
    while #entries > 60 do
        table.remove(entries)
    end
end

local function stopMotion(state)
    state.outputs.thrust = false
    state.outputs.turnLeft = false
    state.outputs.turnRight = false
    state.helm.heading = "Still"
end

local function roleAllowsAction(role, action)
    local roleInfo = ROLE_DEFINITIONS[role or ""]
    if not roleInfo then
        return false
    end

    return roleInfo.actions and roleInfo.actions[action] == true
end

local function actionHasRoleRequirement(action)
    for _, roleInfo in pairs(ROLE_DEFINITIONS) do
        if roleInfo.actions and roleInfo.actions[action] == true then
            return true
        end
    end

    return false
end

local function currentWaypoint(state)
    local navigation = state.navigation
    if not navigation.waypoints[navigation.activeIndex] then
        navigation.activeIndex = 1
    end

    return navigation.waypoints[navigation.activeIndex]
end

local function saveConfig(state)
    return saveSerialized(CONFIG_PATH, {
        shipName = state.shipName,
        assignments = state.assignments,
        preferMonitor = state.preferMonitor,
        palette = state.palette,
        customSymbol = state.customSymbol,
        mode = state.mode,
        checklistFactoryMode = state.checklist.desiredFactoryMode,
        navigation = state.navigation,
        activeRole = state.crew.selectedRole,
        crewUsers = state.crew.users,
        founderUser = state.crew.founderUser,
        selectedCrewUser = state.crew.selectedUser,
        selectedAudioCue = state.audio.selectedCue,
        pin = state.security.pin,
        linkedTabletId = state.comms.linkedTabletId,
        autopilotProgram = state.autopilot.selectedProgram,
    })
end

local function saveLog(state)
    return saveSerialized(LOG_PATH, state.logEntries)
end

function runtime.log(state, message, category)
    local prefix = category and ("[" .. category .. "] ") or ""
    table.insert(state.logEntries, 1, nowStamp() .. " " .. prefix .. message)
    trimLog(state.logEntries)
    saveLog(state)
end

function runtime.linkedTabletLabel(state)
    if state.comms.linkedTabletId then
        return peerLabel(state.comms.linkedTabletId, "tablet")
    end

    return "Nicht gekoppelt"
end

function runtime.setNotice(state, text, ticks)
    state.notice = text
    state.noticeTicks = ticks or 20
end

function runtime.newState(theme)
    local config = loadConfig()
    local monitor, monitorName = findMonitor()
    local speaker, speakerName = findSpeaker()
    local crewUsers = normalizeCrewUsers(config.crewUsers)
    local founderUser = normalizeFounderUser(config.founderUser, crewUsers)
    local hierarchyChanged = normalizeCaptainHierarchy(crewUsers, founderUser)
    local selectedRole = config.activeRole or (userTableHasRole(crewUsers, "captain") and "pilot" or "captain")
    local storedFounderUser = normalizeUserKey(config.founderUser or "")
    local selectedCrewUser = normalizeUserKey(config.selectedCrewUser or "")

    local state = {
        theme = theme,
        shipName = config.shipName or theme.shipName,
        palette = config.palette or "crimson",
        customSymbol = type(config.customSymbol) == "table" and config.customSymbol or DEFAULT_SYMBOL,
        screenOrder = SCREEN_ORDER,
        activeScreen = "home",
        selectedIndex = 1,
        speaker = speaker,
        speakerName = speakerName,
        monitor = monitor,
        monitorName = monitorName,
        preferMonitor = config.preferMonitor ~= false,
        manualAlarm = false,
        modeAlarm = false,
        systemAlarm = false,
        signalOnline = false,
        alarmPulse = 1,
        alarmFlash = false,
        touchTargets = {},
        assignments = normalizeAssignments(config.assignments),
        outputs = {
            thrust = false,
            turnLeft = false,
            turnRight = false,
            factoryEnabled = false,
            reserveMode = false,
        },
        helm = {
            thrust = "Leerlauf",
            heading = "Still",
            altitude = "Noch manuell",
            failsafe = "Aktiv",
        },
        factory = {
            lineA = "Bereit",
            fuel = "Tank pruefen",
            storage = "Normal",
            mode = "Standby",
        },
        engine = {
            generatorOnline = false,
            productionActive = false,
            emergencyStop = false,
            reserveMode = false,
            overload = false,
            enemyContact = false,
            fuelLow = false,
            driveFault = false,
        },
        alerts = {
            ordered = {},
            active = {},
        },
        checklist = {
            desiredFactoryMode = config.checklistFactoryMode or "Standby",
            items = {},
            ready = false,
        },
        navigation = normalizeNavigation(config.navigation, config.shipName or theme.shipName),
        crew = {
            selectedRole = ROLE_DEFINITIONS[selectedRole] and selectedRole or "captain",
            users = crewUsers,
            founderUser = founderUser,
            selectedUser = selectedCrewUser ~= "" and selectedCrewUser or nil,
            session = {
                role = nil,
                operator = "Gast",
                username = nil,
            },
        },
        security = {
            pin = tostring(config.pin or "2468"),
            unlockedTicks = 0,
            keyOnline = false,
        },
        comms = {
            radioOnline = false,
            modemSides = {},
            inbox = {},
            lastPeer = "Kein Kontakt",
            lastContact = "Nie",
            linkedTabletId = config.linkedTabletId,
        },
        autopilot = {
            selectedProgram = config.autopilotProgram or AUTOPILOT_ORDER[1],
            running = false,
            stepIndex = 0,
            ticksRemaining = 0,
            currentStepLabel = "Bereit",
            lastRun = "Noch keiner",
        },
        audio = {
            selectedCue = config.selectedAudioCue or "builtin:bridge_bell",
            cues = {},
            lastCue = "-",
            lastResult = "Noch kein Audio-Test",
            lastMethod = "-",
            lastTime = "Nie",
        },
        debug = {
            terminalMirrorActive = false,
        },
        mode = config.mode or "parking",
        position = {
            online = false,
            x = nil,
            y = nil,
            z = nil,
            status = "Suche GPS",
        },
        tickCount = 0,
        notice = "",
        noticeTicks = 0,
        logEntries = loadLog(),
        _lastAlertMap = {},
        _lastEmergencyStop = false,
    }

    ensureSelectedCrewUser(state)
    refreshAudioCatalog(state)
    runtime.applyTheme(state)
    runtime.setMode(state, state.mode, true)
    runtime.setScreen(state, config.activeScreen or "home")
    if hierarchyChanged or storedFounderUser ~= (founderUser or "") then
        saveConfig(state)
    end
    return state
end

function runtime.refreshPeripherals(state)
    state.speaker, state.speakerName = findSpeaker()
    state.monitor, state.monitorName = findMonitor()

    local modemSides = {}
    if peripheral and rednet and rednet.open and peripheral.isPresent and peripheral.getType then
        for _, side in ipairs(ASSIGNABLE_SIDES) do
            if side ~= "none" and peripheral.isPresent(side) and peripheral.getType(side) == "modem" then
                modemSides[#modemSides + 1] = side
                if not rednet.isOpen(side) then
                    rednet.open(side)
                end
            end
        end
    end

    state.comms.modemSides = modemSides
    state.comms.radioOnline = #modemSides > 0
end

function runtime.save(state)
    saveConfig(state)
end

function runtime.setShipName(state, shipName)
    if shipName and shipName ~= "" then
        state.shipName = shipName
        saveConfig(state)
        runtime.log(state, "Schiffsname gesetzt auf " .. shipName, "SYS")
    end
end

function runtime.setCustomSymbol(state, symbolLines)
    if type(symbolLines) == "table" and #symbolLines > 0 then
        state.customSymbol = symbolLines
        saveConfig(state)
        runtime.log(state, "Schiffssymbol aktualisiert", "SYS")
    end
end

function runtime.paletteName(state)
    return state.palette or "crimson"
end

function runtime.applyTheme(state)
    local preset = PALETTES[state.palette] or PALETTES.crimson
    for key, value in pairs(preset) do
        state.theme[key] = value
    end
end

function runtime.cyclePalette(state)
    local nextIndex = 1
    for index, name in ipairs(PALETTE_ORDER) do
        if name == state.palette then
            nextIndex = index + 1
            break
        end
    end

    if nextIndex > #PALETTE_ORDER then
        nextIndex = 1
    end

    state.palette = PALETTE_ORDER[nextIndex]
    runtime.applyTheme(state)
    saveConfig(state)
    runtime.log(state, "Palette gewechselt auf " .. state.palette, "SYS")
    return state.palette
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
    runtime.log(state, assignmentKey .. " -> " .. state.assignments[assignmentKey], "I/O")
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

function runtime.canAccessScreen(state, screenName, context)
    context = context or {}
    if context.force then
        return true
    end

    if GUEST_SCREENS[screenName] then
        return true
    end

    local role = context.role or (state.crew.session and state.crew.session.role)
    local roleInfo = ROLE_DEFINITIONS[role or ""]
    return roleInfo and roleInfo.screens and roleInfo.screens[screenName] == true or false
end

function runtime.setScreen(state, screenName, context)
    for index, name in ipairs(state.screenOrder) do
        if name == screenName then
            if not runtime.canAccessScreen(state, screenName, context) then
                runtime.setNotice(state, "Bereich gesperrt: Login noetig", 24)
                return false
            end
            state.activeScreen = screenName
            state.selectedIndex = index
            if screenName == "settings" then
                refreshAudioCatalog(state)
            end
            return true
        end
    end

    return false
end

function runtime.nextScreen(state)
    local startIndex = runtime.screenIndex(state)
    local nextIndex = startIndex
    repeat
        nextIndex = nextIndex + 1
        if nextIndex > #state.screenOrder then
            nextIndex = 1
        end
        if runtime.canAccessScreen(state, state.screenOrder[nextIndex]) then
            runtime.setScreen(state, state.screenOrder[nextIndex], { force = true })
            return
        end
    until nextIndex == startIndex
end

function runtime.previousScreen(state)
    local startIndex = runtime.screenIndex(state)
    local previousIndex = startIndex
    repeat
        previousIndex = previousIndex - 1
        if previousIndex < 1 then
            previousIndex = #state.screenOrder
        end
        if runtime.canAccessScreen(state, state.screenOrder[previousIndex]) then
            runtime.setScreen(state, state.screenOrder[previousIndex], { force = true })
            return
        end
    until previousIndex == startIndex
end

function runtime.modeLabel(state)
    local definition = MODE_DEFINITIONS[state.mode] or MODE_DEFINITIONS.parking
    return definition.label
end

function runtime.modeDescription(state)
    local definition = MODE_DEFINITIONS[state.mode] or MODE_DEFINITIONS.parking
    return definition.description
end

function runtime.modeColor(state)
    local definition = MODE_DEFINITIONS[state.mode] or MODE_DEFINITIONS.parking
    return definition.color
end

function runtime.setMode(state, modeName, silent)
    local definition = MODE_DEFINITIONS[modeName]
    if not definition then
        return false
    end

    state.mode = modeName
    state.modeAlarm = definition.modeAlarm
    state.outputs.reserveMode = definition.reserveMode
    state.engine.reserveMode = definition.reserveMode
    state.outputs.factoryEnabled = definition.factoryEnabled
    if definition.stopMotion then
        stopMotion(state)
    end
    if modeName == "emergency" then
        runtime.stopAutopilot(state, "Notfallmodus")
    end
    saveConfig(state)

    if not silent then
        runtime.log(state, "Flugmodus -> " .. definition.label, "MODE")
        runtime.setNotice(state, "Modus: " .. definition.label, 30)
    end

    return true
end

function runtime.cycleFactoryRequirement(state)
    local current = state.checklist.desiredFactoryMode or CHECKLIST_FACTORY_ORDER[1]
    local nextIndex = 1
    for index, value in ipairs(CHECKLIST_FACTORY_ORDER) do
        if value == current then
            nextIndex = index + 1
            break
        end
    end

    if nextIndex > #CHECKLIST_FACTORY_ORDER then
        nextIndex = 1
    end

    state.checklist.desiredFactoryMode = CHECKLIST_FACTORY_ORDER[nextIndex]
    saveConfig(state)
    runtime.log(state, "Checklistenmodus Fabrik -> " .. state.checklist.desiredFactoryMode, "OPS")
    return state.checklist.desiredFactoryMode
end

function runtime.describeFactoryRequirement(state)
    return state.checklist.desiredFactoryMode or "Standby"
end

function runtime.roleLabel(state)
    local info = ROLE_DEFINITIONS[state.crew.session.role or ""]
    if info then
        return info.label
    end

    return "Gast"
end

function runtime.roleFocus(state)
    local info = ROLE_DEFINITIONS[state.crew.session.role or ""]
    if info then
        return info.focus
    end

    return "Nur Home und Crew"
end

function runtime.selectedRoleLabel(state)
    local info = ROLE_DEFINITIONS[state.crew.selectedRole or ""] or ROLE_DEFINITIONS.pilot
    return info.label
end

function runtime.selectedRoleFocus(state)
    local info = ROLE_DEFINITIONS[state.crew.selectedRole or ""] or ROLE_DEFINITIONS.pilot
    return info.focus
end

function runtime.operatorLabel(state)
    return state.crew.session.operator or "Gast"
end

function runtime.currentUsername(state)
    local userKey = state.crew.session.username
    if userKey and state.crew.users[userKey] then
        return state.crew.users[userKey].name
    end

    return "-"
end

function runtime.currentPositionLabel(state)
    local position = state.position or {}
    if position.online and position.x and position.y and position.z then
        return "X " .. tostring(position.x) .. " | Y " .. tostring(position.y) .. " | Z " .. tostring(position.z), state.theme.ok
    end

    return position.status or "GPS offline", state.theme.muted
end

function runtime.headerPositionLabel(state)
    local position = state.position or {}
    if position.online and position.x and position.y and position.z then
        return "Pos " .. tostring(position.x) .. " " .. tostring(position.y) .. " " .. tostring(position.z), state.theme.ok
    end

    return "Pos GPS off", state.theme.muted
end

function runtime.loginStatus(state)
    if state.crew.session.role then
        return "Eingeloggt", state.theme.ok
    end

    if not anyCrewUserHasRole(state, "captain") then
        return "Captain einrichten", state.theme.warning
    end

    return "Gastmodus", state.theme.warning
end

function runtime.selectRole(state, roleName)
    if ROLE_DEFINITIONS[roleName] then
        state.crew.selectedRole = roleName
        saveConfig(state)
        runtime.setNotice(state, "Auswahl: " .. ROLE_DEFINITIONS[roleName].label, 18)
        return true
    end

    return false
end

function runtime.selectedCrewUser(state)
    local keys, index = ensureSelectedCrewUser(state)
    if not index then
        return nil, nil
    end

    local key = keys[index]
    return key, state.crew.users[key]
end

function runtime.selectedCrewUserName(state)
    local _, user = runtime.selectedCrewUser(state)
    if user then
        return user.name
    end

    return "Kein Crew-Konto"
end

function runtime.selectedCrewUserRoles(state)
    local _, user = runtime.selectedCrewUser(state)
    if user then
        return roleLabelsForUser(user)
    end

    return "Keine Auswahl"
end

function runtime.selectCrewUser(state, username)
    local userKey = normalizeUserKey(username)
    if userKey == "" or not state.crew.users[userKey] then
        return false
    end

    state.crew.selectedUser = userKey
    runtime.setNotice(state, "Crew-Auswahl: " .. state.crew.users[userKey].name, 18)
    saveConfig(state)
    return true
end

function runtime.cycleCrewUserSelection(state, delta)
    local keys, index = ensureSelectedCrewUser(state)
    if not index then
        runtime.setNotice(state, "Keine Crew-Konten vorhanden", 22)
        return false
    end

    local nextIndex = index + (delta or 1)
    if nextIndex > #keys then
        nextIndex = 1
    elseif nextIndex < 1 then
        nextIndex = #keys
    end

    state.crew.selectedUser = keys[nextIndex]
    runtime.setNotice(state, "Crew-Auswahl: " .. state.crew.users[state.crew.selectedUser].name, 18)
    saveConfig(state)
    return true
end

function runtime.crewListEntries(state, maxRows)
    local rows = {}
    local keys, selectedIndex = ensureSelectedCrewUser(state)
    local rowCount = math.max(1, maxRows or 1)

    if not selectedIndex then
        return rows
    end

    local startIndex = selectedIndex - math.floor(rowCount / 2)
    if startIndex < 1 then
        startIndex = 1
    end
    if startIndex > math.max(1, #keys - rowCount + 1) then
        startIndex = math.max(1, #keys - rowCount + 1)
    end

    for index = startIndex, math.min(#keys, startIndex + rowCount - 1) do
        local key = keys[index]
        local user = state.crew.users[key]
        rows[#rows + 1] = {
            key = key,
            name = user.name,
            roles = roleLabelsForUser(user),
            founder = key == state.crew.founderUser,
            selected = key == state.crew.selectedUser,
        }
    end

    return rows
end

function runtime.hasCaptain(state)
    return anyCrewUserHasRole(state, "captain")
end

function runtime.canManageCrew(state)
    local role = state.crew.session and state.crew.session.role
    return role == "captain" or role == "co_captain"
end

function runtime.currentUserIsFounder(state)
    local userKey = state.crew.session and state.crew.session.username or nil
    return userKey ~= nil and userKey == state.crew.founderUser
end

function runtime.loginRole(state, roleName, username, password)
    local definition = ROLE_DEFINITIONS[roleName]
    local displayName = trimText(username)
    local secret = tostring(password or "")
    if not definition then
        return false, "Unbekannte Rolle"
    end

    if displayName == "" then
        runtime.setNotice(state, "Benutzername fehlt", 24)
        return false, "Benutzername fehlt"
    end

    if secret == "" then
        runtime.setNotice(state, "Passwort fehlt", 24)
        return false, "Passwort fehlt"
    end

    local userKey, user = findCrewUser(state, displayName)

    if roleName == "captain" and not anyCrewUserHasRole(state, "captain") then
        if user and tostring(user.password or "") ~= secret then
            runtime.log(state, "Captain-Bootstrap fuer " .. displayName .. " fehlgeschlagen", "SEC")
            runtime.setNotice(state, "Passwort fuer Captain-Konto falsch", 24)
            return false, "Passwort falsch"
        end

        if not user then
            user = {
                name = displayName,
                password = secret,
                roles = {},
            }
            state.crew.users[userKey] = user
        else
            user.name = displayName
            user.password = secret
        end

        user.roles.captain = true
        state.crew.founderUser = userKey
        state.crew.selectedUser = userKey
        saveConfig(state)
        runtime.log(state, "Erster Captain eingerichtet: " .. displayName, "CREW")
        runtime.setNotice(state, "Captain-Profil eingerichtet", 28)
    end

    if not user then
        runtime.log(state, "Login fehlgeschlagen fuer unbekannten Benutzer " .. displayName, "SEC")
        runtime.setNotice(state, "Benutzer unbekannt", 24)
        return false, "Benutzer unbekannt"
    end

    if tostring(user.password or "") ~= secret then
        runtime.log(state, "Fehlerhafter Login fuer " .. displayName, "SEC")
        runtime.setNotice(state, "Passwort falsch", 24)
        return false, "Passwort falsch"
    end

    if not (user.roles and user.roles[roleName]) then
        runtime.log(state, displayName .. " hat keine Freigabe fuer " .. definition.label, "SEC")
        runtime.setNotice(state, "Rolle nicht zugewiesen", 24)
        return false, "Rolle nicht zugewiesen"
    end

    state.crew.selectedRole = roleName
    state.crew.session.role = roleName
    state.crew.session.operator = user.name ~= "" and user.name or definition.label
    state.crew.session.username = userKey
    state.crew.selectedUser = userKey
    runtime.log(state, state.crew.session.operator .. " eingeloggt als " .. definition.label, "CREW")
    runtime.setNotice(state, "Login: " .. definition.label, 24)
    return true
end

function runtime.logoutRole(state)
    local previousRole = runtime.roleLabel(state)
    local previousOperator = runtime.operatorLabel(state)
    state.crew.session.role = nil
    state.crew.session.operator = "Gast"
    state.crew.session.username = nil
    runtime.log(state, previousOperator .. " ausgeloggt aus " .. previousRole, "CREW")
    runtime.setNotice(state, "Logout aktiv", 20)
    if not runtime.canAccessScreen(state, state.activeScreen) then
        runtime.setScreen(state, "home", { force = true })
    end
end

function runtime.saveCrewUser(state, username, password)
    local displayName = trimText(username)
    local secret = tostring(password or "")
    local userKey = normalizeUserKey(displayName)
    local actorKey = state.crew.session and state.crew.session.username or nil

    if displayName == "" then
        return false, "Benutzername fehlt"
    end

    if secret == "" then
        return false, "Passwort fehlt"
    end

    local existing = state.crew.users[userKey]
    local created = false
    if not existing then
        existing = {
            name = displayName,
            password = secret,
            roles = {},
        }
        state.crew.users[userKey] = existing
        created = true
    else
        if actorKey ~= state.crew.founderUser and userHasLeadership(existing) and actorKey ~= userKey then
            return false, "Nur Gruender-Captain darf Leitungs-Konten aendern"
        end
        existing.name = displayName
        existing.password = secret
    end

    state.crew.selectedUser = userKey
    saveConfig(state)
    runtime.log(state, created and ("Crew-Konto erstellt: " .. displayName) or ("Crew-Passwort aktualisiert: " .. displayName), "CREW")
    runtime.setNotice(state, created and "Crew-Konto erstellt" or "Passwort aktualisiert", 24)
    return true, created and "created" or "updated"
end

function runtime.assignRoleToUser(state, username, roleName)
    local definition = ROLE_DEFINITIONS[roleName]
    local actorKey = state.crew.session and state.crew.session.username or nil
    local targetKey, user = findCrewUser(state, username)
    if not definition then
        return false, "Unbekannte Rolle"
    end

    if not user then
        return false, "Benutzer unbekannt"
    end

    if roleName == "captain" then
        if actorKey ~= state.crew.founderUser then
            return false, "Nur Gruender-Captain darf Captain verwalten"
        end

        if targetKey ~= state.crew.founderUser then
            return false, "Fuer weitere Leitung bitte Co-Captain vergeben"
        end
    elseif roleName == "co_captain" and actorKey ~= state.crew.founderUser then
        return false, "Nur Gruender-Captain darf Co-Captain vergeben"
    end

    user.roles = user.roles or {}
    if user.roles[roleName] then
        return false, "Rolle bereits gesetzt"
    end
    user.roles[roleName] = true
    state.crew.selectedUser = targetKey
    saveConfig(state)
    runtime.log(state, user.name .. " erhielt Rolle " .. definition.label, "CREW")
    runtime.setNotice(state, definition.label .. " zugewiesen", 24)
    return true
end

function runtime.removeRoleFromUser(state, username, roleName)
    local definition = ROLE_DEFINITIONS[roleName]
    local actorKey = state.crew.session and state.crew.session.username or nil
    local targetKey, user = findCrewUser(state, username)
    if not definition then
        return false, "Unbekannte Rolle"
    end

    if not user then
        return false, "Benutzer unbekannt"
    end

    if not (user.roles and user.roles[roleName]) then
        return false, "Rolle ist nicht gesetzt"
    end

    if roleName == "captain" then
        if actorKey ~= state.crew.founderUser then
            return false, "Nur Gruender-Captain darf Captain entfernen"
        end
        if targetKey == state.crew.founderUser then
            return false, "Gruender-Captain kann nicht entfernt werden"
        end
    elseif roleName == "co_captain" and actorKey ~= state.crew.founderUser then
        return false, "Nur Gruender-Captain darf Co-Captain entfernen"
    end

    user.roles[roleName] = nil
    state.crew.selectedUser = targetKey
    saveConfig(state)
    runtime.log(state, user.name .. " verlor Rolle " .. definition.label, "CREW")
    runtime.setNotice(state, definition.label .. " entfernt", 24)

    if state.crew.session.username == targetKey and state.crew.session.role == roleName then
        runtime.logoutRole(state)
    end

    return true
end

function runtime.deleteCrewUser(state, username)
    local actorKey, actor = currentCrewUser(state)
    local targetKey, user = findCrewUser(state, username)
    if not actorKey or not actor then
        return false, "Login noetig"
    end

    if not user then
        return false, "Benutzer unbekannt"
    end

    if targetKey == actorKey then
        return false, "Eigenes Konto kann nicht geloescht werden"
    end

    if targetKey == state.crew.founderUser then
        return false, "Gruender-Captain kann nicht geloescht werden"
    end

    if userHasLeadership(user) and actorKey ~= state.crew.founderUser then
        return false, "Nur Gruender-Captain darf Leitungs-Konten loeschen"
    end

    state.crew.users[targetKey] = nil
    if state.crew.selectedUser == targetKey then
        state.crew.selectedUser = nil
    end
    ensureSelectedCrewUser(state)
    saveConfig(state)
    runtime.log(state, user.name .. " aus Crew entfernt", "CREW")
    runtime.setNotice(state, "Crew-Konto geloescht", 24)
    return true
end

function runtime.setRoleCode()
    return false, "Rollencodes wurden durch Crew-Konten ersetzt"
end

function runtime.isSecurityUnlocked(state)
    return state.security.keyOnline or state.security.unlockedTicks > 0
end

function runtime.securityStatus(state)
    if state.security.keyOnline then
        return "Schalter frei", state.theme.ok
    end

    if state.security.unlockedTicks > 0 then
        return "PIN frei", state.theme.ok
    end

    return "Nur kritisch", state.theme.muted
end

function runtime.securitySourceLabel(state)
    if state.assignments.keySwitchSide == "none" then
        return "Schalter nicht zugeordnet"
    end

    return "Schalter: " .. state.assignments.keySwitchSide
end

function runtime.securitySummary()
    return "PIN/Schalter gelten nur fuer Schub, Ruder, Fabrik, Reserve, Auto und Gefahr/Notfall"
end

function runtime.unlockWithPin(state, pin)
    if tostring(pin or "") == state.security.pin then
        state.security.unlockedTicks = 150
        runtime.log(state, "PIN-Freigabe erteilt", "SEC")
        runtime.setNotice(state, "PIN akzeptiert", 20)
        return true
    end

    runtime.log(state, "Falsche PIN eingegeben", "SEC")
    runtime.setNotice(state, "PIN falsch", 20)
    return false
end

function runtime.setPin(state, newPin)
    if newPin and newPin ~= "" then
        state.security.pin = tostring(newPin)
        saveConfig(state)
        runtime.log(state, "PIN aktualisiert", "SEC")
        runtime.setNotice(state, "Neue PIN gespeichert", 20)
        return true
    end

    return false
end

function runtime.requiresAccess(action)
    local protected = {
        toggle_thrust = true,
        turn_port = true,
        turn_starboard = true,
        turn_stop = true,
        toggle_factory = true,
        toggle_reserve = true,
        start_autopilot = true,
        set_pin = true,
        set_role_code = true,
        mode_danger = true,
        mode_emergency = true,
    }

    return protected[action] == true
end

function runtime.authorizeAction(state, action, context)
    context = context or {}
    local effectiveRole = context.source == "remote" and context.role or (state.crew.session and state.crew.session.role)

    if actionHasRoleRequirement(action) and not roleAllowsAction(effectiveRole, action) then
        return false, context.source == "remote" and "Rolle darf das nicht" or "Login fuer Bereich noetig"
    end

    if context.source == "remote" and actionHasRoleRequirement(action) then
        local _, user = findCrewUser(state, context.username)
        if not user or tostring(user.password or "") ~= tostring(context.password or "") then
            return false, "Benutzer oder Passwort falsch"
        end

        if not (user.roles and user.roles[context.role or ""]) then
            return false, "Rolle nicht zugewiesen"
        end
    end

    if not runtime.requiresAccess(action) then
        return true
    end

    if runtime.isSecurityUnlocked(state) then
        return true
    end

    if context.providedPin and tostring(context.providedPin) == state.security.pin then
        return true
    end

    return false, "PIN oder Schluesselschalter noetig"
end

function runtime.toggleManualAlarm(state)
    state.manualAlarm = not state.manualAlarm
    if not state.manualAlarm then
        state.alarmFlash = false
        runtime.setNotice(state, "Manueller Alarm quittiert", 24)
    elseif state.assignments.alarmOutputSide == "none" and not state.speaker then
        runtime.setNotice(state, "Manueller Alarm aktiv, aber ohne Alarm I/O und Speaker", 36)
    elseif state.assignments.alarmOutputSide == "none" then
        runtime.setNotice(state, "Manueller Alarm aktiv, nur Speaker vorhanden", 30)
    elseif not state.speaker then
        runtime.setNotice(state, "Manueller Alarm aktiv, nur Alarm I/O vorhanden", 30)
    else
        runtime.setNotice(state, "Manueller Alarm aktiv", 24)
    end
    runtime.log(state, state.manualAlarm and "Manueller Alarm aktiviert" or "Manueller Alarm quittiert", "ALARM")
    return state.manualAlarm
end

function runtime.stopAutopilot(state, reason)
    if state.autopilot.running then
        state.autopilot.running = false
        state.autopilot.ticksRemaining = 0
        state.autopilot.currentStepLabel = reason or "Gestoppt"
        stopMotion(state)
        state.helm.altitude = "Manuell"
        state.autopilot.lastRun = nowStamp() .. " - " .. (reason or "Manuell gestoppt")
        runtime.log(state, "Autopilot gestoppt: " .. (reason or "manuell"), "AUTO")
    end
end

local function beginAutopilotStep(state, step)
    state.outputs.thrust = step.thrust == true
    state.outputs.turnLeft = step.turnLeft == true
    state.outputs.turnRight = step.turnRight == true
    state.helm.heading = step.heading or "Still"
    state.helm.altitude = step.altitude or "Manuell"
    state.autopilot.currentStepLabel = step.label
    state.autopilot.ticksRemaining = step.ticks
end

local function advanceAutopilot(state)
    local program = AUTOPILOT_PROGRAMS[state.autopilot.selectedProgram]
    if not program then
        runtime.stopAutopilot(state, "Programm fehlt")
        return
    end

    state.autopilot.stepIndex = state.autopilot.stepIndex + 1
    local step = program.steps[state.autopilot.stepIndex]
    if not step then
        runtime.stopAutopilot(state, "Sequenz beendet")
        return
    end

    beginAutopilotStep(state, step)
end

function runtime.cycleAutopilotProgram(state)
    local nextIndex = 1
    for index, key in ipairs(AUTOPILOT_ORDER) do
        if key == state.autopilot.selectedProgram then
            nextIndex = index + 1
            break
        end
    end

    if nextIndex > #AUTOPILOT_ORDER then
        nextIndex = 1
    end

    state.autopilot.selectedProgram = AUTOPILOT_ORDER[nextIndex]
    state.autopilot.currentStepLabel = "Bereit"
    saveConfig(state)
    runtime.log(state, "Autopilotprogramm -> " .. AUTOPILOT_PROGRAMS[state.autopilot.selectedProgram].label, "AUTO")
    return state.autopilot.selectedProgram
end

function runtime.startAutopilot(state)
    if state.engine.emergencyStop then
        runtime.setNotice(state, "Not-Aus blockiert Autopilot", 26)
        return false
    end

    state.autopilot.running = true
    state.autopilot.stepIndex = 0
    state.autopilot.ticksRemaining = 0
    runtime.log(state, "Autopilot gestartet: " .. AUTOPILOT_PROGRAMS[state.autopilot.selectedProgram].label, "AUTO")
    advanceAutopilot(state)
    return true
end

function runtime.autopilotLabel(state)
    local program = AUTOPILOT_PROGRAMS[state.autopilot.selectedProgram]
    return program and program.label or "Unbekannt"
end

function runtime.autopilotStatus(state)
    if state.autopilot.running then
        return "Laeuft", state.theme.warning
    end

    return "Bereit", state.theme.ok
end

function runtime.toggleThrust(state)
    if state.autopilot.running then
        runtime.stopAutopilot(state, "Manueller Eingriff")
    end
    state.outputs.thrust = not state.outputs.thrust
    state.helm.thrust = state.outputs.thrust and "Aktiv" or "Leerlauf"
    runtime.log(state, state.outputs.thrust and "Schub aktiviert" or "Schub deaktiviert", "HELM")
    return state.outputs.thrust
end

function runtime.turnPort(state)
    if state.autopilot.running then
        runtime.stopAutopilot(state, "Manueller Eingriff")
    end
    state.outputs.turnLeft = true
    state.outputs.turnRight = false
    state.helm.heading = "Backbord"
    runtime.log(state, "Steuerung auf Backbord", "HELM")
end

function runtime.turnStarboard(state)
    if state.autopilot.running then
        runtime.stopAutopilot(state, "Manueller Eingriff")
    end
    state.outputs.turnLeft = false
    state.outputs.turnRight = true
    state.helm.heading = "Steuerbord"
    runtime.log(state, "Steuerung auf Steuerbord", "HELM")
end

function runtime.stopTurn(state)
    if state.autopilot.running then
        runtime.stopAutopilot(state, "Manueller Eingriff")
    end
    state.outputs.turnLeft = false
    state.outputs.turnRight = false
    state.helm.heading = "Still"
    runtime.log(state, "Steuerung neutral", "HELM")
end

function runtime.toggleFactory(state)
    state.outputs.factoryEnabled = not state.outputs.factoryEnabled
    state.factory.lineA = state.outputs.factoryEnabled and "Aktiv" or "Bereit"
    state.factory.mode = state.outputs.factoryEnabled and "Produktion" or "Standby"
    runtime.log(state, state.outputs.factoryEnabled and "Bordfabrik aktiviert" or "Bordfabrik angehalten", "MACH")
    return state.outputs.factoryEnabled
end

function runtime.toggleReserve(state)
    state.outputs.reserveMode = not state.outputs.reserveMode
    state.engine.reserveMode = state.outputs.reserveMode
    runtime.log(state, state.outputs.reserveMode and "Reservebetrieb aktiviert" or "Reservebetrieb deaktiviert", "MACH")
    return state.outputs.reserveMode
end

function runtime.activeAlertCount(state)
    return #state.alerts.ordered
end

function runtime.primaryAlert(state)
    local first = state.alerts.ordered[1]
    if first then
        return first.label, first.color
    end

    return "Keine Stoerung", state.theme.ok
end

function runtime.alarmStatus(state)
    if state.manualAlarm then
        return "Manuell aktiv", state.theme.warning
    end

    if state.systemAlarm then
        return runtime.primaryAlert(state)
    end

    return "Keine", state.theme.ok
end

function runtime.speakerStatus(state)
    if state.speaker then
        return "Verbunden", state.theme.ok
    end

    return "Nicht gefunden", state.theme.warning
end

function runtime.monitorLabel(state)
    if not state.monitor then
        return "-"
    end

    return state.monitorName or "Monitor auto"
end

function runtime.speakerLabel(state)
    if not state.speaker then
        return "-"
    end

    return state.speakerName or "Speaker auto"
end

function runtime.audioCueLabel(state)
    refreshAudioCatalog(state)
    local cue = findAudioCue(state, state.audio.selectedCue)
    if cue then
        return cue.label
    end

    return "Keine Cue"
end

function runtime.audioLastResult(state)
    return state.audio.lastResult or "Noch kein Audio-Test"
end

function runtime.customAudioCount(state)
    local count = 0
    for _, cue in ipairs(state.audio.cues or {}) do
        if cue.kind == "dfpwm" then
            count = count + 1
        end
    end

    return count
end

function runtime.cycleAudioCue(state, delta)
    refreshAudioCatalog(state)
    if not state.audio.selectedCue or #state.audio.cues == 0 then
        runtime.setNotice(state, "Keine Audio-Cues vorhanden", 24)
        return false
    end

    local currentIndex = 1
    for index, cue in ipairs(state.audio.cues) do
        if cue.key == state.audio.selectedCue then
            currentIndex = index
            break
        end
    end

    local nextIndex = currentIndex + (delta or 1)
    if nextIndex > #state.audio.cues then
        nextIndex = 1
    elseif nextIndex < 1 then
        nextIndex = #state.audio.cues
    end

    state.audio.selectedCue = state.audio.cues[nextIndex].key
    saveConfig(state)
    runtime.setNotice(state, "Audio-Cue: " .. state.audio.cues[nextIndex].label, 24)
    return true
end

function runtime.playSelectedAudioCue(state)
    refreshAudioCatalog(state)
    local cue = findAudioCue(state, state.audio.selectedCue)
    if not cue then
        runtime.setNotice(state, "Keine Audio-Cue gewaehlt", 24)
        return false, "Keine Cue"
    end

    local ok, method, message = playAudioCue(state, cue)
    recordAudioResult(state, cue, ok, method, message)
    runtime.setNotice(state, ok and (cue.label .. " gespielt") or ("Audio fehlgeschlagen: " .. tostring(message)), ok and 24 or 36)
    runtime.log(state, ok and ("Audio-Cue gespielt: " .. cue.label) or ("Audio-Cue fehlgeschlagen: " .. cue.label .. " (" .. tostring(message) .. ")"), "AUDIO")
    return ok, message
end

function runtime.testSpeaker(state)
    if not state.speaker then
        runtime.setNotice(state, "Kein Speaker gefunden", 28)
        runtime.log(state, "Speaker-Test fehlgeschlagen: kein Speaker", "ALARM")
        return false, "Kein Speaker"
    end

    if state.speaker then
        speakerInvoke(state, "stop")
    end

    state.audio.testTicks = 8
    state.audio.testPulse = 1
    state.audio.lastCue = "Speaker-Test"
    state.audio.lastResult = "Speaker-Test gestartet"
    state.audio.lastMethod = state.speakerName or "auto"
    state.audio.lastTime = nowStamp()

    runtime.setNotice(state, "Speaker-Test gestartet", 24)
    runtime.log(state, "Speaker-Test gestartet auf " .. runtime.speakerLabel(state), "ALARM")
    return true
end

function runtime.debugLines(state)
    local positionText = runtime.currentPositionLabel(state)
    local radioText = runtime.radioStatus(state)
    local securityText = runtime.securityStatus(state)
    local lastLog = state.logEntries[1] or "Kein Logeintrag"

    return {
        "Tick: " .. tostring(state.tickCount) .. " | Screen: " .. tostring(state.activeScreen) .. " | Modus: " .. runtime.modeLabel(state),
        "Crew: " .. runtime.operatorLabel(state) .. " | Rolle: " .. runtime.roleLabel(state) .. " | Auswahl: " .. runtime.selectedRoleLabel(state),
        "Monitor: " .. runtime.monitorLabel(state) .. " | Speaker: " .. runtime.speakerLabel(state),
        "Alarm: man=" .. tostring(state.manualAlarm) .. " sys=" .. tostring(state.systemAlarm) .. " flash=" .. tostring(state.alarmFlash) .. " io=" .. runtime.describeAssignment(state, "alarmOutputSide"),
        "Outputs: thrust=" .. tostring(state.outputs.thrust) .. " port=" .. tostring(state.outputs.turnLeft) .. " stb=" .. tostring(state.outputs.turnRight) .. " fact=" .. tostring(state.outputs.factoryEnabled) .. " res=" .. tostring(state.outputs.reserveMode),
        "GPS: " .. tostring(positionText) .. " | Funk: " .. tostring(radioText),
        "Security: " .. tostring(securityText) .. " | Key=" .. runtime.describeAssignment(state, "keySwitchSide") .. " | UnlockTicks=" .. tostring(state.security.unlockedTicks),
        "Audio-Cue: " .. runtime.audioCueLabel(state) .. " | Custom: " .. tostring(runtime.customAudioCount(state)) .. " | Last: " .. runtime.audioLastResult(state),
        "Letzter Log: " .. tostring(lastLog),
        "Audio-Ordner: " .. AUDIO_DIR,
    }
end

function runtime.renderDebugTerminal(state, nativeTerm)
    if not nativeTerm or not state.debug then
        return
    end

    local shouldMirror = state.activeScreen == "settings" and state.preferMonitor and state.monitor ~= nil
    if not shouldMirror and not state.debug.terminalMirrorActive then
        return
    end

    local current = term.current()
    term.redirect(nativeTerm)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)

    if shouldMirror then
        print("Sora's Magical OS Debug")
        print("-----------------------")
        for _, line in ipairs(runtime.debugLines(state)) do
            print(line)
        end
        print("")
        print("Eigene Audios in /smos/audio/*.dfpwm ablegen")
        state.debug.terminalMirrorActive = true
    else
        print("Sora's Magical OS")
        print("Debug-Terminal bereit.")
        print("Oeffne System fuer Live-Debug.")
        state.debug.terminalMirrorActive = false
    end

    term.redirect(current)
end

function runtime.signalStatus(state)
    if state.signalOnline then
        return "Online", state.theme.ok
    end

    return "Standby", state.theme.muted
end

function runtime.radioStatus(state)
    if state.comms.radioOnline then
        return "Online (" .. tostring(#state.comms.modemSides) .. ")", state.theme.ok
    end

    return "Offline", state.theme.warning
end

function runtime.crewUserCount(state)
    local count = 0
    for _ in pairs(state.crew.users or {}) do
        count = count + 1
    end

    return count
end

function runtime.crewManifestLines(state, maxRows)
    local rows = {}
    local keys = sortedCrewUserKeys(state)

    if #keys == 0 then
        return { "Noch keine Crew-Konten vorhanden" }
    end

    for index = 1, math.min(maxRows or #keys, #keys) do
        local key = keys[index]
        local user = state.crew.users[key]
        local suffix = key == state.crew.founderUser and " [Gruender]" or ""
        rows[#rows + 1] = user.name .. ": " .. roleLabelsForUser(user) .. suffix
    end

    return rows
end

function runtime.selectedRoleHint(state)
    if state.crew.selectedRole == "captain" and not runtime.hasCaptain(state) then
        return "Erster Captain wird beim Login automatisch angelegt"
    end

    if state.crew.selectedRole == "captain" then
        return "Captain bleibt Gruenderrolle; weitere Leitung als Co-Captain"
    end

    if state.crew.selectedRole == "co_captain" then
        return "Co-Captain hat Vollzugriff unter dem Gruender-Captain"
    end

    if runtime.currentUserIsFounder(state) then
        return "Gruender-Captain kann User loeschen und alle Rollen entziehen"
    end

    return "Crew-Leitung kann normale Rollen verwalten"
end

function runtime.welcomeMessage(state)
    if state.crew.session.role == "captain" then
        return "Willkommen an Bord Captain " .. runtime.operatorLabel(state)
    end

    if state.crew.session.role == "co_captain" then
        return "Willkommen an Bord Co-Captain " .. runtime.operatorLabel(state)
    end

    if state.crew.session.role then
        return "Willkommen an Bord " .. runtime.operatorLabel(state)
    end

    if not runtime.hasCaptain(state) then
        return "Noch kein Captain vorhanden - bitte Captain auf Crew einrichten"
    end

    return runtime.modeDescription(state)
end

function runtime.describeAssignment(state, key)
    local value = state.assignments[key] or "none"
    if value == "none" then
        return "Nicht zugeordnet"
    end

    return value
end

function runtime.isAlarmActive(state)
    return state.manualAlarm or state.systemAlarm
end

function runtime.isAlarmVisible(state)
        return runtime.isAlarmActive(state)
end

function runtime.describeSymbol(state)
    if not state.customSymbol or #state.customSymbol == 0 then
        return "Standard"
    end

    return tostring(#state.customSymbol) .. " Zeilen"
end

function runtime.checklistStatus(state)
    if state.checklist.ready then
        return "Startbereit", state.theme.ok
    end

    return "Checkliste offen", state.theme.warning
end

function runtime.currentWaypoint(state)
    return currentWaypoint(state)
end

function runtime.cycleWaypoint(state, delta)
    local step = delta or 1
    local count = #state.navigation.waypoints
    if count == 0 then
        return nil
    end

    local nextIndex = state.navigation.activeIndex + step
    if nextIndex > count then
        nextIndex = 1
    elseif nextIndex < 1 then
        nextIndex = count
    end

    state.navigation.activeIndex = nextIndex
    saveConfig(state)
    return currentWaypoint(state)
end

function runtime.updateWaypoint(state, data)
    local waypoint = currentWaypoint(state)
    waypoint.name = data.name or waypoint.name
    waypoint.distance = data.distance or waypoint.distance
    waypoint.direction = data.direction or waypoint.direction
    saveConfig(state)
    runtime.log(state, "Wegpunkt aktualisiert: " .. waypoint.name, "NAV")
end

function runtime.setHomePort(state, homePort)
    if not homePort or homePort == "" then
        return false
    end

    state.navigation.homePort = homePort
    if state.navigation.waypoints[1] then
        state.navigation.waypoints[1].name = homePort
        state.navigation.waypoints[1].distance = "0 km"
        state.navigation.waypoints[1].direction = "Dock"
    end
    saveConfig(state)
    runtime.log(state, "Heimathafen gesetzt: " .. homePort, "NAV")
    return true
end

local function buildStatusPacket(state)
    local alertLabel = runtime.primaryAlert(state)
    return {
        smos = true,
        kind = "status",
        client = "bridge",
        shipName = state.shipName,
        mode = state.mode,
        modeLabel = runtime.modeLabel(state),
        alert = alertLabel,
        alarm = runtime.isAlarmActive(state),
        checklistReady = state.checklist.ready,
        fuel = state.factory.fuel,
        destination = currentWaypoint(state).name,
        role = state.crew.session and state.crew.session.role or state.crew.selectedRole,
        computerId = os.getComputerID(),
    }
end

local function sendPacket(state, targetId, packet)
    if not state.comms.radioOnline or not rednet then
        return false, "Kein Funkmodem"
    end

    packet.smos = true
    if targetId then
        rednet.send(targetId, packet, "smos")
    else
        rednet.broadcast(packet, "smos")
    end

    state.comms.lastContact = nowStamp()
    return true
end

function runtime.sendOperatorMessage(state, targetId, text)
    if not text or text == "" then
        return false, "Leere Nachricht"
    end

    local author = runtime.operatorLabel(state)
    local role = state.crew.session and state.crew.session.role or state.crew.selectedRole
    local packet = {
        kind = "message",
        client = "bridge",
        shipName = state.shipName,
        text = text,
        role = role,
        author = author,
        username = state.crew.session and state.crew.session.username or nil,
    }

    local ok, errorMessage = sendPacket(state, targetId, packet)

    if ok then
        pushInboxEntry(state, {
            direction = "out",
            client = "bridge",
            peerId = os.getComputerID(),
            role = role,
            author = author,
            text = text,
        })
        runtime.log(state, "Funk gesendet: " .. text, "COMMS")
        state.comms.lastPeer = peerLabel(os.getComputerID(), "bridge")
    end

    return ok, errorMessage
end

function runtime.requestStatus(state, targetId)
    return sendPacket(state, targetId, {
        kind = "status_request",
        shipName = state.shipName,
    })
end

function runtime.handleCommsPacket(state, senderId, message)
    if type(message) ~= "table" or message.smos ~= true then
        return nil
    end

    state.comms.lastPeer = peerLabel(senderId, message.client)
    state.comms.lastContact = nowStamp()

    if message.kind == "discover" then
        local requestedName = normalizeShipName(message.shipName)
        local currentName = normalizeShipName(state.shipName)
        if requestedName == "" or requestedName == currentName then
            if message.client == "tablet" then
                state.comms.linkedTabletId = senderId
                saveConfig(state)
                runtime.log(state, "Tablet gekoppelt: ID " .. tostring(senderId), "COMMS")
            end
            sendPacket(state, senderId, buildStatusPacket(state))
        end
        return nil
    end

    if message.kind == "status_request" then
        sendPacket(state, senderId, buildStatusPacket(state))
        return nil
    end

    if message.kind == "message" then
        pushInboxEntry(state, {
            direction = "in",
            client = message.client,
            peerId = senderId,
            text = tostring(message.text or ""),
            role = tostring(message.role or "extern"),
            author = message.author or message.username,
        })
        runtime.log(state, "Funk von " .. tostring(senderId) .. ": " .. tostring(message.text or ""), "COMMS")
        runtime.setNotice(state, "Neue Funknachricht", 30)
        return nil
    end

    if message.kind == "action" then
        return {
            action = message.action,
            source = "remote",
            role = message.role,
            username = message.username,
            password = tostring(message.password or ""),
            providedPin = tostring(message.pin or ""),
            senderId = senderId,
        }
    end

    return nil
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
    if side and state.monitorName and side ~= state.monitorName then
        return nil
    end

    for _, target in ipairs(state.touchTargets) do
        if x >= target.x and x <= target.x + target.width - 1 and y >= target.y and y <= target.y + target.height - 1 then
            return target.action
        end
    end

    return nil
end

local function updateHelmAndFactory(state)
    state.helm.thrust = state.outputs.thrust and "Aktiv" or "Leerlauf"

    if state.outputs.turnLeft then
        state.helm.heading = "Backbord"
    elseif state.outputs.turnRight then
        state.helm.heading = "Steuerbord"
    elseif state.signalOnline then
        state.helm.heading = "Signal erkannt"
    else
        state.helm.heading = "Still"
    end

    if state.engine.emergencyStop then
        state.helm.failsafe = "Not-Aus"
    elseif runtime.isSecurityUnlocked(state) then
        state.helm.failsafe = "Freigabe aktiv"
    else
        state.helm.failsafe = "Gesperrt"
    end

    state.factory.fuel = state.engine.fuelLow and "Tank pruefen" or "Tank okay"
    state.factory.lineA = state.outputs.factoryEnabled and "Aktiv" or "Bereit"
    state.factory.mode = state.outputs.factoryEnabled and "Produktion" or "Standby"
    if state.engine.overload then
        state.factory.storage = "Ueberlast"
    elseif state.outputs.factoryEnabled then
        state.factory.storage = "Laufend"
    else
        state.factory.storage = "Normal"
    end
end

local function evaluateChecklist(state)
    local desiredFactoryMode = state.checklist.desiredFactoryMode
    local factoryReady = true
    if desiredFactoryMode == "Standby" then
        factoryReady = not state.outputs.factoryEnabled
    elseif desiredFactoryMode == "Produktion" then
        factoryReady = state.outputs.factoryEnabled
    end

    state.checklist.items = {
        { label = "Helm-Signal", ok = state.signalOnline },
        { label = "Treibstoff", ok = not state.engine.fuelLow },
        { label = "Fabrik: " .. desiredFactoryMode, ok = factoryReady },
        { label = "Alarmausgang", ok = state.assignments.alarmOutputSide ~= "none" },
        { label = "Monitor", ok = state.monitor ~= nil },
        { label = "Speaker", ok = state.speaker ~= nil },
    }

    state.checklist.ready = true
    for _, item in ipairs(state.checklist.items) do
        if not item.ok then
            state.checklist.ready = false
            break
        end
    end
end

local function evaluateAlerts(state)
    local active = {}
    local critical = false
    local alertMap = {}

    local function addAlert(key)
        local definition = ALERT_DEFINITIONS[key]
        active[#active + 1] = {
            key = key,
            label = definition.label,
            color = definition.color,
            critical = definition.critical,
        }
        alertMap[key] = true
        if definition.critical then
            critical = true
        end
    end

    if state.engine.enemyContact then
        addAlert("enemy_contact")
    end
    if state.engine.emergencyStop then
        addAlert("emergency_stop")
    end
    if state.engine.driveFault then
        addAlert("drive_fault")
    end
    if state.mode ~= "parking" and not state.signalOnline then
        addAlert("helm_disconnected")
    end
    if state.engine.overload then
        addAlert("workshop_overload")
    end
    if state.engine.fuelLow then
        addAlert("fuel_low")
    end

    for key in pairs(alertMap) do
        if not state._lastAlertMap[key] then
            runtime.log(state, "Alarm: " .. ALERT_DEFINITIONS[key].label, "ALARM")
        end
    end
    for key in pairs(state._lastAlertMap) do
        if not alertMap[key] then
            runtime.log(state, "Alarm geloest: " .. ALERT_DEFINITIONS[key].label, "ALARM")
        end
    end

    state._lastAlertMap = alertMap
    state.alerts.ordered = active
    state.alerts.active = alertMap
    state.systemAlarm = state.modeAlarm or critical or (state.mode == "danger" and #active > 0)
end

local function tickAutopilot(state)
    if not state.autopilot.running then
        return
    end

    if state.autopilot.ticksRemaining > 0 then
        state.autopilot.ticksRemaining = state.autopilot.ticksRemaining - 1
        return
    end

    advanceAutopilot(state)
end

function runtime.tick(state)
    state.tickCount = state.tickCount + 1
    runtime.refreshPeripherals(state)

    if state.tickCount == 1 or state.tickCount % 10 == 0 then
        refreshGpsPosition(state)
    end

    if state.activeScreen == "settings" and (state.tickCount == 1 or state.tickCount % 25 == 0) then
        refreshAudioCatalog(state)
    end

    if state.audio and state.audio.testTicks and state.audio.testTicks > 0 then
        local testPattern = {
            { instrument = "pling", pitch = 18 },
            { instrument = "bell", pitch = 12 },
            { instrument = "bit", pitch = 20 },
            { instrument = "bell", pitch = 8 },
        }
        local tone = testPattern[state.audio.testPulse] or testPattern[1]
        local ok, result = speakerInvoke(state, "playNote", tone.instrument, 3, tone.pitch)
        if ok and result ~= false then
            state.audio.lastResult = "Speaker-Test spielt"
            state.audio.lastMethod = "Note"
        else
            state.audio.lastResult = "Speaker-Test blockiert oder stumm"
        end
        state.audio.lastTime = nowStamp()
        state.audio.testTicks = state.audio.testTicks - 1
        state.audio.testPulse = state.audio.testPulse + 1
        if state.audio.testPulse > #testPattern then
            state.audio.testPulse = 1
        end
    end

    if state.noticeTicks > 0 then
        state.noticeTicks = state.noticeTicks - 1
        if state.noticeTicks == 0 then
            state.notice = ""
        end
    end

    if state.security.unlockedTicks > 0 and not state.security.keyOnline then
        state.security.unlockedTicks = state.security.unlockedTicks - 1
    end

    state.signalOnline = sideInput(state.assignments.helmSignalSide)
    state.engine.fuelLow = not sideInput(state.assignments.fuelSensorSide)
    state.engine.generatorOnline = sideInput(state.assignments.generatorSensorSide)
    state.engine.overload = sideInput(state.assignments.overloadSensorSide)
    state.engine.enemyContact = sideInput(state.assignments.enemySensorSide)
    state.security.keyOnline = sideInput(state.assignments.keySwitchSide)
    state.engine.emergencyStop = sideInput(state.assignments.emergencyStopSide)
    state.engine.reserveMode = state.outputs.reserveMode
    state.engine.productionActive = state.outputs.factoryEnabled
    state.engine.driveFault = state.outputs.thrust and not state.engine.generatorOnline

    if state.engine.emergencyStop then
        if not state._lastEmergencyStop then
            runtime.log(state, "Physischer Not-Aus aktiviert", "SEC")
            runtime.setNotice(state, "Not-Aus aktiv", 30)
        end
        runtime.stopAutopilot(state, "Not-Aus")
        stopMotion(state)
        state.outputs.factoryEnabled = false
    elseif state._lastEmergencyStop then
        runtime.log(state, "Physischer Not-Aus geloest", "SEC")
    end
    state._lastEmergencyStop = state.engine.emergencyStop

    tickAutopilot(state)
    updateHelmAndFactory(state)
    evaluateChecklist(state)
    evaluateAlerts(state)

    setOutput(state.assignments.thrustOutputSide, state.outputs.thrust)
    setOutput(state.assignments.portOutputSide, state.outputs.turnLeft)
    setOutput(state.assignments.starboardOutputSide, state.outputs.turnRight)
    setOutput(state.assignments.factoryOutputSide, state.outputs.factoryEnabled)
    setOutput(state.assignments.reserveOutputSide, state.outputs.reserveMode)

    if not runtime.isAlarmActive(state) then
        state.alarmFlash = false
        setOutput(state.assignments.alarmOutputSide, false)
        return
    end

    state.alarmFlash = not state.alarmFlash
    if state.manualAlarm then
        setOutput(state.assignments.alarmOutputSide, true)
    else
        setOutput(state.assignments.alarmOutputSide, state.alarmFlash)
    end

    playAlarmTone(state)
end

return runtime