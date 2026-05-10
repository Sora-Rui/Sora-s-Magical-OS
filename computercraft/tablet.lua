local CONFIG_PATH = "/smos/tablet_config.txt"
local MODEM_SIDES = { "top", "bottom", "left", "right", "front", "back" }

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
        shipId = state.shipId,
        role = state.role,
        roleCode = state.roleCode,
        pin = state.pin,
        status = state.status,
    }))
    handle.close()
    return true
end

local function prompt(title, label, defaultValue, secret)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
    print("Sora Tablet")
    print(title)
    write(label)
    if defaultValue and defaultValue ~= "" then
        write(" [" .. defaultValue .. "]")
    end
    write(": ")
    local value = secret and read("*") or read()
    if value == "" or value == nil then
        return defaultValue
    end
    return value
end

local function ensureModem()
    if not rednet then
        return 0
    end

    local opened = 0
    for _, side in ipairs(MODEM_SIDES) do
        if peripheral and peripheral.isPresent and peripheral.getType and peripheral.isPresent(side) and peripheral.getType(side) == "modem" then
            if not rednet.isOpen(side) then
                rednet.open(side)
            end
            opened = opened + 1
        end
    end
    return opened
end

local function draw(state)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
    print("Sora Tablet")
    print("Schiff: " .. (state.shipName ~= "" and state.shipName or "nicht gesetzt"))
    print("Link: " .. (state.shipId and (state.status.shipName or "ID " .. tostring(state.shipId)) or "offline"))
    print("Rolle: " .. state.role .. "  Code: " .. (state.roleCode ~= "" and "gesetzt" or "leer"))
    print("Modus: " .. (state.status.modeLabel or "?") .. "  Alarm: " .. ((state.status.alarm and "Ja") or "Nein"))
    print("Fuel: " .. (state.status.fuel or "?") .. "  Ziel: " .. (state.status.destination or "?"))
    print("Globale PIN: " .. (state.pin ~= "" and "gesetzt" or "leer"))
    print("")
    print("1 Alarm  2 Dock  3 Reise")
    print("4 Gefahr 5 Not   6 Schub")
    print("7 Fabrik 8 Reserve")
    print("9 Auto+  0 Auto-")
    print("M Msg  P Rolle  U Code")
    print("I PIN  S Schiff  R Sync")
    print("Q Ende")
    print("")
    print(state.note or "Bereit")
end

local function waitForStatus(state, timerId)
    while true do
        local event, p1, p2 = os.pullEvent()
        if event == "rednet_message" and type(p2) == "table" and p2.smos and p2.kind == "status" then
            if not state.shipName or state.shipName == "" or string.lower(p2.shipName or "") == string.lower(state.shipName) then
                state.shipId = p1
                state.status = p2
                state.note = "Verbunden mit " .. p2.shipName .. " (ID " .. tostring(p1) .. ")"
                saveConfig(state)
                return true
            end
        elseif event == "timer" and p1 == timerId then
            return false
        end
    end
end

local function discoverShip(state)
    if state.shipName == "" then
        state.shipName = prompt("Schiff suchen", "Schiffsname", state.shipName)
        saveConfig(state)
    end

    rednet.broadcast({
        smos = true,
        kind = "discover",
        shipName = state.shipName,
        client = "tablet",
    }, "smos")
    state.note = "Suche Schiff..."
    return waitForStatus(state, os.startTimer(2))
end

local function refreshStatus(state)
    if not state.shipId and not discoverShip(state) then
        state.note = "Kein Schiff gefunden"
        return false
    end

    rednet.send(state.shipId, {
        smos = true,
        kind = "status_request",
        shipName = state.shipName,
    }, "smos")

    if not waitForStatus(state, os.startTimer(2)) then
        state.note = "Keine Statusantwort"
        state.shipId = nil
        saveConfig(state)
        return false
    end

    return true
end

local function sendAction(state, action)
    if not state.shipId and not discoverShip(state) then
        state.note = "Kein Schiff gefunden"
        return
    end

    rednet.send(state.shipId, {
        smos = true,
        kind = "action",
        action = action,
        role = state.role,
        roleCode = state.roleCode,
        pin = state.pin,
        client = "tablet",
    }, "smos")
    state.note = "Befehl gesendet: " .. action
    refreshStatus(state)
end

local function sendMessage(state)
    if not state.shipId and not discoverShip(state) then
        state.note = "Kein Schiff gefunden"
        return
    end

    local text = prompt("Funknachricht", "Text", "")
    if not text or text == "" then
        state.note = "Keine Nachricht gesendet"
        return
    end

    rednet.send(state.shipId, {
        smos = true,
        kind = "message",
        role = state.role,
        text = text,
        client = "tablet",
    }, "smos")
    state.note = "Nachricht gesendet"
end

local function cycleRole(state)
    local order = { "pilot", "engineer", "alarm" }
    local nextIndex = 1
    for index, role in ipairs(order) do
        if role == state.role then
            nextIndex = index + 1
            break
        end
    end
    if nextIndex > #order then
        nextIndex = 1
    end
    state.role = order[nextIndex]
    state.note = "Rolle: " .. state.role
    saveConfig(state)
end

local function main()
    if ensureModem() == 0 then
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.white)
        term.clear()
        term.setCursorPos(1, 1)
        print("Sora Tablet")
        print("Kein Modem gefunden.")
        print("Pocket Computer mit Wireless Modem nutzen.")
        return
    end

    local config = loadConfig()
    local state = {
        shipName = config.shipName or "",
        shipId = config.shipId,
        role = config.role or "pilot",
        roleCode = config.roleCode or "",
        pin = config.pin or "",
        status = config.status or {
            modeLabel = "Unbekannt",
            alarm = false,
            fuel = "?",
            destination = "?",
        },
        note = "Bereit",
    }

    if state.shipName ~= "" then
        refreshStatus(state)
    end

    while true do
        draw(state)
        local event, p1, p2 = os.pullEvent()

        if event == "char" then
            if p1 == "q" then
                term.setBackgroundColor(colors.black)
                term.setTextColor(colors.white)
                term.clear()
                term.setCursorPos(1, 1)
                return
            elseif p1 == "1" then
                sendAction(state, "toggle_alarm")
            elseif p1 == "2" then
                sendAction(state, "mode_docking")
            elseif p1 == "3" then
                sendAction(state, "mode_travel")
            elseif p1 == "4" then
                sendAction(state, "mode_danger")
            elseif p1 == "5" then
                sendAction(state, "mode_emergency")
            elseif p1 == "6" then
                sendAction(state, "toggle_thrust")
            elseif p1 == "7" then
                sendAction(state, "toggle_factory")
            elseif p1 == "8" then
                sendAction(state, "toggle_reserve")
            elseif p1 == "9" then
                sendAction(state, "start_autopilot")
            elseif p1 == "0" then
                sendAction(state, "stop_autopilot")
            elseif p1 == "m" then
                sendMessage(state)
            elseif p1 == "p" then
                cycleRole(state)
            elseif p1 == "u" then
                state.roleCode = prompt("Rollencode fuer die gewaehlte Rolle", "Rollencode", state.roleCode, true) or ""
                state.note = "Rollencode aktualisiert"
                saveConfig(state)
            elseif p1 == "i" then
                state.pin = prompt("Globale PIN fuer kritische Befehle", "PIN", state.pin, true) or ""
                state.note = "PIN aktualisiert"
                saveConfig(state)
            elseif p1 == "s" then
                state.shipName = prompt("Zielschiff", "Schiffsname", state.shipName) or ""
                state.shipId = nil
                state.note = "Schiff gespeichert"
                saveConfig(state)
            elseif p1 == "r" then
                refreshStatus(state)
            end
        elseif event == "rednet_message" and type(p2) == "table" and p2.smos then
            if p2.kind == "status" then
                state.shipId = p1
                state.status = p2
                state.note = "Status aktualisiert"
                saveConfig(state)
            elseif p2.kind == "message" then
                state.note = "Funk: " .. tostring(p2.text or "")
            end
        end
    end
end

main()