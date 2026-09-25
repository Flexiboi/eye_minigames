Config = {}

Config.AllowCancelByDefault = true

-- Built-in local test commands. Set false for production servers.
Config.EnableTestCommands = true

Config.Sound = true        -- master on/off
Config.Volume = 0.5        -- 0.0 - 1.0

Config.DuiSyncRange = 25.0

Config.DuiWidth = 1280
Config.DuiHeight = 720

-- Prints what the DUI cursor loop is doing to the client console (F8):
-- whether the loop started, whether raw-key input is available, the cursor
-- position, clicks, and every key forwarded to the page. Turn on when a DUI is
-- not responding, off for production.
Config.DuiDebug = false

Config.DuiTestProp = {
    -- `txd` and `texture` are the ORIGINAL texture dictionary + texture name on
    -- the model, and they are model-specific. They are what AddReplaceTexture
    -- targets. If the pair is wrong the replacement silently does nothing and
    -- the prop keeps its own screen, with no error printed.
    --
    -- Use OpenIV / CodeWalker to confirm the pair for any other model. Another
    -- known-good example:
    --   model = 'hei_prop_hei_securitypanel'
    --   txd = 'hei_prop_hei_securitypanel'
    --   texture = 'prop_hei_securitypanel_screen'
    model = 'prop_monitor_01b',
    txd = 'prop_monitor_01b',
    texture = 'prop_monitor_01b',
    -- Normalized visible/clickable texture rectangle. Keep 0..1.
    uv = { uMin = 0.0, uMax = 1.0, vMin = 0.0, vMax = 1.0, flipX = false, flipY = false, rotate = 0 },
    screenWidth = 0.60,
    screenHeight = 0.34,
    screenOffset = vector3(0.0, 0.0, 0.0),
    camera = true,
    cameraDistance = 1.0,
    cameraHeight = 0.0,
    cameraFov = 40.0,
    cameraSide = 1.0
}

Config.Defaults = {
    livewire    = { difficulty = 2 },
    flatline    = { difficulty = 2, rounds = 3 },
    deadcalm    = { difficulty = 2, shots = 3 },
    ghostsignal = { difficulty = 2 },
    steadydose  = { difficulty = 2 },
    cuttheright = { difficulty = 2 },
    vaultspin   = { difficulty = 2, tumblers = 3 },
    bluff       = { difficulty = 2, hands = 3 },
    decrypt     = { difficulty = 2 },
    gaslight    = { difficulty = 2 },

    overflow     = { difficulty = 2 },
    breachmatrix = { difficulty = 2 },
    daemonrun    = { difficulty = 2 },
    pulse        = { difficulty = 2 },
    hottrace     = { difficulty = 2 },
    cascade      = { difficulty = 2 },
    lightsout    = { difficulty = 2 },
    slidepuzzle  = { difficulty = 2 },

    resonance    = { difficulty = 2 },
    intrusion    = { difficulty = 2 },
    override     = { difficulty = 2 },
    animus       = { difficulty = 2 },
    eaglevision  = { difficulty = 2 },
    parry        = { difficulty = 2 },
    constellation = { difficulty = 2 },
    archery      = { difficulty = 2 },

    skillcheck   = { difficulty = 2, rounds = 3 },
    lockpick     = { difficulty = 2 },
    keypad       = { difficulty = 2 },
    password     = { difficulty = 2, password = "1234", attempts = 3, caseSensitive = true },
    quicktime    = { difficulty = 2 },
    mash         = { difficulty = 2 },
    reaction     = { difficulty = 2 },
    stacker      = { difficulty = 2 },
    targets      = { difficulty = 2 },

    fishing      = { difficulty = 2 },
    mining       = { difficulty = 2 },
    cooking      = { difficulty = 2 },
    welding      = { difficulty = 2 },
    harvest      = { difficulty = 2 },
    drilling     = { difficulty = 2 },
    locksmith    = { difficulty = 2 },
    hotwire      = { difficulty = 2 },
    crafting     = { difficulty = 2 },
    forge        = { difficulty = 2 },
    diving       = { difficulty = 2 },

    tripwire     = { difficulty = 2 },
    pickpocket   = { difficulty = 2 },
    getaway      = { difficulty = 2 },
    cashcount    = { difficulty = 2 },
    counterfeit  = { difficulty = 2 },
    chopshop     = { difficulty = 2 },

    lugnuts      = { difficulty = 2 },
    paintspray   = { difficulty = 2 },
    crane        = { difficulty = 2 },

    suture       = { difficulty = 2 },
    bonepin      = { difficulty = 2 },
    vitals       = { difficulty = 2 },

    thermite     = { difficulty = 2 },
    lasergrid    = { difficulty = 2 },
    vaultdrill   = { difficulty = 2 },
    jammer       = { difficulty = 2 },
    dataheist    = { difficulty = 2 },

    partsort     = { difficulty = 2 },
    toolbox      = { difficulty = 2 },
    packing      = { difficulty = 2 },
    beltsort     = { difficulty = 2 },

    fingerprint  = { difficulty = 2 },
    breathalyzer = { difficulty = 2 },

    titration    = { difficulty = 2 },
    pillpress    = { difficulty = 2 }
}

Config.FreezePlayer = false
