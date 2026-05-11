local args = { ... }

local BRIDGE_FILES = {
    { source = "startup.lua", target = "startup.lua" },
    { source = "smos/boot.lua", target = "smos/boot.lua" },
    { source = "smos/app/runtime.lua", target = "smos/app/runtime.lua" },
    { source = "smos/app/theme.lua", target = "smos/app/theme.lua" },
    { source = "smos/app/ui.lua", target = "smos/app/ui.lua" },
    { source = "smos/app/screens.lua", target = "smos/app/screens.lua" },
}

local TABLET_FILES = {
    { source = "tablet.lua", target = "tablet.lua" },
}

local function trimTrailingSlash(value)
    return (value:gsub("/+$", ""))
end

local function normalizeBaseUrl(value)
    local normalized = trimTrailingSlash(value or "")

    normalized = normalized:gsub("/install%.lua$", "")
    normalized = normalized:gsub("/startup%.lua$", "")

    if not normalized:match("^https?://") then
        error("Base URL must start with http:// or https://")
    end

    return normalized
end

local function prompt(label, defaultValue)
    write(label)
    if defaultValue and defaultValue ~= "" then
        write(" [" .. defaultValue .. "]")
    end
    write(": ")

    local value = read()
    if value == "" or value == nil then
        return defaultValue
    end

    return value
end

local function joinPath(base, relative)
    if not base or base == "" or base == "/" then
        return relative
    end

    if base:sub(-1) == "/" then
        return base .. relative
    end

    return base .. "/" .. relative
end

local function ensureParent(path)
    local parent = fs.getDir(path)
    if parent and parent ~= "" then
        fs.makeDir(parent)
    end
end

local function fetch(url)
    if not http then
        error("HTTP API is unavailable. Enable it in CC:Tweaked.")
    end

    local handle, errorMessage = http.get(url)
    if not handle then
        error("Download failed for " .. url .. ": " .. tostring(errorMessage))
    end

    local body = handle.readAll()
    handle.close()
    return body
end

local function installFile(baseUrl, targetRoot, entry)
    local url = baseUrl .. "/" .. entry.source
    local targetPath = joinPath(targetRoot, entry.target)

    print("Downloading " .. entry.source .. " ...")
    local content = fetch(url)
    ensureParent(targetPath)

    local file = fs.open(targetPath, "w")
    if not file then
        error("Could not open target file " .. targetPath)
    end

    file.write(content)
    file.close()
end

local function resolveProfile(value)
    local normalized = string.lower(value or "bridge")
    if normalized == "tablet" or normalized == "pocket" then
        return "tablet", TABLET_FILES
    end

    return "bridge", BRIDGE_FILES
end

local function main()
    term.setTextColor(colors.white)
    term.setBackgroundColor(colors.black)
    print("Sora's Magical OS installer")
    print("---------------------------")

    local baseUrl = args[1]
    local targetRoot = args[2]
    local profile = args[3]

    if not baseUrl or baseUrl == "" then
        baseUrl = prompt("Base URL", "https://raw.githubusercontent.com/USER/REPO/BRANCH/soras-magical-os/prototype/computercraft")
    end
    if not targetRoot or targetRoot == "" then
        targetRoot = prompt("Install to", "/")
    end
    if not profile or profile == "" then
        profile = prompt("Profile (bridge/tablet)", "bridge")
    end

    baseUrl = normalizeBaseUrl(baseUrl)
    targetRoot = trimTrailingSlash(targetRoot)
    if targetRoot == "" then
        targetRoot = "/"
    end

    local filesToInstall
    profile, filesToInstall = resolveProfile(profile)

    print("Source: " .. baseUrl)
    print("Target: " .. targetRoot)
    print("Profile: " .. profile)
    print("")

    for _, entry in ipairs(filesToInstall) do
        installFile(baseUrl, targetRoot, entry)
    end

    print("")
    print("Installation complete.")
    if profile == "tablet" then
        print("Run 'tablet' on the pocket computer to connect with the ship.")
    elseif targetRoot == "/" then
        print("Run 'reboot' or 'startup' to launch Sora's Magical OS.")
    else
        print("If you installed to a disk, copy files from " .. targetRoot .. " onto the target computer.")
    end
end

main()