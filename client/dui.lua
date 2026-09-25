local RESOURCE_NAME = GetCurrentResourceName()

local DuiCursor = _G.DuiCursor

if type(DuiCursor) ~= 'table' then
    print('[DUI] FATAL: duicursor.lua did not load.')
    print('[DUI] client/duicursor.lua must be listed BEFORE client/dui.lua in fxmanifest.lua')
    return
end

print('[DUI] DuiCursor loaded successfully!')

DuiCursor.debug = Config.DuiDebug == true

DuiSync = {
    handle = nil,
    isActive = false,
    sessionId = nil,
    propEntity = nil,
    model = nil,
    txd = nil,
    texture = nil,
    cameraDistance = tonumber(Config.DuiCameraDistance) or 1.0,
    cameraHeight = tonumber(Config.DuiCameraHeight) or 0.0,
    cameraFov = tonumber(Config.DuiCameraFov) or 40.0,
    cameraSide = tonumber(Config.DuiCameraSide) or 1.0,
    _pending = nil
}

local DUI_WIDTH = math.max(320, math.floor(tonumber(Config.DuiWidth) or 1280))
local DUI_HEIGHT = math.max(180, math.floor(tonumber(Config.DuiHeight) or 720))
local EPSILON = 0.0001

local function clamp(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
end

local function dot(a, b)
    return a.x * b.x + a.y * b.y + a.z * b.z
end

local function cross(a, b)
    return vector3(
        a.y * b.z - a.z * b.y,
        a.z * b.x - a.x * b.z,
        a.x * b.y - a.y * b.x
    )
end

local function length(v)
    return math.sqrt(dot(v, v))
end

local function normalize(v)
    local len = length(v)
    if len <= EPSILON then return vector3(0.0, 0.0, 0.0) end
    return v / len
end

local function propData(payload)
    if type(payload) ~= 'table' or type(payload.prop) ~= 'table' then return nil end
    local prop = payload.prop
    if not prop.coords or not prop.texture or not prop.txd then return nil end

    return {
        model = prop.model,
        entity = tonumber(prop.entity),
        coords = vector3(prop.coords.x, prop.coords.y, prop.coords.z),
        heading = tonumber(prop.coords.w) or tonumber(prop.heading) or 0.0,
        txd = tostring(prop.txd),
        texture = tostring(prop.texture),
        camera = prop.camera ~= false,
        cameraDistance = tonumber(prop.cameraDistance) or DuiSync.cameraDistance,
        cameraHeight = tonumber(prop.cameraHeight) or 0.0,
        cameraFov = tonumber(prop.cameraFov) or DuiSync.cameraFov,
        cameraSide = tonumber(prop.cameraSide) or DuiSync.cameraSide,
        screenWidth = tonumber(prop.screenWidth) or 0.60,
        screenHeight = tonumber(prop.screenHeight) or 0.34,
        screenOffset = prop.screenOffset and vector3(prop.screenOffset.x or 0.0, prop.screenOffset.y or 0.0, prop.screenOffset.z or 0.0) or vector3(0.0, 0.0, 0.0),
        searchRadius = tonumber(prop.searchRadius) or 3.0,
        uv = type(prop.uv) == 'table' and prop.uv or {},
        duiWidth = math.max(320, math.floor(tonumber(prop.resW or prop.duiWidth) or DUI_WIDTH)),
        duiHeight = math.max(180, math.floor(tonumber(prop.resH or prop.duiHeight) or DUI_HEIGHT))
    }
end

local function findPropEntity(p)
    if p.entity and p.entity ~= 0 and DoesEntityExist(p.entity) then
        return p.entity
    end

    if not p.model then return 0 end
    local model = type(p.model) == 'number' and p.model or joaat(p.model)
    local radius = tonumber(p.searchRadius) or 3.0

    for _, isMission in ipairs({ true, false }) do
        local entity = GetClosestObjectOfType(
            p.coords.x, p.coords.y, p.coords.z, radius, model, isMission, false, false
        )
        if entity and entity ~= 0 and DoesEntityExist(entity) then
            return entity
        end
    end

    local best, bestDist = 0, radius

    for _, obj in ipairs(GetGamePool('CObject')) do
        if DoesEntityExist(obj) and GetEntityModel(obj) == model then
            local dist = #(GetEntityCoords(obj) - p.coords)
            if dist <= bestDist then
                best, bestDist = obj, dist
            end
        end
    end

    if best == 0 then
        print(('[DUI] no "%s" found within %.1fm of the supplied coords.')
            :format(tostring(p.model), radius))
        print('[DUI] If another resource spawns this prop, pass its handle as prop.entity.')
    end

    return best
end

local function apiBase()
    local endpoint = GetCurrentServerEndpoint()
    if type(endpoint) ~= 'string' or endpoint == '' then return '' end
    return ('http://%s/%s'):format(endpoint, RESOURCE_NAME)
end

local function buildDuiUrl(sessionId)
    return ('nui://%s/html/index.html?dui=1&session=%s&resource=%s&api=%s'):format(
        RESOURCE_NAME,
        tostring(sessionId),
        RESOURCE_NAME,
        apiBase()
    )
end

local function sendDuiInit(handle, sessionId)
    if not handle then return end

    local message = {
        action = 'duiInit',
        dui = true,
        session = tostring(sessionId),
        resource = RESOURCE_NAME,
        api = apiBase()
    }

    DuiCursor.Send(handle, message)

    CreateThread(function()
        for _ = 1, 4 do
            Wait(250)
            if not handle.dui then return end
            DuiCursor.Send(handle, message)
        end
    end)
end

function DuiSync.createDui(sessionId, width, height)
    if not DuiCursor then
        print('[DUI] ERROR: DuiCursor not available!')
        return nil
    end
    
    if DuiSync.handle then
        DuiCursor.Destroy(DuiSync.handle)
        DuiSync.handle = nil
    end

    local url = buildDuiUrl(sessionId)
    print(('[DUI] Creating DUI with URL: %s'):format(url))
    print(('[DUI] Size: %sx%s'):format(width, height))

    local handle = DuiCursor.Create(url, width, height)
    if not handle then
        print('[DUI] FAILED: DuiCursor.Create returned nil')
        return nil
    end

    DuiCursor.Blank(handle)
    print(('[DUI] DUI Created with handle: %s'):format(tostring(handle)))

    return handle
end

local function vectorAdd(a, b)
    return vector3(a.x + b.x, a.y + b.y, a.z + b.z)
end

local function vectorSub(a, b)
    return vector3(a.x - b.x, a.y - b.y, a.z - b.z)
end

local function vectorMul(a, n)
    return vector3(a.x * n, a.y * n, a.z * n)
end

local function buildWorldPanel(topLeft, bottomRight)
    if not topLeft or not bottomRight then return nil end

    local h = tonumber(topLeft.w) or 0.0
    local radH = math.rad(h)

    local facing = vector3(-math.sin(radH), math.cos(radH), 0.0)
    local rightDir = vector3(math.cos(radH), math.sin(radH), 0.0)

    local diagonal = vectorSub(bottomRight, topLeft)
    local width = math.abs(dot(diagonal, rightDir))
    local height = math.abs(diagonal.z)

    if width < EPSILON then
        width = math.sqrt(diagonal.x * diagonal.x + diagonal.y * diagonal.y)
    end
    if height < EPSILON then
        local planar = math.sqrt(diagonal.x * diagonal.x + diagonal.y * diagonal.y)
        if planar > EPSILON and width > EPSILON then
            height = math.max(0.01, math.abs(diagonal.z))
        end
    end

    if width < 0.01 or height < 0.01 then
        return nil
    end

    local right = vectorMul(rightDir, width)
    local down = vector3(0.0, 0.0, -height)

    local center = vector3(
        (topLeft.x + bottomRight.x) * 0.5,
        (topLeft.y + bottomRight.y) * 0.5,
        (topLeft.z + bottomRight.z) * 0.5
    )

    local origin = center - vectorMul(right, 0.5) - vectorMul(down, 0.5)

    return {
        origin = origin,
        right = right,
        down = down,
        facing = facing,
        width = width,
        height = height
    }
end

local function buildPropPanel(prop, pData)
    local coords = GetEntityCoords(prop)

    local forward, rightDir, upDir, matrixPos = GetEntityMatrix(prop)

    if not forward or not rightDir or not upDir then
        forward = vector3(0.0, 1.0, 0.0)
        rightDir = vector3(1.0, 0.0, 0.0)
        upDir = vector3(0.0, 0.0, 1.0)
    end

    local width = math.max(0.01, tonumber(pData.screenWidth) or 0.60)
    local height = math.max(0.01, tonumber(pData.screenHeight) or 0.34)

    local offset = pData.screenOffset or vector3(0.0, 0.0, 0.0)
    local center = coords
    center = vectorAdd(center, vectorMul(rightDir, offset.x or 0.0))
    center = vectorAdd(center, vectorMul(forward, offset.y or 0.0))
    center = vectorAdd(center, vectorMul(upDir, offset.z or 0.0))

    local facing = vectorMul(forward, -1.0)
    if (DuiSync.cameraSide or 1.0) < 0 then
        facing = vectorMul(facing, -1.0)
    end

    local right = vectorMul(rightDir, width)
    local down = vectorMul(upDir, -height)

    return {
        origin = center - vectorMul(right, 0.5) - vectorMul(down, 0.5),
        right = right,
        down = down,
        facing = facing,
        width = width,
        height = height
    }
end

local lastCursorForward = 0
local CURSOR_FORWARD_MS = 100

local function controllerInput(data)
    if not DuiSync.isActive or not DuiSync.sessionId then return end

    if type(data) == 'table' and data.action == 'cursorMove' then
        local now = GetGameTimer()
        if now - lastCursorForward < CURSOR_FORWARD_MS then return end
        lastCursorForward = now
    end

    TriggerServerEvent('eye_minigames:dui:input', DuiSync.sessionId, data)
end

local function makeCursorOptions(payload)
    local p = payload or {}
    local opts = {
        fov = tonumber(p.cameraFov) or DuiSync.cameraFov or 40.0,
        keys = true,
        wheelStep = 120,
        exitOnBack = false,
        sensitivity = p.duiSensitivity,
        sensitivityScale = tonumber(p.duiSensitivityScale) or 1.0,
        onInput = controllerInput,
    }

    if p.prop then
        opts.fov = tonumber(p.prop.cameraFov) or opts.fov
        opts.sensitivity = tonumber(p.prop.sensitivity) or opts.sensitivity
        opts.sensitivityScale = tonumber(p.prop.sensitivityScale) or opts.sensitivityScale
        opts.invertWheel = p.prop.invertWheel == true
    end

    opts.onClick = function(x, y)
        TriggerEvent('eye_minigames:dui:click', x, y, DuiSync.sessionId)
    end

    return opts
end

local function waitForDui(handle, timeout)
    local deadline = GetGameTimer() + (timeout or 5000)
    while handle and handle.dui and not DuiCursor.Available(handle) do
        if GetGameTimer() > deadline then return false end
        Wait(50)
    end
    return handle and handle.dui ~= nil and DuiCursor.Available(handle)
end

function DuiSync.startAsPanel(payload, onStarted, onRejected)
    local p = payload or {}
    local topLeft = p.topLeft
    local bottomRight = p.bottomRight

    local panel = buildWorldPanel(topLeft, bottomRight)
    if not panel then
        print('[DUI] Invalid topLeft/bottomRight panel geometry')
        if onRejected then onRejected() end
        return false
    end

    local width = math.max(320, math.floor(tonumber(p.duiWidth or p.resW) or DUI_WIDTH))
    local height = math.max(180, math.floor(tonumber(p.duiHeight or p.resH) or DUI_HEIGHT))
    if DuiSync.handle then
        print('[DUI] destroying an orphaned DUI handle before creating a new one')
        if DuiSync.handle.attached and DuiSync.txd and DuiSync.texture then
            DuiCursor.Detach(DuiSync.handle, DuiSync.txd, DuiSync.texture)
        end
        DuiCursor.Destroy(DuiSync.handle)
        DuiSync.handle = nil
    end

    local url = buildDuiUrl(p.sessionId)
    local handle = DuiCursor.Create(url, width, height)

    if not handle then
        print('[DUI] Failed to create world DUI')
        if onRejected then onRejected() end
        return false
    end

    DuiSync.handle = handle
    DuiSync.propEntity = nil
    DuiSync.model = nil
    DuiSync.txd = nil
    DuiSync.texture = nil

    local function reject()
        if handle then DuiCursor.Destroy(handle) end
        if DuiSync.handle == handle then DuiSync.handle = nil end
        if onRejected then onRejected() end
    end

    if not waitForDui(handle, 5000) then
        print('[DUI] World DUI did not become available')
        reject()
        return false
    end

    DuiCursor.Restore(handle)

    p.duiApi = apiBase()
    sendDuiInit(handle, p.sessionId)

    local opts = makeCursorOptions(p)
    opts.fov = tonumber(p.cameraFov) or DuiSync.cameraFov
    opts.fill = tonumber(p.duiFill) or 0.90
    opts.camDistance = tonumber(p.cameraDistance) or tonumber(p.duiCameraDistance)
    opts.camera = p.camera ~= false
    opts.onInput = controllerInput

    DuiCursor.StartPanel(handle, panel, function()
        DuiSync.stopController()
        TriggerEvent('eye_minigames:dui:cancel')
    end, opts)

    DuiSync.isActive = true
    DuiSync.sessionId = p.sessionId

    CreateThread(function()
        while DuiSync.isActive and DuiSync.handle == handle and handle.dui do
            DuiCursor.DrawPanel(handle, panel)
            Wait(0)
        end
    end)

    if onStarted then onStarted(p.sessionId) end
    return true
end

function DuiSync.startOnProp(payload, onStarted, onRejected)
    local pData = propData(payload)
    if not pData then
        print('[DUI] Invalid prop data in payload')
        if onRejected then onRejected() end
        return false
    end

    local width = pData.duiWidth or DUI_WIDTH
    local height = pData.duiHeight or DUI_HEIGHT
    if DuiSync.handle then
        print('[DUI] destroying an orphaned DUI handle before creating a new one')
        if DuiSync.handle.attached and DuiSync.txd and DuiSync.texture then
            DuiCursor.Detach(DuiSync.handle, DuiSync.txd, DuiSync.texture)
        end
        DuiCursor.Destroy(DuiSync.handle)
        DuiSync.handle = nil
    end

    local url = buildDuiUrl(payload.sessionId)
    local handle = DuiCursor.Create(url, width, height)

    if not handle then
        print('[DUI] Failed to create prop DUI')
        if onRejected then onRejected() end
        return false
    end

    DuiSync.handle = handle

    local prop = pData.entity or findPropEntity(pData)
    if not prop or prop == 0 or not DoesEntityExist(prop) then
        print(('[DUI] Could not find prop "%s" near %.2f %.2f %.2f'):format(
            tostring(pData.model), pData.coords.x, pData.coords.y, pData.coords.z
        ))
        print('[DUI] Pass prop.entity if another resource owns the object, or raise prop.searchRadius.')
        DuiCursor.Destroy(handle)
        DuiSync.handle = nil
        if onRejected then onRejected() end
        return false
    end

    if Config.DuiDebug then
        print(('[DUI] prop entity %s, replacing txd "%s" texture "%s" with %dx%d DUI')
            :format(tostring(prop), tostring(pData.txd), tostring(pData.texture), width, height))
        print('[DUI] If the screen stays black, verify that pair with /mgduitex')
    end

    if not waitForDui(handle, 5000) then
        print('[DUI] Prop DUI did not become available')
        DuiCursor.Destroy(handle)
        DuiSync.handle = nil
        if onRejected then onRejected() end
        return false
    end

    if not DuiCursor.Attach(handle, pData.txd, pData.texture, 5000) then
        print(('[DUI] Prop DUI texture attach failed (txd=%s texture=%s)'):format(
            tostring(pData.txd), tostring(pData.texture)
        ))
        DuiCursor.Destroy(handle)
        DuiSync.handle = nil
        if onRejected then onRejected() end
        return false
    end

    payload.duiApi = apiBase()
    sendDuiInit(handle, payload.sessionId)

    DuiSync.propEntity = prop
    DuiSync.model = pData.model
    DuiSync.txd = pData.txd
    DuiSync.texture = pData.texture

    local panel = buildPropPanel(prop, pData)
    if not panel then
        DuiCursor.Detach(handle)
        DuiCursor.Destroy(handle)
        DuiSync.handle = nil
        if onRejected then onRejected() end
        return false
    end

    local opts = makeCursorOptions(payload)
    opts.fov = tonumber(pData.cameraFov) or DuiSync.cameraFov
    opts.camDistance = tonumber(pData.cameraDistance) or DuiSync.cameraDistance or 1.0
    opts.camera = pData.camera ~= false
    opts.camOffset = pData.cameraOffset
    opts.targetOffset = pData.cameraTargetOffset
    opts.onInput = controllerInput

    if tonumber(pData.cameraHeight) and tonumber(pData.cameraHeight) ~= 0.0 then
        opts.camOffset = opts.camOffset or vector3(0.0, 0.0, 0.0)
        opts.camOffset = vector3(
            opts.camOffset.x or 0.0,
            (opts.camOffset.y or 0.0),
            (opts.camOffset.z or 0.0) + tonumber(pData.cameraHeight)
        )
    end

    DuiCursor.StartPanel(handle, panel, function()
        DuiSync.stopController()
        TriggerEvent('eye_minigames:dui:cancel')
    end, opts)

    DuiSync.isActive = true
    DuiSync.sessionId = payload.sessionId

    if onStarted then onStarted(payload.sessionId) end
    return true
end

function DuiSync.hasValidConfig(payload)
    if not payload then return false end
    if payload.topLeft ~= nil and payload.bottomRight ~= nil then return true end
    if type(payload.prop) == 'table' then
        local prop = payload.prop
        return prop.texture ~= nil and prop.txd ~= nil and prop.coords ~= nil
    end
    return false
end

local requestCounter = 0
local function nextRequest()
    requestCounter = requestCounter + 1
    return ('dui_req_%s_%s_%s'):format(GetGameTimer(), math.random(100000, 999999), requestCounter)
end

function DuiSync.beginController(payload, onStarted, onRejected)
    print('[DUI] beginController called')
    if not DuiCursor or not DuiSync.hasValidConfig(payload) then
        if onRejected then onRejected() end
        return false
    end

    if payload.sessionId then
        if payload.prop then
            return DuiSync.startOnProp(payload, onStarted, onRejected)
        end
        return DuiSync.startAsPanel(payload, onStarted, onRejected)
    end

    local request = nextRequest()
    DuiSync._pending = {
        request = request,
        onStarted = onStarted,
        onRejected = onRejected,
        payload = payload
    }

    TriggerServerEvent('eye_minigames:dui:start', request, payload)
    return true
end

function DuiSync.activateController(sessionId, payload, seed, onRejected)
    payload = payload or {}
    payload.sessionId = sessionId
    payload.duiSeed = seed

    if DuiSync.isActive and DuiSync.controllerSession == sessionId then
        print('[DUI] activateController called twice for the same session, ignoring the second call')
        return true
    end

    DuiSync.controllerSession = sessionId

    local started
    if payload.prop then
        started = DuiSync.startOnProp(payload, function()
            DuiSync.isActive = true
        end, onRejected)
    else
        started = DuiSync.startAsPanel(payload, function()
            DuiSync.isActive = true
        end, onRejected)
    end

    return started == true
end

function DuiSync.stopController()
    if not DuiCursor then return end

    DuiCursor.Stop()

    if DuiSync.camera then
        RenderScriptCams(false, true, 500, true, true)
        DestroyCam(DuiSync.camera, false)
        DuiSync.camera = nil
    end

    if DuiSync.handle then
        if DuiSync.handle.attached and DuiSync.txd and DuiSync.texture then
            DuiCursor.Detach(DuiSync.handle, DuiSync.txd, DuiSync.texture)
        end
        DuiCursor.Destroy(DuiSync.handle)
        DuiSync.handle = nil
    end

    if DuiSync.sessionId then
        TriggerServerEvent('eye_minigames:dui:stop', DuiSync.sessionId)
    end

    DuiSync.isActive = false
    DuiSync.controllerSession = nil
    DuiSync.sessionId = nil
    DuiSync.propEntity = nil
    DuiSync.model = nil
    DuiSync.txd = nil
    DuiSync.texture = nil
    DuiSync._pending = nil

    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
end

RegisterNetEvent('eye_minigames:dui:started', function(request, sessionId, seed)
    local p = DuiSync._pending
    if not p or p.request ~= request then return end

    local payload = p.payload
    payload.sessionId = sessionId
    payload.duiSeed = seed
    DuiSync._pending = nil

    local ok = DuiSync.activateController(sessionId, payload, seed, p.onRejected)
    if ok then
        if p.onStarted then p.onStarted(sessionId, seed) end
    elseif p.onRejected then
        p.onRejected()
    end
end)

DuiSync._observer = nil

RegisterNetEvent('eye_minigames:dui:observerStart', function(sessionId, payload, seed, history)
    if DuiSync._observer then
        if DuiSync._observer.handle then DuiCursor.Destroy(DuiSync._observer.handle) end
        DuiSync._observer = nil
    end

    payload = payload or {}
    payload.sessionId = sessionId
    payload.duiSeed = seed
    payload.duiPreview = true

    local width = math.max(320, math.floor(tonumber(payload.duiWidth or payload.resW) or DUI_WIDTH))
    local height = math.max(180, math.floor(tonumber(payload.duiHeight or payload.resH) or DUI_HEIGHT))
    local handle = DuiCursor.Create(buildDuiUrl(sessionId), width, height)
    if not handle then return end

    DuiSync._observer = { sessionId = sessionId, handle = handle }
    CreateThread(function()
        if not waitForDui(handle, 5000) then
            DuiCursor.Destroy(handle)
            DuiSync._observer = nil
            return
        end

        local obs = DuiSync._observer
        if payload.prop then
            local prop = payload.prop.entity and tonumber(payload.prop.entity) or findPropEntity(propData(payload) or {})
            if prop and prop ~= 0 and DoesEntityExist(prop) then
                local panel = buildPropPanel(prop, propData(payload))
                if panel then
                    local center = panel.origin + panel.right * 0.5 + panel.down * 0.5
                    local dist = tonumber(payload.prop.cameraDistance) or DuiSync.cameraDistance or 1.0
                    local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
                    SetCamCoord(cam, (center + panel.facing * dist).x, (center + panel.facing * dist).y, (center + panel.facing * dist).z)
                    PointCamAtCoord(cam, center.x, center.y, center.z)
                    SetCamFov(cam, tonumber(payload.prop.cameraFov) or DuiSync.cameraFov)
                    SetCamActive(cam, true)
                    RenderScriptCams(true, true, 500, true, true)
                    obs.camera = cam
                    DuiCursor.StartPanel(handle, panel, nil, { keys = false })
                end
            end
        else
            local panel = buildWorldPanel(payload.topLeft, payload.bottomRight)
            if panel then
                local center = panel.origin + panel.right * 0.5 + panel.down * 0.5
                local dist = tonumber(payload.cameraDistance or payload.duiCameraDistance) or 2.0
                local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
                SetCamCoord(cam, (center + panel.facing * dist).x, (center + panel.facing * dist).y, (center + panel.facing * dist).z)
                PointCamAtCoord(cam, center.x, center.y, center.z)
                SetCamFov(cam, tonumber(payload.cameraFov) or DuiSync.cameraFov)
                SetCamActive(cam, true)
                RenderScriptCams(true, true, 500, true, true)
                obs.camera = cam
                DuiCursor.StartPanel(handle, panel, nil, { keys = false })
            end
        end

        if type(history) == 'table' then
            for _, eventData in ipairs(history) do
                if obs and obs.handle then DuiCursor.Send(obs.handle, eventData) end
            end
        end
    end)
end)

RegisterNetEvent('eye_minigames:dui:observerInput', function(sessionId, eventData)
    local obs = DuiSync._observer
    if not obs or obs.sessionId ~= sessionId or not obs.handle then return end
    DuiCursor.Send(obs.handle, eventData)
end)

RegisterNetEvent('eye_minigames:dui:observerStop', function(sessionId)
    local obs = DuiSync._observer
    if not obs or obs.sessionId ~= sessionId then return end

    DuiCursor.Stop()
    if obs.camera then
        RenderScriptCams(false, true, 500, true, true)
        DestroyCam(obs.camera, false)
    end
    if obs.handle then DuiCursor.Destroy(obs.handle) end
    DuiSync._observer = nil
end)

exports('ObserveDui', function(sessionId)
    if not sessionId then return false end
    TriggerServerEvent('eye_minigames:dui:observe', sessionId)
    return true
end)

exports('StopDuiObserver', function(sessionId)
    TriggerServerEvent('eye_minigames:dui:unobserve', sessionId)
    TriggerEvent('eye_minigames:dui:observerStop', sessionId)
    return true
end)

function DuiSync.sendToPage(data)
    if not DuiCursor then
        print('[DUI] DuiCursor not available')
        return false
    end
    
    if not DuiSync.handle then
        print('[DUI] Cannot send message: No active DUI handle.')
        return false
    end
    return DuiCursor.Send(DuiSync.handle, data)
end

function DuiSync.forwardClock(clockData)
    if not DuiSync.isActive then return end
    DuiSync.sendToPage({ action = 'duiClock', clock = clockData })
    TriggerServerEvent('eye_minigames:dui:clock', DuiSync.sessionId, clockData)
end

RegisterNetEvent('eye_minigames:dui:cancel', function()
    DuiSync.stopController()
    SendNUIMessage({ action = 'close' })
    SetNuiFocus(false, false)
end)

exports('StartDui', function(game, opts, cb)
    local duiOpts = opts or {}
    duiOpts.dui = true
    return exports[RESOURCE_NAME]:Start(game, duiOpts, cb)
end)

exports('PlayDui', function(game, opts)
    local duiOpts = opts or {}
    duiOpts.dui = true
    return exports[RESOURCE_NAME]:Play(game, duiOpts)
end)

exports('SetDuiCameraDistance', function(dist)
    dist = tonumber(dist)
    if not dist or dist <= 0.01 then return false end
    DuiSync.cameraDistance = dist
    return true
end)

exports('SetDuiCameraHeight', function(height)
    height = tonumber(height)
    if not height then return false end
    DuiSync.cameraHeight = height
    return true
end)

exports('SetDuiCameraFov', function(fov)
    fov = tonumber(fov)
    if not fov or fov <= 1 or fov >= 170 then return false end
    DuiSync.cameraFov = fov
    return true
end)

exports('SetDuiCameraSide', function(side)
    side = tonumber(side)
    if not side or side == 0 then return false end
    DuiSync.cameraSide = side >= 0 and 1 or -1
    return true
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= RESOURCE_NAME then return end
    if DuiSync.isActive then
        DuiSync.stopController()
    end
end)

_G.DuiSync = DuiSync