---@class DuiCursor
DuiCursor = {}

DuiCursor.debug = false

---@alias DuiCursorIdle
---| '"detach"' take it off the prop, leave the browser running. default, re entry is instant
---| '"keep"' leave it on and running. for when something else, like a distance loop, owns attach/detach
---| '"blank"' take it off AND stop the browser on about:blank. cheapest by far, but you lose page state and pay a reload

---@class DuiCursorOptions
---@field onClick? fun(x: number, y: number) left click, position in 0..1. hit test your own rects in here, lua already knows the pixel
---@field keys? boolean forward the keyboard to the page, on by default
---@field wheelStep? number pixels per wheel notch, default 120
---@field invertWheel? boolean flip the scroll direction if your build has the wheel controls the other way round
---@field exitOnBack? boolean also leave on BACKSPACE. off, because backspace belongs to the page
---@field sensitivity? number fixed cursor speed. leave it out and it follows the players own mouse sensitivity
---@field sensitivityScale? number multiplier on the players setting, default 1.0. ignored if sensitivity is set
---@field fov? number cam fov, default 50
---@field fill? number how much of the view the screen fills, default 0.75 on a prop and 0.85 on a panel
---@field camDistance? number prop mode, overrides the distance worked out from the props bounding box
---@field camHeight? number prop mode, overrides the height worked out from the props bounding box
---@field targetHeight? number prop mode, what height on the prop the cam looks at, defaults to camHeight
---@field flipCam? boolean prop mode, which side of the prop the cam sits on. flip it if you get the back of the screen
---@field idle? DuiCursorIdle prop mode, what to do with the page when the player leaves. default 'detach'

---@class DuiCursorPanel
---@field origin vector3 top left corner
---@field right vector3 top left -> top right, length included
---@field down vector3 top left -> bottom left, length included
---@field facing vector3 unit vector pointing out of the front, thats where the cam goes

---@class DuiCursorHandle
---@field dui integer? raw dui object, nil once destroyed
---@field url string the page we were built with, kept so Restore can go back to it
---@field txd string runtime txd name
---@field txn string runtime texture name
---@field width integer
---@field height integer
---@field attached boolean whether the page is currently on a prop
---@field blank boolean whether the browser has been stopped on about:blank
---@field model string? txd it was last attached to, so Detach does not need reminding
---@field texture string? texture it was last attached to

local floor, min, max, tan, rad = math.floor, math.min, math.max, math.tan, math.rad

---@type DuiCursorHandle[]
local live = {}

---@type boolean
local active = false

---@type integer
local session = 0

---@type integer?
local cam

---@param path string
---@return string url
function DuiCursor.Url(path)
    if path:match('^https?://') then return path end

    return ('nui://%s/%s'):format(GetCurrentResourceName(), path)
end

---@param url string
---@param width? integer defaults to 1920
---@param height? integer defaults to 1080
---@return DuiCursorHandle?
function DuiCursor.Create(url, width, height)
    if type(url) ~= 'string' or url == '' then return end

    width = width or 1920
    height = height or 1080

    local txdName = ('duicursor_%s_%d'):format(GetCurrentResourceName(), GetGameTimer())
    local txnName = 'page'

    local dui = CreateDui(url, width, height)

    if not dui then return end

    local bound = pcall(CreateRuntimeTextureFromDuiHandle, CreateRuntimeTxd(txdName), txnName, GetDuiHandle(dui))

    if not bound then
        DestroyDui(dui)
        return
    end

    local handle = {
        dui = dui,
        url = url,
        txd = txdName,
        txn = txnName,
        width = width,
        height = height,
        attached = false,
        blank = false,
    }

    live[#live + 1] = handle

    return handle
end

---@param handle DuiCursorHandle
---@param data table|string
function DuiCursor.Send(handle, data)
    if not handle.dui then return end

    SendDuiMessage(handle.dui, type(data) == 'string' and data or json.encode(data))
end

---@param handle DuiCursorHandle
function DuiCursor.Destroy(handle)
    for i = #live, 1, -1 do
        if live[i] == handle then
            table.remove(live, i)
        end
    end

    if not handle.dui then return end

    DestroyDui(handle.dui)

    handle.dui = nil
end

---@param handle DuiCursorHandle
---@return boolean
function DuiCursor.Available(handle)
    return handle.dui ~= nil and IsDuiAvailable(handle.dui)
end

---@param handle DuiCursorHandle
function DuiCursor.Blank(handle)
    if not handle.dui or handle.blank then return end

    handle.blank = true
    SetDuiUrl(handle.dui, 'about:blank')
end

--- points it back at the real page. Attach does this for you
---@param handle DuiCursorHandle
function DuiCursor.Restore(handle)
    if not handle.dui or not handle.blank then return end

    handle.blank = false
    SetDuiUrl(handle.dui, handle.url)
end

---@param handle DuiCursorHandle
---@param model? string
---@param texture? string
function DuiCursor.Detach(handle, model, texture)
    if not handle.attached then return end

    local txd = model or handle.model
    local txn = texture or handle.texture

    handle.attached = false

    if txd and txn then
        RemoveReplaceTexture(txd, txn)
    end
end

---@param handle DuiCursorHandle
---@param model string txd name, usually the model name
---@param texture string texture inside that txd
---@param timeout? integer ms, default 5000
---@return boolean ok
function DuiCursor.Attach(handle, model, texture, timeout)
    -- coming back from Blank is a real page load, not just a repaint, so it
    -- needs longer to settle
    local reloading = handle.blank

    DuiCursor.Restore(handle)

    local deadline = GetGameTimer() + (timeout or 5000)

    while not DuiCursor.Available(handle) do
        if GetGameTimer() > deadline then return false end

        Wait(50)
    end

    Wait(reloading and 800 or 300)

    if not handle.dui then return false end

    AddReplaceTexture(model, texture, handle.txd, handle.txn)

    handle.attached = true
    handle.model, handle.texture = model, texture

    return true
end

local PROFILE_MOUSE_LOOK = 754

local PROFILE_MOUSE_MID = 7

local BASE_SENS = 0.080

---@param opts? DuiCursorOptions
---@return number sensitivity
---@return integer? notch what the profile reported, nil if it couldnt be read
function DuiCursor.Sensitivity(opts)
    opts = opts or {}

    if type(opts.sensitivity) == 'number' then
        return opts.sensitivity
    end

    if not GetProfileSetting then
        return BASE_SENS
    end

    local notch = GetProfileSetting(PROFILE_MOUSE_LOOK)

    if type(notch) ~= 'number' then
        return BASE_SENS
    end

    local scale = max(0.35, min(2.5, (notch + 1) / (PROFILE_MOUSE_MID + 1)))

    return BASE_SENS * scale * (opts.sensitivityScale or 1.0), notch
end

---@type table<integer, string[]>
local KEYS = {
    [0x08] = { 'Backspace', 'Backspace' },
    [0x0D] = { 'Enter', 'Enter' },
    [0x09] = { 'Tab', 'Tab' },
    [0x20] = { ' ', 'Space' },
    [0x2E] = { 'Delete', 'Delete' },
    [0x25] = { 'ArrowLeft', 'ArrowLeft' },
    [0x26] = { 'ArrowUp', 'ArrowUp' },
    [0x27] = { 'ArrowRight', 'ArrowRight' },
    [0x28] = { 'ArrowDown', 'ArrowDown' },

    -- Number row and OEM punctuation.  The raw-key path does not go
    -- through CEF's keyboard layout handling, so Shift symbols must be
    -- translated explicitly below.
    [0x30] = { '0', 'Digit0' },
    [0x31] = { '1', 'Digit1' },
    [0x32] = { '2', 'Digit2' },
    [0x33] = { '3', 'Digit3' },
    [0x34] = { '4', 'Digit4' },
    [0x35] = { '5', 'Digit5' },
    [0x36] = { '6', 'Digit6' },
    [0x37] = { '7', 'Digit7' },
    [0x38] = { '8', 'Digit8' },
    [0x39] = { '9', 'Digit9' },

    [0xBA] = { ';', 'Semicolon' },
    [0xBB] = { '=', 'Equal' },
    [0xBC] = { ',', 'Comma' },
    [0xBD] = { '-', 'Minus' },
    [0xBE] = { '.', 'Period' },
    [0xBF] = { '/', 'Slash' },
    [0xC0] = { '`', 'Backquote' },
    [0xDB] = { '[', 'BracketLeft' },
    [0xDC] = { '\\', 'Backslash' },
    [0xDD] = { ']', 'BracketRight' },
    [0xDE] = { "'", 'Quote' },
}

for vk = 0x41, 0x5A do
    KEYS[vk] = { string.char(vk), 'Digit' .. string.char(vk) }
end

for vk = 0x41, 0x5A do
    KEYS[vk] = { string.char(vk + 32), 'Key' .. string.char(vk) }
end

---@param opts DuiCursorOptions?
---@param data table
local function emitInput(opts, data)
    if opts and type(opts.onInput) == 'function' then
        local ok, err = pcall(opts.onInput, data)
        if not ok then
            print(('[duicursor] onInput error: %s'):format(tostring(err)))
        end
    end
end

-- US keyboard-layout Shift symbols used by the raw-key bridge.
-- This is what makes e.g. Shift+1 arrive as "!" in a DUI input.
local SHIFTED = {
    [0x30] = ')', [0x31] = '!', [0x32] = '@', [0x33] = '#', [0x34] = '$',
    [0x35] = '%', [0x36] = '^', [0x37] = '&', [0x38] = '*', [0x39] = '(',
    [0xBA] = ':', [0xBB] = '+', [0xBC] = '<', [0xBD] = '_', [0xBE] = '>',
    [0xBF] = '?', [0xC0] = '~', [0xDB] = '{', [0xDC] = '|', [0xDD] = '}',
    [0xDE] = '"',
}

local REPEAT_DELAY = 400
local REPEAT_RATE = 35

---@type table<integer, { at: integer, last: integer }>
local held = {}

local function seedKeys()
    for vk in pairs(KEYS) do
        held[vk] = IsRawKeyDown(vk) and { at = math.maxinteger, last = 0 } or nil
    end
end

---@param handle DuiCursorHandle
---@param opts DuiCursorOptions?
local function pumpKeys(handle, opts)
    local now = GetGameTimer()

    -- Detect Shift using both the Windows virtual-key codes and GTA's
    -- control mapping. Some FiveM/CEF builds do not report VK_SHIFT
    -- (0x10) reliably through IsRawKeyDown, which caused DUI text input
    -- to always arrive as lowercase even while Shift was held.
    local shift = IsRawKeyDown(0x10)
        or IsRawKeyDown(0xA0) -- Left Shift
        or IsRawKeyDown(0xA1) -- Right Shift
        or IsControlPressed(0, 21) -- INPUT_SPRINT / Shift

    for vk, entry in pairs(KEYS) do
        if not IsRawKeyDown(vk) then
            held[vk] = nil
        else
            local state = held[vk]
            local fire = false

            if not state then
                held[vk] = { at = now, last = now }
                fire = true
            elseif now - state.at >= REPEAT_DELAY and now - state.last >= REPEAT_RATE then
                state.last = now
                fire = true
            end

            if fire then
                local key = entry[1]

                if shift then
                    local shifted = SHIFTED[vk]
                    if shifted then
                        key = shifted
                    elseif #key == 1 and key >= 'a' and key <= 'z' then
                        key = key:upper()
                    end
                end

                local message = { action = 'key', key = key, code = entry[2], shift = shift }

                if DuiCursor.debug then
                    print(('[duicursor] key -> page: %s'):format(tostring(key)))
                end

                DuiCursor.Send(handle, message)
                emitInput(opts, message)
            end
        end
    end
end

---@param width number meters. keep the same ratio as the dui or the page comes out stretched
---@param height number meters
---@param distance? number how far in front, default 2.0
---@param eye? number height off the players feet for the middle of the panel, default 1.1
---@return DuiCursorPanel
function DuiCursor.PanelInFront(width, height, distance, eye)
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local fwd = GetEntityForwardVector(ped)

    local right = vector3(fwd.y, -fwd.x, 0.0) * width
    local down = vector3(0.0, 0.0, -height)

    local center = pos + fwd * (distance or 2.0) + vector3(0.0, 0.0, eye or 1.1)

    return {
        origin = center - right * 0.5 - down * 0.5,
        right = right,
        down = down,
        facing = -fwd,
    }
end

---@param handle DuiCursorHandle
---@param panel DuiCursorPanel
function DuiCursor.DrawPanel(handle, panel)
    local o, r, d = panel.origin, panel.right, panel.down
    local tl, tr, bl, br = o, o + r, o + d, o + r + d

    local function tri(a, b, c, au, av, bu, bv, cu, cv)
        DrawTexturedPoly(
            a.x, a.y, a.z,
            b.x, b.y, b.z,
            c.x, c.y, c.z,
            255, 255, 255, 255,
            handle.txd, handle.txn,
            au, av, 1.0,
            bu, bv, 1.0,
            cu, cv, 1.0
        )
    end

    tri(tl, tr, bl, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0)
    tri(bl, tr, br, 0.0, 1.0, 1.0, 0.0, 1.0, 1.0)

    tri(bl, tr, tl, 0.0, 1.0, 1.0, 0.0, 0.0, 0.0)
    tri(br, tr, bl, 1.0, 1.0, 1.0, 0.0, 0.0, 1.0)
end

---@param w number
---@param h number
---@param fov number vertical, degrees, same as gta
---@param fill number 1.0 fits exactly, less leaves a margin
---@return number distance
local function fitDistance(w, h, fov, fill)
    local resX, resY = GetActiveScreenResolution()

    local halfV = tan(rad(fov) * 0.5)
    local halfH = halfV * (resX / resY)

    return max((h * 0.5) / halfV, (w * 0.5) / halfH) / fill
end

---@param pos vector3
---@param lookAt vector3
---@param fov number
local function beginCam(pos, lookAt, fov)
    cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)

    SetCamCoord(cam, pos.x, pos.y, pos.z)
    PointCamAtCoord(cam, lookAt.x, lookAt.y, lookAt.z)
    SetCamFov(cam, fov + 0.0)
    SetCamActive(cam, true)

    RenderScriptCams(true, true, 1000, true, true)
end

local function endCam()
    RenderScriptCams(false, true, 1000, true, true)

    if cam then
        DestroyCam(cam, false)
        cam = nil
    end
end

---@param handle DuiCursorHandle
---@param opts DuiCursorOptions
---@param teardown fun() undo whatever the mode set up
---@param onExit? fun()
---@return integer session token for this entry
local function runCursor(handle, opts, teardown, onExit)
    local x, y = 0.5, 0.5
    local primed = false
    local frames = 0

    local sens = DuiCursor.Sensitivity(opts)

    -- IMPORTANT: do not send cursorMove through SendDuiMessage for the local
    -- controller. SendDuiMouseMove already produces a real CEF mousemove event
    -- inside the DUI. The page-side cursor follows that event directly.
    --
    -- Sending a second cursorMove message for every mouse packet can build a
    -- CEF message queue behind a busy minigame page. That is the source of the
    -- noticeable "mouse moved, then cursor catches up" delay.
    --
    -- Network synchronization is separate: emitInput() below still forwards
    -- cursor state to the server at the configured rate.

    local canType = opts.keys ~= false and IsRawKeyDown ~= nil

    local hidePlayer = opts.camera ~= false

    if opts.keys ~= false and not canType then
        print('[duicursor] no raw key natives on this build, typing is off')
    end

    if canType then
        seedKeys()
    end

    session = session + 1

    local mine = session

    local function frame()
        if not handle.dui then return false end

        DisableAllControlActions(0)
        DisableAllControlActions(1)
        DisableAllControlActions(2)

        if hidePlayer then
            if not IsPedInAnyVehicle(PlayerPedId()) then
                SetLocalPlayerInvisibleLocally(true)
            end
        end

        if IsDisabledControlJustReleased(0, 200)
            or (opts.exitOnBack and IsDisabledControlJustReleased(0, 177)) then
            return false
        end

        local resX, resY = GetActiveScreenResolution()
        local aspect = resX / resY

        local dx = GetDisabledControlUnboundNormal(0, 1)
        local dy = GetDisabledControlUnboundNormal(0, 2) * aspect

        if not primed or dx ~= 0.0 or dy ~= 0.0 then
            primed = true

            x = max(0.0, min(1.0, x + dx * sens))
            y = max(0.0, min(1.0, y + dy * sens))

            -- Native CEF mouse position: keep this at the full game-frame
            -- rate so DOM hover/drag/click behavior remains responsive.
            SendDuiMouseMove(handle.dui,
                min(handle.width - 1, floor(x * handle.width)),
                min(handle.height - 1, floor(y * handle.height)))

            -- The local page cursor follows CEF's native mousemove event, so
            -- there is no Lua -> CEF message in the local visual path.
            -- Server/observer synchronization remains independent and is
            -- throttled by eye_minigames/client/dui.lua.
            emitInput(opts, { action = 'cursorMove', x = x, y = y })

            if DuiCursor.debug then
                frames = frames + 1
                if frames % 120 == 1 then
                    print(('[duicursor] cursor %.3f %.3f (dx %.4f dy %.4f sens %.4f)')
                        :format(x, y, dx, dy, sens))
                end
            end
        end

        if IsDisabledControlJustPressed(0, 24) then
            SendDuiMouseDown(handle.dui, 'left')
            emitInput(opts, { action = 'mouseDown', button = 'left', x = x, y = y })

            if DuiCursor.debug then
                print(('[duicursor] mouseDown at %.3f %.3f'):format(x, y))
            end
        elseif IsDisabledControlJustReleased(0, 24) then

            SendDuiMouseUp(handle.dui, 'left')
            emitInput(opts, { action = 'mouseUp', button = 'left', x = x, y = y })

            if opts.onClick then
                opts.onClick(x, y)
            end
        end

        local wheel = 0

        if IsDisabledControlJustPressed(0, 15) or IsDisabledControlJustPressed(0, 241) then
            wheel = -1 -- up
        elseif IsDisabledControlJustPressed(0, 14) or IsDisabledControlJustPressed(0, 242) then
            wheel = 1 -- down
        end

        if wheel ~= 0 then
            if opts.invertWheel then wheel = -wheel end

            local wheelDy = wheel * (opts.wheelStep or 120)
            DuiCursor.Send(handle, { action = 'wheel', dy = wheelDy })
            emitInput(opts, { action = 'wheel', dy = wheelDy })
        end

        if canType then
            pumpKeys(handle, opts)
        end

        return true
    end

    CreateThread(function()
        if DuiCursor.debug then
            print(('[duicursor] cursor loop started (session %d, canType %s, %dx%d)')
                :format(mine, tostring(canType), handle.width, handle.height))
        end

        while active and session == mine do
            Wait(0)

            local ok, keepGoing = pcall(frame)

            if not ok then
                print(('[duicursor] cursor loop error: %s'):format(tostring(keepGoing)))
                break
            end

            if not keepGoing then break end
        end

        active = false

        if hidePlayer then
            SetLocalPlayerInvisibleLocally(false)
        end

        endCam()
        teardown()

        if DuiCursor.debug then
            print(('[duicursor] cursor loop ended (session %d)'):format(mine))
        end

        if onExit then onExit() end
    end)

    return mine
end

---@param handle DuiCursorHandle
---@param prop integer the object the screen is on
---@param model string txd name for AddReplaceTexture, usually the model name
---@param texture string texture inside that txd
---@param onExit? fun()
---@param opts? DuiCursorOptions
function DuiCursor.StartProp(handle, prop, model, texture, onExit, opts)
    if active then
        print('[duicursor] StartProp ignored: a panel is already active. The caller started two.')
        return false
    end

    active = true

    opts = opts or {}

    local coords = GetEntityCoords(prop)
    local forward = GetEntityForwardVector(prop)
    local fov = opts.fov or 50.0

    local minDim, maxDim = GetModelDimensions(GetEntityModel(prop))

    local height = opts.camHeight or (minDim.z + maxDim.z) * 0.5
    local dist = opts.camDistance
        or fitDistance(maxDim.x - minDim.x, maxDim.z - minDim.z, fov, opts.fill or 0.75)

    local dir = opts.flipCam and 1.0 or -1.0

    beginCam(
        coords + forward * (dist * dir) + vector3(0.0, 0.0, height),
        coords + vector3(0.0, 0.0, opts.targetHeight or height),
        fov
    )

    local function teardown()
        local idle = opts.idle or 'detach'

        if idle == 'keep' then return end

        DuiCursor.Detach(handle, model, texture)

        if idle == 'blank' then
            DuiCursor.Blank(handle)
        end
    end

    local mine = runCursor(handle, opts, teardown, onExit)

    if not handle.attached then
        CreateThread(function()
            local ok = DuiCursor.Attach(handle, model, texture)

            if ok and session ~= mine then
                teardown()
            end
        end)
    end

    return true
end

---@param handle DuiCursorHandle
---@param panel DuiCursorPanel
---@param onExit? fun()
---@param opts? DuiCursorOptions
function DuiCursor.StartPanel(handle, panel, onExit, opts)
    if active then
        print('[duicursor] StartPanel ignored: a panel is already active. The caller started two.')
        return false
    end

    active = true

    opts = opts or {}

    local fov = opts.fov or 50.0
    local center = panel.origin + panel.right * 0.5 + panel.down * 0.5

    local dist = opts.camDistance or fitDistance(#panel.right, #panel.down, fov, opts.fill or 0.85)

    if opts.camera ~= false then
        local camPos = center + panel.facing * dist

        if type(opts.camOffset) == 'table' then
            camPos = camPos + vector3(
                opts.camOffset.x or 0.0,
                opts.camOffset.y or 0.0,
                opts.camOffset.z or 0.0
            )
        end

        local target = center
        if type(opts.targetOffset) == 'table' then
            target = target + vector3(
                opts.targetOffset.x or 0.0,
                opts.targetOffset.y or 0.0,
                opts.targetOffset.z or 0.0
            )
        end

        beginCam(camPos, target, fov)
    end

    runCursor(handle, opts, function() end, onExit)

    return true
end

function DuiCursor.Stop()
    active = false
end

---@return boolean
function DuiCursor.IsActive()
    return active
end

AddEventHandler('onResourceStop', function(name)
    if name ~= GetCurrentResourceName() then return end

    DuiCursor.Stop()

    for i = #live, 1, -1 do
        local dui = live[i].dui

        if dui then
            DestroyDui(dui)
        end

        live[i] = nil
    end
end)
