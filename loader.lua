
--[[
    POLAHACK LOADER v4.1
    Cloudflare Worker + R2 + Work.ink
    Compatible con Solara

    Cambios:
    - Verificacion de keys mediante POST
    - Keys fuera de las URLs de verificacion
    - Sesiones individuales por anuncio
    - Sin key precargada
    - Sin verificacion automatica
    - Payload privado desde R2
    - Control de ejecuciones duplicadas
]]

local API = "https://polagodd.scriptroblox.workers.dev"

local Http = game:GetService("HttpService")
local ENV = getgenv()

-- ==========================================
-- CANCELAR LOADERS ANTERIORES
-- ==========================================

ENV.POLAHACK_LOADER_SESSION =
    (ENV.POLAHACK_LOADER_SESSION or 0) + 1

local RUN_ID = ENV.POLAHACK_LOADER_SESSION

local function alive()
    return ENV.POLAHACK_LOADER_SESSION == RUN_ID
end

if ENV.POLAHACK_LOADER_GUI then
    pcall(function()
        ENV.POLAHACK_LOADER_GUI:Destroy()
    end)
end

-- ==========================================
-- HWID
-- ==========================================

local function getHWID()
    if type(gethwid) == "function" then
        local ok, value = pcall(gethwid)

        if ok
            and type(value) == "string"
            and #value >= 8 then
            return value
        end
    end

    local ok, value = pcall(function()
        return game:GetService(
            "RbxAnalyticsService"
        ):GetClientId()
    end)

    if ok
        and type(value) == "string"
        and #value >= 8 then
        return value
    end

    return nil
end

local identifier = getHWID()

if not identifier then
    warn("[POLAHACK] No se pudo obtener HWID.")
    return
end

local SID = identifier:sub(1, 16)

-- ==========================================
-- PORTAPAPELES
-- ==========================================

local function copy(text)
    local fn

    if type(setclipboard) == "function" then
        fn = setclipboard
    elseif type(toclipboard) == "function" then
        fn = toclipboard
    end

    if not fn then
        return false
    end

    return pcall(function()
        fn(text)
    end)
end

-- ==========================================
-- REQUEST HTTP
-- ==========================================

local function getRequest()
    if type(request) == "function" then
        return request
    end

    if type(http_request) == "function" then
        return http_request
    end

    if type(syn) == "table"
        and type(syn.request) == "function" then
        return syn.request
    end

    return nil
end

local function post(path, data)
    local fn = getRequest()

    if not fn then
        return nil, "HTTP POST no disponible"
    end

    local ok, response = pcall(function()
        return fn({
            Url = API .. path,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = Http:JSONEncode(data)
        })
    end)

    if not ok then
        return nil, tostring(response)
    end

    if type(response) ~= "table" then
        return nil, "Respuesta HTTP invalida"
    end

    return response
end

local function postJSON(path, data)
    local response, err = post(path, data)

    if not response then
        return nil, err
    end

    local ok, result = pcall(function()
        return Http:JSONDecode(response.Body or "")
    end)

    if not ok or type(result) ~= "table" then
        return nil, "Respuesta JSON invalida"
    end

    return result
end

-- ==========================================
-- VALIDAR FORMATO KEY
-- ==========================================

local function normalizeKey(value)
    if type(value) ~= "string" then
        return nil
    end

    local key = value
        :match("^%s*(.-)%s*$")
        :upper()

    local pattern =
        "^POLA%-" ..
        "[A-Z2-9][A-Z2-9][A-Z2-9][A-Z2-9]%-" ..
        "[A-Z2-9][A-Z2-9][A-Z2-9][A-Z2-9]%-" ..
        "[A-Z2-9][A-Z2-9][A-Z2-9][A-Z2-9]$"

    if not key:match(pattern) then
        return nil
    end

    return key
end

-- ==========================================
-- VERIFICACION SEGURA MEDIANTE POST
-- ==========================================

local function verify(key)
    return postJSON("/verify", {
        key = key,
        hwid = SID
    })
end

-- ==========================================
-- CREAR GUI
-- ==========================================

local gui = Instance.new("ScreenGui")
gui.Name = "POLAHACK_LOADER"
gui.ResetOnSpawn = false

ENV.POLAHACK_LOADER_GUI = gui

pcall(function()
    if type(gethui) == "function" then
        gui.Parent = gethui()
    end
end)

if not gui.Parent then
    local ok = pcall(function()
        gui.Parent = game:GetService("CoreGui")
    end)

    if not ok or not gui.Parent then
        warn("[POLAHACK] Error creando GUI.")
        return
    end
end

local frame = Instance.new("Frame")
frame.Parent = gui
frame.Size = UDim2.fromOffset(360, 225)
frame.Position = UDim2.new(0.5, -180, 0.5, -112)
frame.BackgroundColor3 = Color3.fromRGB(14, 17, 24)
frame.BorderSizePixel = 0

Instance.new("UICorner", frame).CornerRadius =
    UDim.new(0, 12)

local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(59, 130, 246)

local function label(text, y, h, size, bold)
    local l = Instance.new("TextLabel")
    l.Parent = frame

    l.Size = UDim2.new(1, -24, 0, h)
    l.Position = UDim2.fromOffset(12, y)
    l.BackgroundTransparency = 1

    l.Font = bold
        and Enum.Font.GothamBold
        or Enum.Font.Gotham

    l.TextSize = size

    l.TextColor3 = bold
        and Color3.fromRGB(125, 211, 252)
        or Color3.fromRGB(177, 190, 207)

    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextWrapped = true
    l.Text = text

    return l
end

label(
    "POLAHACK",
    10, 26, 17, true
)

local status = label(
    "Toca el boton para obtener tu key.",
    38, 36, 12, false
)

-- ==========================================
-- INPUT KEY
-- ==========================================

local box = Instance.new("TextBox")
box.Parent = frame
box.Size = UDim2.new(1, -24, 0, 32)
box.Position = UDim2.fromOffset(12, 80)

box.BackgroundColor3 =
    Color3.fromRGB(9, 11, 16)

box.BorderSizePixel = 0
box.Font = Enum.Font.Code
box.TextSize = 13

box.TextColor3 =
    Color3.fromRGB(232, 236, 243)

box.PlaceholderText = "POLA-XXXX-XXXX-XXXX"
box.ClearTextOnFocus = false
box.Text = ""

Instance.new("UICorner", box).CornerRadius =
    UDim.new(0, 8)

-- ==========================================
-- BOTON
-- ==========================================

local btn = Instance.new("TextButton")
btn.Parent = frame
btn.Size = UDim2.new(1, -24, 0, 34)
btn.Position = UDim2.fromOffset(12, 120)

btn.BackgroundColor3 =
    Color3.fromRGB(37, 99, 235)

btn.BorderSizePixel = 0
btn.Font = Enum.Font.GothamBold
btn.TextSize = 12

btn.TextColor3 =
    Color3.fromRGB(255, 255, 255)

btn.Text = "COPIAR LINK Y COMPLETAR ANUNCIO"

Instance.new("UICorner", btn).CornerRadius =
    UDim.new(0, 8)

local hint = label(
    "Completa un anuncio para recibir tu licencia.",
    162, 52, 11, false
)

-- ==========================================
-- ESTADO
-- ==========================================

local busy = false
local verifying = false
local creatingSession = false
local finished = false
local pollVersion = 0

local function say(text)
    if alive() and gui.Parent then
        status.Text = tostring(text)
    end
end

-- ==========================================
-- DESCARGAR PAYLOAD PRIVADO
-- ==========================================

local function launch(key, tier, exp)
    if busy or finished or not alive() then
        return
    end

    busy = true

    say("Licencia OK. Descargando desde R2...")

    task.spawn(function()
        local response, err = post(
            "/payload",
            {
                key = key,
                hwid = SID
            }
        )

        if not alive() then
            return
        end

        if not response then
            busy = false
            say("Error HTTP: " .. tostring(err))
            return
        end

        local code = tonumber(
            response.StatusCode or response.Status
        )

        if code ~= 200 then
            local reason = "HTTP " .. tostring(code)

            pcall(function()
                local data = Http:JSONDecode(
                    response.Body or ""
                )

                if data.reason then
                    reason = data.reason
                end
            end)

            busy = false
            say("Error R2: " .. tostring(reason))
            return
        end

        local source = response.Body

        if type(source) ~= "string"
            or #source < 100 then
            busy = false
            say("Payload vacio o invalido")
            return
        end

        local compiled, compileError =
            loadstring(source)

        if not compiled then
            busy = false

            say(
                "Error compilando: " ..
                tostring(compileError)
            )

            return
        end

        ENV.POLAHACK = {
            api = API,
            key = key,
            hwid = SID,
            tier = tier,
            exp = exp
        }

        say("Iniciando POLAHACK...")

        local ok, runtimeError = pcall(compiled)

        if not alive() then
            return
        end

        if not ok then
            busy = false

            say(
                "Error: " ..
                tostring(runtimeError)
            )

            return
        end

        finished = true
        busy = false

        pollVersion = pollVersion + 1

        gui.Enabled = false
    end)
end

-- ==========================================
-- VERIFICAR KEY MANUAL O DE ANUNCIO
-- ==========================================

local function tryKey(raw, expectedPoll)
    if busy or verifying or finished or not alive() then
        return
    end

    local key = normalizeKey(raw)

    if not key then
        say("Formato de key invalido")
        return
    end

    verifying = true
    say("Verificando key...")

    -- POST: la key no se envia en la URL

    local result, err = verify(key)

    verifying = false

    if not alive() then
        return
    end

    if expectedPoll
        and expectedPoll ~= pollVersion then
        return
    end

    if not result or not result.ok then
        say(
            "Key: " ..
            tostring(
                result and result.reason
                or err
                or "sin respuesta"
            )
        )

        return
    end

    box.Text = key

    launch(
        key,
        result.tier,
        result.exp
    )
end

-- ==========================================
-- GENERAR SESION Y COPIAR ENLACE
-- ==========================================

btn.MouseButton1Click:Connect(function()
    if not alive()
        or busy
        or verifying
        or creatingSession
        or finished then
        return
    end

    pollVersion = pollVersion + 1
    local thisPoll = pollVersion

    creatingSession = true
    say("Creando sesion de anuncio...")

    local session, err = postJSON(
        "/session",
        {
            hwid = SID
        }
    )

    creatingSession = false

    if not alive()
        or thisPoll ~= pollVersion then
        return
    end

    if not session or not session.ok then
        say(
            "Error de sesion: " ..
            tostring(
                session and session.reason
                or err
                or "sin respuesta"
            )
        )

        return
    end

    local copied = copy(session.url)

    if copied then
        hint.Text =
            "LINK COPIADO. Pegalo en Chrome " ..
            "(Ctrl+V) y completa el anuncio."
    else
        hint.Text =
            "No se pudo copiar. " ..
            "Mira el enlace en la consola."

        print(
            "[POLAHACK] LINK: " ..
            tostring(session.url)
        )
    end

    say("Esperando que completes el anuncio...")

    -- ======================================
    -- POLLING POR SESION
    -- ======================================

    task.spawn(function()
        for _ = 1, 120 do
            task.wait(3)

            if not alive()
                or thisPoll ~= pollVersion
                or finished then
                return
            end

            local data = postJSON(
                "/poll",
                {
                    id = session.id,
                    secret = session.secret
                }
            )

            if not alive()
                or thisPoll ~= pollVersion
                or finished then
                return
            end

            if data and data.ok and data.key then
                pollVersion = pollVersion + 1

                local completedPoll = pollVersion

                box.Text = data.key

                tryKey(
                    data.key,
                    completedPoll
                )

                return
            end

            if data
                and (
                    data.reason == "sesion_invalida"
                    or data.reason == "licencia_no_activa"
                ) then
                say(
                    "Sesion: " ..
                    tostring(data.reason)
                )

                return
            end
        end

        if alive()
            and thisPoll == pollVersion then
            say(
                "Tiempo agotado. " ..
                "Genera un enlace nuevo."
            )
        end
    end)
end)

-- ==========================================
-- KEY MANUAL CON ENTER
-- ==========================================

box.FocusLost:Connect(function(enterPressed)
    if not enterPressed or not alive() then
        return
    end

    pollVersion = pollVersion + 1

    tryKey(box.Text)
end)

-- ==========================================
-- INICIO
-- ==========================================

-- No leer POLAHACK.key.
-- No cargar keys guardadas.
-- No verificar automaticamente.
-- Solo verificar al presionar Enter
-- o al completar la sesion de anuncio.

say("Toca el boton para obtener tu key.")
