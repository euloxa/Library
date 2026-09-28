local Players     = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local GAMES = {
    [98049867659682] = {
        Name      = "The Morgue Shift",
        ScriptURL = "https://raw.githubusercontent.com/euloxa/Library/refs/heads/main/loader/scripts/themorgueshift.lua",
    },
}

local FALLBACK_URL = nil

local CONFIG = {
    LoaderURL   = "https://raw.githubusercontent.com/euloxa/Library/refs/heads/main/loader/loader.lua",
    VerifyKey   = "L2-HUB",
    NotifyTime  = 4,
    Verbose     = true,
    SecretSalt  = "L2HUB_v1_SECRET_CHANGE_ME",
    SessionTTL  = 600,
    VerifyWait  = 120,
}

local function Log(msg)
    if CONFIG.Verbose then
        print("[L2-HUB] " .. tostring(msg))
    end
end

local function Notify(title, content, duration)
    duration = duration or CONFIG.NotifyTime

    if L2Hub and L2Hub.Notifier then
        pcall(function()
            L2Hub.Notifier.new({
                Title    = title,
                Content  = content,
                Duration = duration,
                Icon     = "lucide:info",
            })
        end)
        return
    end

    if Starlight and Starlight.Notify then
        pcall(Starlight.Notify, { Title = title, Content = content, Duration = duration })
    end
end

local function HMAC(str, salt)
    local out = 0
    for i = 1, #str do
        out = (out * 31 + str:byte(i)) % 2^31
    end
    return tostring(out)
end

local function GenerateSession()
    local sessionKey = table.concat({
        tostring(game.PlaceId),
        tostring(game.JobId or ""),
        tostring(os.time()),
        tostring(math.random(1, 2^30)),
        tostring(LocalPlayer.UserId or 0),
    }, "|")

    local signature   = HttpService:GenerateGUID(false)
    local fingerprint = HMAC(sessionKey .. CONFIG.SecretSalt, CONFIG.SecretSalt)

    getgenv().L2HUB_SESSION = {
        Key         = sessionKey,
        Signature   = signature,
        Fingerprint = fingerprint,
        PlaceId     = game.PlaceId,
        JobId       = game.JobId,
        UserId      = LocalPlayer.UserId,
        Time        = os.time(),
        Version     = 1,
    }

    Log("Session generated.")
    return getgenv().L2HUB_SESSION
end

local function LoadLoader()
    Log("Fetching loader UI...")

    local ok, source = pcall(game.HttpGet, game, CONFIG.LoaderURL)
    if not ok or type(source) ~= "string" or #source < 100 then
        Notify("L2-HUB", "Failed to fetch loader UI.", 5)
        return false
    end

    local chunk, err = loadstring(source)
    if not chunk then
        Notify("L2-HUB", "Loader compile error: " .. tostring(err), 6)
        return false
    end

    local ok2, err2 = pcall(chunk)
    if not ok2 then
        Notify("L2-HUB", "Loader runtime error: " .. tostring(err2), 6)
        return false
    end

    Log("Loader UI loaded.")
    return true
end

local function WaitForVerification(timeout)
    timeout = timeout or CONFIG.VerifyWait

    local bindable = Instance.new("BindableEvent")
    getgenv().L2HUB_VERIFIED = bindable

    local verified = false
    local conn = bindable.Event:Connect(function(result)
        if result == true then
            verified = true
        end
    end)

    local startTime = os.time()
    while not verified do
        if os.time() - startTime > timeout then
            Log("Verification timeout.")
            break
        end
        task.wait(0.2)
    end

    conn:Disconnect()
    bindable:Destroy()
    getgenv().L2HUB_VERIFIED = nil

    return verified
end

local function ExecuteScript(name, url)
    Log("Loading: " .. name .. " (" .. url .. ")")

    local ok, source = pcall(game.HttpGet, game, url)
    if not ok or type(source) ~= "string" or #source < 50 then
        Notify("L2-HUB", "Failed to download: " .. name, 5)
        return false
    end

    local chunk, err = loadstring(source)
    if not chunk then
        Notify("L2-HUB", "Compile error in " .. name .. ": " .. tostring(err), 6)
        return false
    end

    local ok2, err2 = pcall(chunk)
    if not ok2 then
        Notify("L2-HUB", "Runtime error in " .. name .. ": " .. tostring(err2), 6)
        return false
    end

    Notify("L2-HUB", name .. " loaded successfully.", 4)
    return true
end

local function GetGameInfo()
    local placeId = game.PlaceId
    local jobId   = game.JobId
    local entry   = GAMES[placeId]

    if entry then
        return {
            PlaceId = placeId,
            JobId   = jobId,
            Name    = entry.Name,
            URL     = entry.ScriptURL,
            Icon    = entry.Icon,
            Known   = true,
        }
    end

    if FALLBACK_URL then
        return {
            PlaceId = placeId,
            JobId   = jobId,
            Name    = "Unknown Game (fallback)",
            URL     = FALLBACK_URL,
            Known   = false,
        }
    end

    return {
        PlaceId = placeId,
        JobId   = jobId,
        Name    = "Unknown Game",
        URL     = nil,
        Known   = false,
    }
end

local function Main()
    local info = GetGameInfo()

    Log(string.format("PlaceId: %d | JobId: %s", info.PlaceId, info.JobId))
    Log("Detected: " .. info.Name)

    if not info.URL then
        Notify("L2-HUB", "Game not supported: " .. info.Name, 6)
        warn("[L2-HUB] No script URL for PlaceId " .. tostring(info.PlaceId))
        return
    end

    if not LoadLoader() then
        return
    end

    local verified = WaitForVerification(CONFIG.VerifyWait)
    if not verified then
        Log("Verification cancelled or timed out.")
        return
    end

    GenerateSession()
    task.wait(0.15)

    ExecuteScript(info.Name, info.URL)
end

task.spawn(function()
    local ok, err = pcall(Main)
    if not ok then
        warn("[L2-HUB] Fatal: " .. tostring(err))
        Notify("L2-HUB", "Fatal error: " .. tostring(err), 6)
    end
end)