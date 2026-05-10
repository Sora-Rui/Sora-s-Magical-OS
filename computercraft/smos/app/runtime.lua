local runtime = {}

local CONFIG_PATH = "/smos/config.txt"
local LOG_PATH = "/smos/log.txt"
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

local function normalizeRoleAccounts(raw)
    local accounts = {}
    for roleName, definition in pairs(ROLE_DEFINITIONS) do
        local code = definition.defaultCode
        if type(raw) == "table" then
            if type(raw[roleName]) == "table" and raw[roleName].code then
                code = tostring(raw[roleName].code)
            elseif raw[roleName] ~= nil then
                code = tostring(raw[roleName])
            end
        end

        accounts[roleName] = {
            code = code,
        }
    end

    return accounts
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

local function sideInput(side)
    return side and side ~= "none" and redstone.getInput(side) or false
end

local function setOutput(side, enabled)
    if side and side ~= "none" then
        redstone.setOutput(side, enabled)
    end
end

local function trimInbox(inbox)
    while #inbox > 8 do
        table.remove(inbox)
    end
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
        roleAccounts = state.crew.accounts,
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

function runtime.setNotice(state, text, ticks)
    state.notice = text
    state.noticeTicks = ticks or 20
end

function runtime.newState(theme)
    local config = loadConfig()
    local monitor, monitorName = findMonitor()

    local state = {
        theme = theme,
        shipName = config.shipName or theme.shipName,
        palette = config.palette or "crimson",
        customSymbol = type(config.customSymbol) == "table" and config.customSymbol or DEFAULT_SYMBOL,
        screenOrder = SCREEN_ORDER,
        activeScreen = "home",
        selectedIndex = 1,
        speaker = findSpeaker(),
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
            selectedRole = config.activeRole or "pilot",
            accounts = normalizeRoleAccounts(config.roleAccounts),
            session = {
                role = nil,
                operator = "Gast",
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
        mode = config.mode or "parking",
        tickCount = 0,
        notice = "",
        noticeTicks = 0,
        logEntries = loadLog(),
        _lastAlertMap = {},
        _lastEmergencyStop = false,
    }

    runtime.applyTheme(state)
    runtime.setMode(state, state.mode, true)
    runtime.setScreen(state, config.activeScreen or "home")
    return state
end

function runtime.refreshPeripherals(state)
    state.speaker = findSpeaker()
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

function runtime.loginStatus(state)
    if state.crew.session.role then
        return "Eingeloggt", state.theme.ok
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

function runtime.loginRole(state, roleName, operatorName, roleCode)
    local account = state.crew.accounts[roleName]
    local definition = ROLE_DEFINITIONS[roleName]
    if not account or not definition then
        return false, "Unbekannte Rolle"
    end

    if tostring(roleCode or "") ~= tostring(account.code) then
        runtime.log(state, "Fehlerhafter Login fuer " .. definition.label, "SEC")
        runtime.setNotice(state, "Rollencode falsch", 24)
        return false, "Rollencode falsch"
    end

    state.crew.selectedRole = roleName
    state.crew.session.role = roleName
    state.crew.session.operator = operatorName and operatorName ~= "" and operatorName or definition.label
    runtime.log(state, state.crew.session.operator .. " eingeloggt als " .. definition.label, "CREW")
    runtime.setNotice(state, "Login: " .. definition.label, 24)
    return true
end

function runtime.logoutRole(state)
    local previousRole = runtime.roleLabel(state)
    local previousOperator = runtime.operatorLabel(state)
    state.crew.session.role = nil
    state.crew.session.operator = "Gast"
    runtime.log(state, previousOperator .. " ausgeloggt aus " .. previousRole, "CREW")
    runtime.setNotice(state, "Logout aktiv", 20)
    if not runtime.canAccessScreen(state, state.activeScreen) then
        runtime.setScreen(state, "home", { force = true })
    end
end

function runtime.setRoleCode(state, roleName, newCode)
    local account = state.crew.accounts[roleName]
    local definition = ROLE_DEFINITIONS[roleName]
    if not account or not definition or not newCode or newCode == "" then
        return false
    end

    account.code = tostring(newCode)
    saveConfig(state)
    runtime.log(state, "Rollencode gesetzt fuer " .. definition.label, "SEC")
    runtime.setNotice(state, "Rollencode gespeichert", 24)
    return true
end

function runtime.isSecurityUnlocked(state)
    return state.security.keyOnline or state.security.unlockedTicks > 0
end

function runtime.securityStatus(state)
    if state.security.keyOnline then
        return "Schluesselschalter aktiv", state.theme.ok
    end

    if state.security.unlockedTicks > 0 then
        return "PIN-Freigabe aktiv", state.theme.ok
    end

    return "Gesperrt", state.theme.warning
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
        local account = state.crew.accounts[context.role or ""]
        if not account or tostring(context.roleCode or "") ~= tostring(account.code) then
            return false, "Rollencode fehlt oder ist falsch"
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

function runtime.roleCodePreview(state)
    local account = state.crew.accounts[state.crew.selectedRole or ""]
    if not account or not account.code then
        return "Nicht gesetzt"
    end

    return string.rep("*", math.max(4, #tostring(account.code)))
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
    return runtime.isAlarmActive(state) and state.alarmFlash
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
        shipName = state.shipName,
        mode = state.mode,
        modeLabel = runtime.modeLabel(state),
        alert = alertLabel,
        alarm = runtime.isAlarmActive(state),
        checklistReady = state.checklist.ready,
        fuel = state.factory.fuel,
        destination = currentWaypoint(state).name,
        role = state.crew.activeRole,
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

    local ok, errorMessage = sendPacket(state, targetId, {
        kind = "message",
        shipName = state.shipName,
        text = text,
        role = state.crew.activeRole,
    })

    if ok then
        runtime.log(state, "Funk gesendet: " .. text, "COMMS")
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

    state.comms.lastPeer = tostring(senderId)
    state.comms.lastContact = nowStamp()

    if message.kind == "discover" then
        if not message.shipName or message.shipName == "" or string.lower(message.shipName) == string.lower(state.shipName) then
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
        table.insert(state.comms.inbox, 1, {
            from = tostring(senderId),
            text = tostring(message.text or ""),
            role = tostring(message.role or "extern"),
            time = nowStamp(),
        })
        trimInbox(state.comms.inbox)
        runtime.log(state, "Funk von " .. tostring(senderId) .. ": " .. tostring(message.text or ""), "COMMS")
        runtime.setNotice(state, "Neue Funknachricht", 30)
        return nil
    end

    if message.kind == "action" then
        return {
            action = message.action,
            source = "remote",
            role = message.role,
            roleCode = tostring(message.roleCode or ""),
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
    setOutput(state.assignments.alarmOutputSide, state.alarmFlash)

    if state.speaker then
        local note = alarmNotes[state.alarmPulse]
        state.speaker.playNote(note.instrument, 3, note.pitch)
        state.alarmPulse = state.alarmPulse + 1
        if state.alarmPulse > #alarmNotes then
            state.alarmPulse = 1
        end
    end
end

return runtime