local Sessions = {}
local UserSessions = {}

-------------------------------------------------------------------------------
-- Helper Functions
-------------------------------------------------------------------------------

local function createSessionId()
    return string.format("dui_%s_%s", os.time(), math.random(1000, 9999))
end

local function sanitizePayload(payload)
    if type(payload) ~= "table" then return {} end
    return payload
end

local function cleanPlayerSession(src)
    local sessionId = UserSessions[src]
    if not sessionId then return end

    local session = Sessions[sessionId]
    if session then
        -- Notify all current observers to tear down their DUI runtime instance
        for observerSrc, _ in pairs(session.observers) do
            TriggerClientEvent('eye_minigames:dui:observerStop', observerSrc, sessionId)
        end
        Sessions[sessionId] = nil
    end

    UserSessions[src] = nil
end

-------------------------------------------------------------------------------
-- Networking & Synchronization Handlers
-------------------------------------------------------------------------------

-- Handle Client Initialization Request
RegisterNetEvent('eye_minigames:dui:start', function(requestToken, rawPayload)
    local src = source
    local payload = sanitizePayload(rawPayload)

    -- Force single active session per player controller
    if UserSessions[src] then
        cleanPlayerSession(src)
    end

    local sessionId = createSessionId()
    local seed = math.random(100000, 999999)

    Sessions[sessionId] = {
        id = sessionId,
        owner = src,
        payload = payload,
        seed = seed,
        observers = {},
        inputHistory = {},
        cursorState = nil
    }
    UserSessions[src] = sessionId

    -- Acknowledge controller setup
    TriggerClientEvent('eye_minigames:dui:started', src, requestToken, sessionId, seed)
end)

-- Handle Client Stop Request
RegisterNetEvent('eye_minigames:dui:stop', function(sessionId)
    local src = source
    if UserSessions[src] and UserSessions[src] == sessionId then
        cleanPlayerSession(src)
    end
end)

-- Input Synchronization (Controller -> Server -> Observers)
RegisterNetEvent('eye_minigames:dui:input', function(sessionId, eventData)
    local src = source
    local session = Sessions[sessionId]

    -- Verify the input sender is the registered controller host
    if not session or session.owner ~= src then return end
    if type(eventData) ~= "table" then return end

    -- Cursor movement is state, not history. Keep only the latest position so
    -- a long minigame cannot grow an unbounded server-side input log.
    if eventData.action == 'cursorMove' then
        session.cursorState = eventData
    else
        table.insert(session.inputHistory, eventData)
        if #session.inputHistory > 2000 then
            table.remove(session.inputHistory, 1)
        end
    end

    -- Forward input state to all registered secondary viewers.
    for observerSrc, _ in pairs(session.observers) do
        TriggerClientEvent('eye_minigames:dui:observerInput', observerSrc, sessionId, eventData)
    end
end)

-- Clock synchronization uses the same controller authorization as input.
RegisterNetEvent('eye_minigames:dui:clock', function(sessionId, clockData)
    local src = source
    local session = Sessions[sessionId]
    if not session or session.owner ~= src then return end
    if type(clockData) ~= 'table' then return end

    for observerSrc, _ in pairs(session.observers) do
        TriggerClientEvent('eye_minigames:dui:observerInput', observerSrc, sessionId, {
            action = 'duiClock',
            clock = clockData
        })
    end
end)

-------------------------------------------------------------------------------
-- Observer Management (Join / Leave Spectating)
-------------------------------------------------------------------------------

-- Request to start observing an active DUI instance
RegisterNetEvent('eye_minigames:dui:observe', function(sessionId)
    local src = source
    local session = Sessions[sessionId]
    if not session then return end

    session.observers[src] = true
    local history = {}
    for i, eventData in ipairs(session.inputHistory) do
        history[i] = eventData
    end
    if session.cursorState then
        history[#history + 1] = session.cursorState
    end
    TriggerClientEvent('eye_minigames:dui:observerStart', src, sessionId, session.payload, session.seed, history)
end)

-- Stop observing a DUI instance
RegisterNetEvent('eye_minigames:dui:unobserve', function(sessionId)
    local src = source
    local session = Sessions[sessionId]
    if not session then return end

    session.observers[src] = nil
    TriggerClientEvent('eye_minigames:dui:observerStop', src, sessionId)
end)

-------------------------------------------------------------------------------
-- HTTP bridge: DUI page -> server -> owning client
-------------------------------------------------------------------------------
-- A DUI browser has no NUI callback channel. fetch('https://resource/name')
-- from a DUI is not routed anywhere and window.invokeNative does not exist, so
-- a minigame running inside the DUI had no way to report whether it was won or
-- lost. CEF can reach a normal HTTP URL, so the page posts here instead.
--
-- Reachable at http://<server-ip>:<port>/eye_minigames/result
-- The client passes that base URL into the page as the ?api= query parameter.

local function httpJson(res, status, body)
    res.writeHead(status, {
        ['Content-Type'] = 'application/json',
        -- The DUI's origin is nui://eye_minigames, so this is cross-origin.
        ['Access-Control-Allow-Origin'] = '*',
        ['Access-Control-Allow-Methods'] = 'POST, OPTIONS',
        ['Access-Control-Allow-Headers'] = 'Content-Type'
    })
    res.send(body or '{}')
end

SetHttpHandler(function(req, res)
    local path = (req.path or ''):gsub('%?.*$', '')

    if req.method == 'OPTIONS' then
        return httpJson(res, 204, '')
    end

    if path ~= '/result' and path ~= '/closed' then
        return httpJson(res, 404, '{"error":"not found"}')
    end

    req.setDataHandler(function(body)
        local ok, data = pcall(json.decode, body)
        if not ok or type(data) ~= 'table' then
            return httpJson(res, 400, '{"error":"bad payload"}')
        end

        local session = Sessions[data.session]
        if not session then
            return httpJson(res, 404, '{"error":"unknown session"}')
        end

        if path == '/closed' then
            TriggerClientEvent('eye_minigames:dui:closed', session.owner, data.session)
        else
            TriggerClientEvent(
                'eye_minigames:dui:result',
                session.owner,
                data.session,
                data.success == true
            )
        end

        httpJson(res, 200, '{"ok":true}')
    end)
end)

-------------------------------------------------------------------------------
-- Server Callbacks & Player Disconnect Cleanup
-------------------------------------------------------------------------------

-- Register ox_lib callback to retrieve active sessions nearby
lib.callback.register('eye_minigames:dui:getActiveSessions', function(source)
    local active = {}
    for id, session in pairs(Sessions) do
        active[#active + 1] = {
            id = id,
            owner = session.owner,
            payload = session.payload
        }
    end
    return active
end)

-- Cleanup when player disconnects
AddEventHandler('playerDropped', function()
    local src = source
    cleanPlayerSession(src)

    -- Remove player from all observer lists
    for _, session in pairs(Sessions) do
        if session.observers[src] then
            session.observers[src] = nil
        end
    end
end)