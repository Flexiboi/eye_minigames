local isActive = false
local activeCb = nil
local activeNonce = nil

local nonceCounter = 0
local function makeNonce()
    nonceCounter = nonceCounter + 1
    local parts = {
        tostring(GetGameTimer()),
        tostring(math.random(100000, 999999)),
        tostring(math.random(100000, 999999)),
        tostring(nonceCounter)
    }
    return table.concat(parts, '-')
end

local function merge(a, b)
    local out = {}
    for k, v in pairs(a or {}) do out[k] = v end
    for k, v in pairs(b or {}) do out[k] = v end
    return out
end

local disableControlls = false
function DisableAnimCancel(state)
    disableControlls = state
    if state then
        CreateThread(function()
            while disableControlls do
                DisableAllControlActions(0)
                Wait(1)
            end
        end)
    else
        disableControlls = false
    end
end

local function finish(success)
    LocalPlayer.state:set('invBusy', false, true)
    if DuiSync and type(DuiSync.stopController) == 'function' then 
        DuiSync.stopController() 
    end

    if not isActive then
        SetNuiFocus(false, false)
        return
    end
    isActive = false
    activeNonce = nil

    SendNUIMessage({ action = 'close' })

    SetNuiFocus(false, false)
    if Config.FreezePlayer then
        FreezeEntityPosition(PlayerPedId(), false)
    end

    local cb = activeCb
    activeCb = nil
    if cb then cb(success and true or false) end
end

local function Start(game, opts, cb)
    if isActive then
        if cb then cb(false) end
        return
    end
    LocalPlayer.state:set('invBusy', true, true)
    game = string.lower(game or '')
    local defaults = Config.Defaults[game]
    if not defaults then
        print(('[eye_minigames] unknown game id: "%s"'):format(game))
        if cb then cb(false) end
        return
    end

    local payload = merge(defaults, opts)
    payload.game = game
    payload.theme = nil

    if payload.allowCancel == nil then
        payload.allowCancel = Config.AllowCancelByDefault
    end
    if payload.sound == nil then payload.sound = Config.Sound end
    if payload.volume == nil then payload.volume = Config.Volume end

    isActive = true
    activeCb = cb
    activeNonce = makeNonce()
    payload.nonce = activeNonce

    if Config.FreezePlayer then
        FreezeEntityPosition(PlayerPedId(), true)
    end

    local openNormal

    local function openController(sessionId, seed)
        if not isActive or activeNonce == nil then return end
        payload.duiSession = sessionId
        payload.duiSeed = seed
        payload.duiController = false
        payload.duiPreview = false
        payload.captureOnly = false
        payload.duiMode = true
        SetNuiFocus(false, false)
        CreateThread(function()
            Wait(150)
            if not isActive or activeNonce == nil then return end
            DuiSync.sendToPage({ action = 'open', payload = payload })
        end)
    end

    openNormal = function()
        if not isActive then return end
        SetNuiFocus(true, true)
        payload.duiSession = nil
        payload.duiSeed = nil
        payload.duiController = false
        payload.captureOnly = false
        SendNUIMessage({ action = 'open', payload = payload })
    end

    if payload.dui == true then
        if not DuiSync or not DuiSync.hasValidConfig(payload) then
            print('[eye_minigames] DUI requested but no valid prop or two-coordinate configuration was supplied')
            isActive = false
            activeCb = nil
            activeNonce = nil
            SetNuiFocus(false, false)
            if Config.FreezePlayer then
                FreezeEntityPosition(PlayerPedId(), false)
            end
            if cb then cb(false) end
            return
        end

        DuiSync.beginController(payload, openController, function()
            if isActive then
                if DuiSync then DuiSync.stopController() end
                isActive = false
                activeNonce = nil
                SetNuiFocus(false, false)
                if Config.FreezePlayer then
                    FreezeEntityPosition(PlayerPedId(), false)
                end
                local doneCb = activeCb
                activeCb = nil
                if doneCb then doneCb(false) end
            end
        end)
    elseif DuiSync and DuiSync.hasValidConfig(payload) then
        DuiSync.beginController(payload, openController, openNormal)
    else
        openNormal()
    end
end

-- Keep FiveM control/key mappings from leaking through while a minigame is active.
-- DUI cursor mode has its own control loop, but this also covers the short startup
-- window and resources whose keybinds are registered outside the normal control path.
CreateThread(function()
    while true do
        if isActive then
            DisableAllControlActions(0)
            DisableAllControlActions(1)
            DisableAllControlActions(2)
        end
        Wait(0)
    end
end)

local function Play(game, opts)
    LocalPlayer.state:set('invBusy', true, true)
    local done, result = false, false
    Start(game, opts, function(ok)
        result = ok
        done = true
    end)
    while not done do Wait(0) end
    return result
end

local function PlayChain(games, opts)
    opts = opts or {}
    local stopOnFail = opts.stopOnFail
    if stopOnFail == nil then stopOnFail = true end
    local total = #games
    local completed = 0
    LocalPlayer.state:set('invBusy', true, true)
    for i = 1, total do
        local stage = games[i]
        local id, stageOpts
        if type(stage) == 'table' then
            id = stage.game or stage[1]
            stageOpts = merge(opts, stage)
            stageOpts.game = nil
        else
            id = stage
            stageOpts = merge(opts, {})
        end

        local ok = Play(id, stageOpts)
        if ok then
            completed = completed + 1
        elseif stopOnFail then
            return false, completed, total
        end
        if i < total then Wait(opts.failDelay or 250) end
    end

    return completed == total, completed, total
end

local function parseNumber(v)
    return tonumber(v)
end

local function parseVec4(value)
    if type(value) ~= 'string' then return nil end

    local x, y, z, w = value:match(
        '[Vv][Ee][Cc][Tt][Oo][Rr]4%s*%(%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)%s*%)'
    )

    if not x then
        x, y, z, w = value:match(
            '[Vv]4%s*%(%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)%s*%)'
        )
    end

    if not x then
        return nil
    end

    return vector4(
        tonumber(x),
        tonumber(y),
        tonumber(z),
        tonumber(w)
    )
end

local function testCommandEnabled()
    return Config.EnableTestCommands ~= false
end

local function testPrint(msg)
    print(('^3[eye_minigames]^7 %s'):format(msg))
end

local RESOURCE_NAME = GetCurrentResourceName()

if Config.EnableTestCommands ~= false then
    RegisterCommand('mg', function(_, args)
        local game = string.lower(args[1] or '')
        if game == '' then
            testPrint('Usage: /mg <game> [difficulty] [topLeft vector4] [bottomRight vector4]')
            return
        end

        local difficulty = tonumber(args[2]) or nil
        local opts = {}
        if difficulty then opts.difficulty = difficulty end

        local topLeft = parseVec4(args[3] or '')
        local bottomRight = parseVec4(args[4] or '')

        if (topLeft and not bottomRight) or (bottomRight and not topLeft) then
            testPrint('Both topLeft and bottomRight must be valid vector4(...) values.')
            return
        end

        if topLeft and bottomRight then
            opts.topLeft = topLeft
            opts.bottomRight = bottomRight
            opts.dui = true
            testPrint(('Starting world DUI test: %s'):format(game))
            exports[RESOURCE_NAME]:StartDui(game, opts, function(ok)
                testPrint(('world DUI result: %s'):format(tostring(ok)))
            end)
            return
        end

        testPrint(('Starting normal NUI test: %s'):format(game))
        exports[RESOURCE_NAME]:Start(game, opts, function(ok)
            testPrint(('normal NUI result: %s'):format(tostring(ok)))
        end)
    end, false)

    RegisterCommand('mgdui', function(_, args)
        local game = string.lower(args[1] or '')
        local difficulty = tonumber(args[2]) or 2
        local topLeft = parseVec4(args[3] or '')
        local bottomRight = parseVec4(args[4] or '')

        if game == '' or not topLeft or not bottomRight then
            testPrint('Usage: /mgdui <game> <difficulty> vector4(x,y,z,heading) vector4(x,y,z,heading)')
            return
        end

        local opts = {
            difficulty = difficulty,
            topLeft = topLeft,
            bottomRight = bottomRight,
            dui = true
        }

        testPrint(('Starting two-coordinate DUI: %s'):format(game))
        exports[RESOURCE_NAME]:StartDui(game, opts, function(ok)
            testPrint(('DUI result: %s'):format(tostring(ok)))
        end)
    end, false)

    RegisterCommand('mgduiprop', function(_, args)
        local game = string.lower(args[1] or '')
        local difficulty = tonumber(args[2]) or 2

        if game == '' then
            testPrint('Usage: /mgduiprop <game> [difficulty] [model] [txd] [texture]')
            return
        end

        local cfg = Config.DuiTestProp or {}
        local model = args[3] or cfg.model
        local txd = args[4] or cfg.txd
        local texture = args[5] or cfg.texture

        if not model or not txd or not texture then
            testPrint('Config.DuiTestProp must define model, txd and texture.')
            return
        end

        local ped = PlayerPedId()
        local pc = GetEntityCoords(ped)
        local modelHash = joaat(tostring(model))
        local entity = GetClosestObjectOfType(
            pc.x, pc.y, pc.z, 3.0, modelHash, false, false, false
        )

        if not entity or entity == 0 or not DoesEntityExist(entity) then
            testPrint(('No %s prop found within 3 metres.'):format(tostring(model)))
            return
        end

        local ec = GetEntityCoords(entity)
        local er = GetEntityRotation(entity, 2)

        local opts = {
            difficulty = difficulty,
            prop = {
                entity = entity,
                model = model,
                coords = vector4(ec.x, ec.y, ec.z, GetEntityHeading(entity)),
                txd = txd,
                texture = texture,
                screenWidth = tonumber(cfg.screenWidth) or 0.60,
                screenHeight = tonumber(cfg.screenHeight) or 0.34,
                screenOffset = cfg.screenOffset or vector3(0.0, 0.0, 0.0),
                uv = cfg.uv,
                camera = cfg.camera ~= false,
                cameraDistance = tonumber(cfg.cameraDistance) or 1.0,
                cameraHeight = tonumber(cfg.cameraHeight) or 0.0,
                cameraFov = tonumber(cfg.cameraFov) or 40.0,
                cameraSide = tonumber(cfg.cameraSide) or 1.0,
                cameraOffset = cfg.cameraOffset,
                cameraTargetOffset = cfg.cameraTargetOffset
            },
            dui = true
        }

        testPrint(('Starting prop DUI: entity=%s model=%s txd=%s texture=%s'):format(
            tostring(entity), tostring(model), tostring(txd), tostring(texture)
        ))

        exports[RESOURCE_NAME]:StartDui(game, opts, function(ok)
            testPrint(('prop DUI result: %s'):format(tostring(ok)))
        end)
    end, false)

    RegisterCommand('mgduistop', function()
        if DuiSync then
            DuiSync.stopController()
        end
        finish(false)
        testPrint('Stopped active minigame/DUI.')
    end, false)

    RegisterCommand('mgduidebug', function()
        if not DuiSync then
            testPrint('DuiSync is nil: client/dui.lua failed to load.')
            return
        end

        testPrint(('active=%s session=%s handle=%s'):format(
            tostring(DuiSync.isActive),
            tostring(DuiSync.sessionId),
            tostring(DuiSync.handle ~= nil)
        ))

        if DuiSync.handle then
            testPrint(('dui alive=%s available=%s size=%sx%s attached=%s'):format(
                tostring(DuiSync.handle.dui ~= nil),
                tostring(DuiSync.handle.dui ~= nil and IsDuiAvailable(DuiSync.handle.dui)),
                tostring(DuiSync.handle.width),
                tostring(DuiSync.handle.height),
                tostring(DuiSync.handle.attached)
            ))
            testPrint(('runtime txd=%s txn=%s'):format(
                tostring(DuiSync.handle.txd),
                tostring(DuiSync.handle.txn)
            ))
        end

        testPrint(('replacing txd=%s texture=%s on entity=%s'):format(
            tostring(DuiSync.txd),
            tostring(DuiSync.texture),
            tostring(DuiSync.propEntity)
        ))

        testPrint(('cursor loop active=%s, raw key natives=%s'):format(
            tostring(_G.DuiCursor and _G.DuiCursor.IsActive()),
            tostring(IsRawKeyDown ~= nil)
        ))
    end, false)

    RegisterCommand('mgduitex', function(_, args)
        local model = args[1]
        local txd = args[2] or model
        local texture = args[3]

        if not model or not texture then
            testPrint('Usage: /mgduitex <model> <txd> <texture>')
            return
        end

        local DuiCursor = _G.DuiCursor
        if not DuiCursor then
            testPrint('DuiCursor not loaded.')
            return
        end

        local ped = PlayerPedId()
        local pc = GetEntityCoords(ped)
        local hash = joaat(model)
        local found = 0

        for _, isMission in ipairs({ true, false }) do
            found = GetClosestObjectOfType(pc.x, pc.y, pc.z, 8.0, hash, isMission, false, false)
            if found and found ~= 0 then break end
        end

        if not found or found == 0 then
            for _, obj in ipairs(GetGamePool('CObject')) do
                if GetEntityModel(obj) == hash then found = obj break end
            end
        end

        testPrint(('prop "%s" nearby: %s'):format(model,
            (found and found ~= 0) and ('yes (entity ' .. found .. ')') or 'NO'))

        local page = 'data:text/html,<html><body style="margin:0;background:%23ff00ff;' ..
            'color:%23000;font:700 44px sans-serif;display:flex;align-items:center;' ..
            'justify-content:center;text-align:center">TXD OK</body></html>'

        local handle = DuiCursor.Create(page, 512, 512)
        if not handle then
            testPrint('Could not create the test DUI.')
            return
        end

        CreateThread(function()
            if not DuiCursor.Attach(handle, txd, texture, 5000) then
                testPrint('Test DUI never painted, aborting.')
                DuiCursor.Destroy(handle)
                return
            end

            testPrint(('Replaced %s / %s. Look at the prop now.'):format(txd, texture))
            testPrint('Magenta = pair is correct. Unchanged = pair is wrong.')
            testPrint('Reverting in 20 seconds.')

            Wait(20000)

            DuiCursor.Detach(handle, txd, texture)
            DuiCursor.Destroy(handle)
            testPrint('Test texture removed.')
        end)
    end, false)

    RegisterCommand('mgduiscan', function(_, args)
        local model = args[1]

        if not model then
            testPrint('Usage: /mgduiscan <model> [txd] [comma,separated,textures]')
            return
        end

        local DuiCursor = _G.DuiCursor
        if not DuiCursor then
            testPrint('DuiCursor not loaded.')
            return
        end

        local txd = args[2] or model

        local textures = {}
        if args[3] then
            for name in tostring(args[3]):gmatch('[^,]+') do
                textures[#textures + 1] = name:gsub('^%s+', ''):gsub('%s+$', '')
            end
        else
            textures = {
                'phone_screen', 'phonescreen', 'screen', 'Screen',
                'p_phone_screen', 'phone_scr', 'phone_01_screen',
                'prologue_phone_screen', 'p_prologue_phone_screen',
                'screen_01', 'phone_screen_01', 'cellphone_screen',
                'phone_diffuse', 'phone', model
            }
        end

        local page = 'data:text/html,<html><body style="margin:0;background:%23ff00ff">' ..
            '</body></html>'

        local handle = DuiCursor.Create(page, 256, 256)
        if not handle then
            testPrint('Could not create the scan DUI.')
            return
        end

        CreateThread(function()
            local deadline = GetGameTimer() + 5000
            while not DuiCursor.Available(handle) do
                if GetGameTimer() > deadline then
                    testPrint('Scan DUI never painted, aborting.')
                    DuiCursor.Destroy(handle)
                    return
                end
                Wait(50)
            end
            Wait(300)

            testPrint(('Scanning txd "%s", %d candidates. Watch the prop.'):format(txd, #textures))

            for i, texture in ipairs(textures) do
                AddReplaceTexture(txd, texture, handle.txd, handle.txn)
                testPrint(('  [%d/%d] %s / %s'):format(i, #textures, txd, texture))

                Wait(2500)

                RemoveReplaceTexture(txd, texture)
                Wait(100)
            end

            DuiCursor.Destroy(handle)
            testPrint('Scan finished. Note the number that turned the screen magenta.')
            testPrint('If none did, the TXD name is wrong, not the texture name.')
        end)
    end, false)

    RegisterCommand('mgduiscantxd', function(_, args)
        local texture = args[1]

        if not texture then
            testPrint('Usage: /mgduiscantxd <texture> [comma,separated,txds]')
            return
        end

        local DuiCursor = _G.DuiCursor
        if not DuiCursor then
            testPrint('DuiCursor not loaded.')
            return
        end

        local txds = {}
        if args[2] then
            for name in tostring(args[2]):gmatch('[^,]+') do
                txds[#txds + 1] = name:gsub('^%s+', ''):gsub('%s+$', '')
            end
        else
            txds = {
                'prop_prologue_phone', 'prop_npc_phone', 'prop_npc_phone_02',
                'prop_phone_ing', 'prop_amb_phone', 'prop_cs_phone',
                'phone_screen', 'prop_phone'
            }
        end

        local handle = DuiCursor.Create(
            'data:text/html,<html><body style="margin:0;background:%23ff00ff"></body></html>',
            256, 256
        )
        if not handle then
            testPrint('Could not create the scan DUI.')
            return
        end

        CreateThread(function()
            local deadline = GetGameTimer() + 5000
            while not DuiCursor.Available(handle) do
                if GetGameTimer() > deadline then
                    DuiCursor.Destroy(handle)
                    testPrint('Scan DUI never painted, aborting.')
                    return
                end
                Wait(50)
            end
            Wait(300)

            testPrint(('Scanning %d txds against texture "%s". Watch the prop.'):format(#txds, texture))

            for i, txd in ipairs(txds) do
                AddReplaceTexture(txd, texture, handle.txd, handle.txn)
                testPrint(('  [%d/%d] %s / %s'):format(i, #txds, txd, texture))

                Wait(2500)

                RemoveReplaceTexture(txd, texture)
                Wait(100)
            end

            DuiCursor.Destroy(handle)
            testPrint('Scan finished.')
        end)
    end, false)

    RegisterCommand('mgduilog', function()
        if not _G.DuiCursor then
            testPrint('DuiCursor not loaded.')
            return
        end

        _G.DuiCursor.debug = not _G.DuiCursor.debug
        testPrint(('DUI cursor logging %s'):format(_G.DuiCursor.debug and 'ON' or 'OFF'))
    end, false)
end

exports('Start', Start)
exports('Play', Play)
exports('PlayChain', PlayChain)

RegisterNUICallback('result', function(data, cb)
    cb('ok')
    if not isActive then return end
    if not data or data.nonce ~= activeNonce then
        print('[eye_minigames] rejected result with invalid/missing token')
        return
    end
    finish(data.success)
end)

AddEventHandler('eye_minigames:dui:cancel', function()
    if isActive then finish(false) end
end)

RegisterNetEvent('eye_minigames:dui:result', function(sessionId, success)
    if not isActive then return end
    if DuiSync and DuiSync.sessionId and sessionId ~= DuiSync.sessionId then return end
    finish(success == true)
end)

RegisterNetEvent('eye_minigames:dui:closed', function(sessionId)
    if not isActive then return end
    if DuiSync and DuiSync.sessionId and sessionId ~= DuiSync.sessionId then return end
    finish(false)
end)

RegisterNUICallback('duiClock', function(data, cb)
    cb('ok')
    if not isActive or not DuiSync or not DuiSync.controllerSession then return end
    if type(data) ~= 'table' then return end
    DuiSync.forwardClock(data)
end)

RegisterNUICallback('closed', function(data, cb)
    cb('ok')
    if type(data) ~= 'table' then data = {} end
    if data.nonce and activeNonce and data.nonce ~= activeNonce then return end
    if DuiSync and type(DuiSync.stopController) == 'function' then
        DuiSync.stopController()
    end
    if isActive then
        finish(false)
    else
        SetNuiFocus(false, false)
        if Config.FreezePlayer then
            FreezeEntityPosition(PlayerPedId(), false)
        end
    end
end)
