
--[[ POLAHACK Loader v4 - Sesion por anuncio, sin key precargada, R2 ]]
local API = "https://polagodd.scriptroblox.workers.dev"
local Http = game:GetService("HttpService")
local env = getgenv()
env.POLAHACK_LOADER_SESSION = (env.POLAHACK_LOADER_SESSION or 0) + 1
local runId = env.POLAHACK_LOADER_SESSION
local function alive() return env.POLAHACK_LOADER_SESSION == runId end
if env.POLAHACK_LOADER_GUI then pcall(function() env.POLAHACK_LOADER_GUI:Destroy() end) end

local function hwid()
    if type(gethwid) == "function" then
        local ok, v = pcall(gethwid)
        if ok and type(v) == "string" and #v >= 8 then return v end
    end
    local ok, v = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    if ok and type(v) == "string" and #v >= 8 then return v end
    return nil
end
local identifier = hwid()
if not identifier then warn("[POLAHACK] No se pudo obtener HWID") return end
local SID = identifier:sub(1, 16)

local function send(path, data)
    local fn = (type(request) == "function" and request)
        or (type(http_request) == "function" and http_request)
        or (type(syn) == "table" and type(syn.request) == "function" and syn.request)
    if not fn then return nil, "Executor sin HTTP POST" end
    local ok, res = pcall(function()
        return fn({Url = API .. path, Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = Http:JSONEncode(data)})
    end)
    if not ok or type(res) ~= "table" then return nil, tostring(res) end
    return res
end
local function postJSON(path, data)
    local res, err = send(path, data)
    if not res then return nil, err end
    local ok, body = pcall(function() return Http:JSONDecode(res.Body or "") end)
    if not ok or type(body) ~= "table" then return nil, "Respuesta JSON invalida" end
    return body
end
local function copy(text)
    local fn = type(setclipboard) == "function" and setclipboard
        or type(toclipboard) == "function" and toclipboard
    if not fn then return false end
    return pcall(fn, text)
end
local function normalizeKey(s)
    if type(s) ~= "string" then return nil end
    s = s:match("^%s*(.-)%s*$"):upper()
    if not s:match("^POLA%-[A-Z2-9][A-Z2-9][A-Z2-9][A-Z2-9]%-[A-Z2-9][A-Z2-9][A-Z2-9][A-Z2-9]%-[A-Z2-9][A-Z2-9][A-Z2-9][A-Z2-9]$") then return nil end
    return s
end
local function verify(key)
    local ok, raw = pcall(function()
        return game:HttpGet(API .. "/verify?key=" .. Http:UrlEncode(key) .. "&hwid=" .. Http:UrlEncode(SID), true)
    end)
    if not ok then return nil end
    local parsed, data = pcall(function() return Http:JSONDecode(raw) end)
    return parsed and data or nil
end

local gui = Instance.new("ScreenGui")
gui.Name = "POLAHACK_LOADER"
gui.ResetOnSpawn = false
env.POLAHACK_LOADER_GUI = gui
pcall(function() if type(gethui) == "function" then gui.Parent = gethui() end end)
if not gui.Parent then
    local ok = pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not ok then warn("[POLAHACK] No se pudo mostrar la interfaz") return end
end
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromOffset(360, 225)
frame.Position = UDim2.new(.5, -180, .5, -112)
frame.BackgroundColor3 = Color3.fromRGB(14, 17, 24)
frame.BorderSizePixel = 0
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(59, 130, 246)
local function label(text, y, h, size, bold)
    local l = Instance.new("TextLabel", frame)
    l.Size = UDim2.new(1, -24, 0, h)
    l.Position = UDim2.fromOffset(12, y)
    l.BackgroundTransparency = 1
    l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    l.TextSize = size
    l.TextColor3 = bold and Color3.fromRGB(125, 211, 252) or Color3.fromRGB(177, 190, 207)
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextWrapped = true
    l.Text = text
    return l
end
label("POLAHACK", 10, 26, 17, true)
local status = label("Toca el boton para generar un enlace nuevo.", 38, 36, 12, false)
local box = Instance.new("TextBox", frame)
box.Size = UDim2.new(1, -24, 0, 32)
box.Position = UDim2.fromOffset(12, 80)
box.BackgroundColor3 = Color3.fromRGB(9, 11, 16)
box.BorderSizePixel = 0
box.Font = Enum.Font.Code
box.TextSize = 13
box.TextColor3 = Color3.fromRGB(232, 236, 243)
box.PlaceholderText = "POLA-XXXX-XXXX-XXXX"
box.ClearTextOnFocus = false
box.Text = ""
Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)
local btn = Instance.new("TextButton", frame)
btn.Size = UDim2.new(1, -24, 0, 34)
btn.Position = UDim2.fromOffset(12, 120)
btn.BackgroundColor3 = Color3.fromRGB(37, 99, 235)
btn.BorderSizePixel = 0
btn.Font = Enum.Font.GothamBold
btn.TextSize = 12
btn.TextColor3 = Color3.new(1, 1, 1)
btn.Text = "COPIAR LINK Y COMPLETAR ANUNCIO"
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
local hint = label("La key aparecera solo cuando esta sesion reciba la recompensa.", 162, 52, 11, false)

local busy, finished, pollVersion = false, false, 0
local function say(t) if alive() then status.Text = t end end
local function launch(key, tier, exp)
    if busy or finished or not alive() then return end
    busy = true
    say("Descargando desde Cloudflare R2...")
    task.spawn(function()
        local response, err = send("/payload", {key = key, hwid = SID})
        if not alive() then return end
        if not response then busy = false say("Error: " .. tostring(err)) return end
        local code = tonumber(response.StatusCode or response.Status)
        if code ~= 200 then
            local reason = "HTTP " .. tostring(code)
            pcall(function()
                local data = Http:JSONDecode(response.Body)
                reason = data.reason or reason
            end)
            busy = false say("Error de payload: " .. tostring(reason)) return
        end
        local source = response.Body
        if type(source) ~= "string" or #source < 100 then busy = false say("Payload vacio") return end
        local fn, compileError = loadstring(source)
        if not fn then busy = false say("Error compilando: " .. tostring(compileError)) return end
        env.POLAHACK = {api = API, key = key, hwid = SID, tier = tier, exp = exp}
        say("Iniciando...")
        local ok, runtimeError = pcall(fn)
        if not alive() then return end
        if not ok then busy = false say("Error: " .. tostring(runtimeError)) return end
        finished = true
        busy = false
        pollVersion = pollVersion + 1
        gui.Enabled = false
    end)
end
local function tryKey(raw)
    if busy or finished or not alive() then return end
    local key = normalizeKey(raw)
    if not key then say("Formato de key invalido") return end
    say("Verificando key...")
    local result = verify(key)
    if not alive() then return end
    if not result or not result.ok then
        say("Key: " .. tostring(result and result.reason or "sin respuesta"))
        return
    end
    box.Text = key
    launch(key, result.tier, result.exp)
end
btn.MouseButton1Click:Connect(function()
    if busy or finished or not alive() then return end
    -- Siempre comienza una sesion nueva, nunca consulta una licencia historica.
    pollVersion = pollVersion + 1
    local thisPoll = pollVersion
    say("Creando sesion de anuncio...")
    local session, err = postJSON("/session", {hwid = SID})
    if not alive() or thisPoll ~= pollVersion then return end
    if not session or not session.ok then
        say("Error creando sesion: " .. tostring(err or (session and session.reason))) return
    end
    local copied = copy(session.url)
    hint.Text = copied
        and "LINK COPIADO. Pegalo en Chrome (Ctrl+V) y completa el anuncio."
        or "No se pudo copiar: selecciona el link mostrado en la consola."
    if not copied then print("[POLAHACK] LINK: " .. session.url) end
    say("Esperando el anuncio de esta sesion...")
    task.spawn(function()
        for _ = 1, 120 do
            task.wait(3)
            if not alive() or thisPoll ~= pollVersion or finished then return end
            local data = postJSON("/poll", {id = session.id, secret = session.secret})
            if not alive() or thisPoll ~= pollVersion then return end
            if data and data.ok and data.key then
                pollVersion = pollVersion + 1
                box.Text = data.key
                tryKey(data.key)
                return
            end
        end
        if alive() and thisPoll == pollVersion then say("Tiempo agotado. Genera otro enlace.") end
    end)
end)
box.FocusLost:Connect(function(enter)
    if enter and alive() then
        pollVersion = pollVersion + 1
        tryKey(box.Text)
    end
end)
-- Intencionalmente no se lee POLAHACK.key y no se hace polling al iniciar.
