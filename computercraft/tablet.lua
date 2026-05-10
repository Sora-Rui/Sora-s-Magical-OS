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
        username = state.username,
        password = state.password,
        pin = state.pin,
        status = state.status,
        protocolLog = state.protocolLog,
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

local function clipText(text, width)
    local value = tostring(text or "")
    if #value <= width then
        return value
    end

    if width <= 3 then
        return value:sub(1, width)
    end

    return value:sub(1, width - 3) .. "..."
end

local function deviceCode(client)
    if client == "tablet" then
        return "T"
    end

    return "BC"
end

local function trimProtocolLog(entries)
    while #entries > 10 do
        table.remove(entries)
    end
end

local function buildProtocolLine(direction, client, peerId, author, text)
    local marker = direction == "out" and ">" or direction == "in" and "<" or "*"
    local head = marker
    if peerId then
        head = head .. " " .. deviceCode(client) .. "#" .. tostring(peerId)
    end

    local name = trimText(author)
    if name ~= "" then
        head = head .. " " .. name
    end

    local body = trimText(text)
    if body ~= "" then
        head = head .. ": " .. body
    end

    return head
end

local function pushProtocol(state, line)
    table.insert(state.protocolLog, 1, tostring(line))
    trimProtocolLog(state.protocolLog)
    saveConfig(state)
end

local function promptCaptainProfile(state)
    local current = state.role == "captain" and "j" or "n"
    local answer = prompt("Captain-Profil", "Als Captain verbinden? (j/n)", current)
    local normalized = string.lower(tostring(answer or ""))
    if normalized:sub(1, 1) == "j" then
        state.role = "captain"
        state.note = "Captain-Profil aktiv"
    else
        if state.role == "captain" then
            state.role = "co_captain"
        end
        state.note = "Captain-Profil aus"
    end
    saveConfig(state)
end

local function runSetupWizard(state)
    state.shipName = prompt("Tablet-Setup", "Schiffsname", state.shipName) or ""
    promptCaptainProfile(state)
    state.username = prompt("Tablet-Setup", "Benutzer", state.username) or ""
    state.password = prompt("Tablet-Setup", "Passwort", state.password, true) or ""
    saveConfig(state)
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
    local width, height = term.getSize()
    local logStart = 12
    local logRows = math.max(4, height - logStart - 1)

    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
    print("Sora Tablet")
    print("Schiff: " .. (state.shipName ~= "" and state.shipName or "nicht gesetzt"))
    print("Link: " .. (state.shipId and ("BC#" .. tostring(state.shipId)) or "offline"))
    print("Crew: " .. state.role .. " | " .. (state.username ~= "" and state.username or "leer"))
    print("Modus: " .. (state.status.modeLabel or "?") .. " | Alarm " .. ((state.status.alarm and "Ja") or "Nein"))
    print("Ziel: " .. (state.status.destination or "?") .. " | Fuel " .. (state.status.fuel or "?"))
    print("Cmd : 1-8 9/0 M")
    print("Crew: P Rolle C Capt")
    print("Auth: U User W Pw")
    print("Sys : I PIN S Schiff R")
    print("Q Ende")
    print("Funkprotokoll")

    for index = 1, logRows do
        local line = state.protocolLog[index] or "-"
        print(clipText(line, width))
    end

    term.setCursorPos(1, height)
    write(clipText(state.note or "Bereit", width))
end

local function waitForStatus(state, timerId)
    while true do
        local event, p1, p2 = os.pullEvent()
        if event == "rednet_message" and type(p2) == "table" and p2.smos and p2.kind == "status" then
            local expectedName = normalizeShipName(state.shipName)
            local receivedName = normalizeShipName(p2.shipName)
            if expectedName == "" or receivedName == expectedName then
                state.shipId = p1
                state.status = p2
                state.note = "Verbunden mit " .. p2.shipName .. " (ID " .. tostring(p1) .. ")"
                pushProtocol(state, buildProtocolLine("sys", p2.client, p1, p2.shipName, "Status " .. tostring(p2.modeLabel or "?") .. " | Ziel " .. tostring(p2.destination or "?")))
                saveConfig(state)
                return true
            end
        elseif event == "timer" and p1 == timerId then
            return false
        end
    end
end

local function discoverShip(state)
    local function tryDiscovery(shipName, note)
        rednet.broadcast({
            smos = true,
            kind = "discover",
            shipName = shipName,
            client = "tablet",
        }, "smos")
        state.note = note
        pushProtocol(state, buildProtocolLine("sys", "tablet", os.getComputerID(), state.username, note))
        return waitForStatus(state, os.startTimer(2))
    end

    if state.shipName == "" then
        state.shipName = prompt("Schiff suchen", "Schiffsname", state.shipName)
        saveConfig(state)
    end

    if tryDiscovery(state.shipName, "Suche Schiff...") then
        return true
    end

    if normalizeShipName(state.shipName) ~= "" then
        state.note = "Kein exakter Treffer, pruefe offene Suche..."
        if tryDiscovery("", "Suche alle Schiffe...") then
            return true
        end
    end

    state.note = "Kein Schiff gefunden. Name und Bridge-Modem pruefen."
    return false
end

local function refreshStatus(state)
    if not state.shipId and not discoverShip(state) then
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
        pushProtocol(state, buildProtocolLine("sys", "bridge", nil, "", "Keine Statusantwort"))
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
        username = state.username,
        password = state.password,
        pin = state.pin,
        client = "tablet",
    }, "smos")
    state.note = "Befehl gesendet: " .. action
    pushProtocol(state, buildProtocolLine("out", "tablet", os.getComputerID(), state.username, "Aktion " .. action))
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
        author = state.username,
        username = state.username,
        text = text,
        client = "tablet",
    }, "smos")
    state.note = "Nachricht gesendet"
    pushProtocol(state, buildProtocolLine("out", "tablet", os.getComputerID(), state.username, text))
end

local function cycleRole(state)
    local order = { "pilot", "engineer", "alarm", "co_captain", "captain" }
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
        username = config.username or "",
        password = config.password or "",
        pin = config.pin or "",
        status = config.status or {
            modeLabel = "Unbekannt",
            alarm = false,
            fuel = "?",
            destination = "?",
        },
        protocolLog = type(config.protocolLog) == "table" and config.protocolLog or {},
        note = "Bereit",
    }

    if state.shipName == "" or state.username == "" then
        runSetupWizard(state)
    end

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
            elseif p1 == "c" then
                promptCaptainProfile(state)
            elseif p1 == "u" then
                state.username = prompt("Tablet-Benutzer", "Benutzer", state.username) or ""
                state.note = "Benutzer aktualisiert"
                saveConfig(state)
            elseif p1 == "w" then
                state.password = prompt("Tablet-Passwort", "Passwort", state.password, true) or ""
                state.note = "Passwort aktualisiert"
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
                pushProtocol(state, buildProtocolLine("sys", p2.client, p1, p2.shipName, "Status " .. tostring(p2.modeLabel or "?") .. " | Alarm " .. (((p2.alarm and "Ja") or "Nein"))))
                saveConfig(state)
            elseif p2.kind == "message" then
                state.note = "Funk: " .. tostring(p2.text or "")
                pushProtocol(state, buildProtocolLine("in", p2.client, p1, p2.author or p2.username or p2.role, p2.text or ""))
            end
        end
    end
end

main()