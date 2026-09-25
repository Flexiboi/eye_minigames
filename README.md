# EDITS [VIBE CODED]

Added option to display minigames in DUI replace texture mode and play the minigames in 3d world space DUI.
</br>
Added password minigame
</br>
Changed style to windwos XP

# Ay-eye Minigames

A **standalone, framework-agnostic** pack of 70 cinematic skill-check minigames
for FiveM, with one clean export API. No ESX, QBCore, QBox, or ox_lib required.
Drop it in, call it from any script, get a `true`/`false` back.

# [Preview](https://eye-minigames.vercel.app/) 
# [Discord ](https://discord.gg/BN34qUeKwY)
---

## The games (70 total)

### Essentials (8 — the everyday workhorses, fit any script)

| id | name | mechanic | good for |
|----|------|----------|----------|
| `skillcheck` | Skill Check | sweep a marker into the zone (multi-round) | the universal one — any job/crime action |
| `lockpick` | Lockpick | rotate pick to each hidden sweet spot | doors, vehicles, safes, lockers |
| `keypad` | Keypad | deduce a hidden PIN from ●/○ feedback | doors, safes, alarms, terminals |
| `quicktime` | Quicktime | press a key sequence before each timer | struggles, repairs, chases, QTEs |
| `mash` | Mash | spam SPACE to fill a draining bar | break free, CPR, prying, pushing |
| `reaction` | Reaction | wait for green, tap fast (no early starts) | reflex gates, quickdraw, sobriety |
| `stacker` | Stacker | drop sliding blocks to stack a tower | loading, assembling, packing |
| `targets` | Targets | click pop-up targets, dodge red decoys | aim gates, fast interactions |

### Core (10)

| id | name | mechanic | good for |
|----|------|----------|----------|
| `livewire` | Live Wire | drag-match colored wires | electrician, panel hacks, fuse boxes |
| `flatline` | Flatline | defib rhythm timing (SPACE in green zone) | EMS, revives |
| `deadcalm` | Dead Calm | sniper breath control (hold SPACE, click) | hits, hunting, ranges |
| `ghostsignal` | Ghost Signal | tune frequency + phase to a hidden wave | surveillance, jamming, radios |
| `steadydose` | Steady Dose | keep needle in a moving band (mouse) | medic, drugs, lab work |
| `cuttheright` | Cut The Right One | read clue, cut the correct wire | bomb defusal, traps |
| `vaultspin` | Vault Spin | analog combination dial (drag) | safes, vaults |
| `bluff` | Bluff | read NPC tells, call or fold | interrogation, deals, poker |
| `decrypt` | Decrypt | type streaming code tokens | hacking, terminals |
| `gaslight` | Gaslight | flash-memory recall | witness, recon, observation |

### Advanced (8 — inspired by well-known game mechanics)

| id | name | mechanic | inspired by | good for |
|----|------|----------|-------------|----------|
| `overflow` | Overflow | rotate pipe tiles to connect source→drain | Pipe Dream / BioShock | plumbing, gas, fluid systems |
| `breachmatrix` | Breach Matrix | hex sequence injection, row/col picks | Cyberpunk Breach Protocol | advanced hacking, terminals |
| `daemonrun` | Daemon Run | maze data-grab while dodging a trace | Pac-Man-style hacks | data heists, ICE evasion |
| `pulse` | Pulse | 4-lane rhythm note hitting (D F J K) | Guitar Hero / rhythm | DJ, music, timing-heavy jobs |
| `hottrace` | Hot Trace | drag a probe through a corridor, no walls | Operation / wire-loop | surgery, delicate wiring, defusal |
| `cascade` | Cascade | escalating Simon-says pattern memory | Simon / Bop It | keypads, memory locks |
| `lightsout` | Lights Out | flip cells (and neighbours) until every light is off | Lights Out | logic locks, fuse boxes, terminals |
| `slidepuzzle` | Slide Puzzle | slide the scrambled tiles back into 1..N order | 15-puzzle | locks, repairs, decryption, terminals |

### AAA-Inspired (8 — premium signature mechanics)

| id | name | mechanic | inspired by | good for |
|----|------|----------|-------------|----------|
| `resonance` | Resonance | tune sine sliders so your wave matches a target (one "inverts voltage") | Marvel's Spider-Man circuit puzzles | calibration, lab hacks, repairs |
| `intrusion` | Intrusion | hop the signal through a node network, dodge monitored (red) nodes | Watch Dogs camera/ctOS hopping | advanced hacking, CCTV, infiltration |
| `override` | Override | lock spinning concentric rings at the top notch before corruption fills | Horizon Zero Dawn override | machine/drone takeover, control hacks |
| `animus` | Animus | rotate concentric rings to align all key segments to one spoke | Assassin's Creed animus/glyph | ancient locks, sync points, relics |
| `eaglevision` | Eagle Vision | memorize a target signature, then click every match among decoys | AC eagle vision / spider-sense | recon, target ID, surveillance |
| `parry` | Deflect | parry each incoming strike with the right arrow inside the timing ring | Sekiro / soulslike | melee duels, struggles, defence |
| `constellation` | Stargazing | connect the numbered stars in order to trace the constellation | AC / Ghost of Tsushima | rituals, recon, observation, lore |
| `archery` | Longshot | drag from the bow toward the target & arc the shot onto it (trajectory preview) | Horizon / Tomb Raider | hunting, archery, ranged skill checks |

### Jobs (14 — job-specific)

| id | name | mechanic | good for |
|----|------|----------|----------|
| `fishing` | Fishing | wait for the bite, then keep the fish in the zone while reeling | fishing job |
| `mining` | Mining | strike the glowing crack before it fades, dodge misses | mining, quarry |
| `cooking` | Cooking | multi-step timing — hit each stage in the green | cooking, crafting |
| `welding` | Welding | drag the torch along a seam at steady speed without overheating | mechanic, repairs, fabrication |
| `harvest` | Harvest | rhythm — cut each crop as it crosses the line | farming, weed/coca trim |
| `drilling` | Drilling | hold to drill, keep pressure in the green without overheating | drilling, breaching, oil |
| `locksmith` | Locksmith | raise each pin to its shear line and set it | doors, locks, repo |
| `hotwire` | Hotwire | connect the wires, then time the ignition spark | car theft, boosting |
| `crafting` | Crafting | memorize the recipe, then add ingredients in order | crafting, chemistry, cooking |
| `lugnuts` | Lug Nuts | torque each wheel nut in star order — stop the needle in the green | mechanic, tyre shop, repairs |
| `paintspray` | Paint Booth | spray the panel to even coverage without over-soaking (drips) | bodyshop, resprays, detailing |
| `crane` | Cargo Crane | lead the pendulum swing and drop crates onto the truck | docks, warehouse, loading |
| `forge` | Blacksmith | strike the metal while it glows in the green heat window | smithing, weapon/tool crafting, metalwork |
| `diving` | Salvage Dive | grab the loot, surface to breathe before air runs out | diving, salvage, smuggling, search & rescue |

### Mechanic (4 — sorting & moving things around)

| id | name | mechanic | good for |
|----|------|----------|----------|
| `partsort` | Parts Sort | send each part to its matching bin (1 / 2 / 3) | mechanic, warehouse, parts shop, recycling |
| `toolbox` | Tool Board | drag each tool onto its matching shadow outline | mechanic, garage, organizing, prep |
| `packing` | Crate Packing | drag every part into the crate so they all fit (Tetris-style) | warehouse, shipping, loadouts, storage |
| `beltsort` | Quality Control | pull the cracked parts off the conveyor, let good ones pass | factory, assembly line, inspection, recycling |

### Crime (6 — illegal jobs)

| id | name | mechanic | good for |
|----|------|----------|----------|
| `tripwire` | Tripwire | weave past sweeping lasers to the exit — one touch = caught | infiltration, heists, security rooms |
| `pickpocket` | Pickpocket | hold to lift, release before the mark glances at you | theft, lifting, stealth |
| `getaway` | Getaway | swap lanes to dodge oncoming traffic and survive the run | chases, getaway driver, street racing |
| `cashcount` | Count The Take | click bills to hit the exact amount (undo to fix overcounts) | robbery loot, drug deals, laundering |
| `counterfeit` | Counterfeit | drag the plate onto the guides and hold it aligned to print | fake bills, forged documents |
| `chopshop` | Chop Shop | hold on each car part to unbolt it before the heat maxes out | stolen car stripping, parts fencing |

### Medical & Rescue (3)

| id | name | mechanic | good for |
|----|------|----------|----------|
| `suture` | Suture | click each stitch as its ring shrinks into the green | EMS, surgery, field medic |
| `bonepin` | Bone Set | drag fractured fragments into their matching slots | orthopedics, surgery, first aid |
| `vitals` | Vitals | keep three drifting gauges in the green — tap 1 / 2 / 3 | EMS monitoring, ICU, anesthesia |

### Police & Forensics (2)

| id | name | mechanic | good for |
|----|------|----------|----------|
| `fingerprint` | Fingerprint | match the scanned print — click the identically-oriented one | police, forensics, evidence, access ID |
| `breathalyzer` | Breathalyzer | hold to blow, keep airflow in the green to log a clean reading | DUI stops, sobriety, medical |

### Drugs & Chemistry (2)

| id | name | mechanic | good for |
|----|------|----------|----------|
| `titration` | Titration | pour reagent and stop exactly in the narrow target band | drug labs, chemistry, lab work, brewing |
| `pillpress` | Pill Press | time each press stroke to stamp a clean pill | drug production, pharma, manufacturing |

### Heist (5)

| id | name | mechanic | good for |
|----|------|----------|----------|
| `thermite` | Thermite | memorize the lit cells, then burn the same ones back | vault breaches, doors, fleeca/pacific |
| `lasergrid` | Laser Grid | guide the cursor to the exit without touching a sweeping laser | infiltration, vaults, museums |
| `vaultdrill` | Vault Drill | stop each drill point in the green core | safes, vaults, ATMs |
| `jammer` | Signal Jammer | jam each alarm channel as its bar peaks | alarms, cameras, security |
| `dataheist` | Data Heist | catch the clean data packets, dodge the corrupt red ones | hacking, data steals, USB grabs |

---

## Install

1. Drop the `eye_minigames` folder into your `resources`.
2. Add to `server.cfg`:
   ```
   ensure eye_minigames
   ```
3. (Optional) rename the folder — just keep it consistent with the
   `ensure` line. The export name follows the folder name.

No database, no dependencies.

---

## Usage

### Blocking (recommended — runs inside a thread)

```lua
CreateThread(function()
    local ok = exports.eye_minigames:Play('vaultspin', {
        difficulty = 3,                 -- 1 (easy) .. 5 (brutal)
        tumblers   = 4                  -- per-game option (see table below)
    })

    if ok then
        print('cracked the safe!')
        -- TriggerServerEvent('myheist:vaultOpen')
    else
        print('failed')
    end
end)
```

### Non-blocking (callback)

```lua
exports.eye_minigames:Start('flatline', { difficulty = 4 }, function(ok)
    if ok then
        -- revive logic
    end
end)
```

### Optional synchronized DUI

DUI is opt-in. **Normal `/mg` and `exports:Play()` are unchanged** and still use the original fullscreen NUI.

For prop DUIs, `resW`/`resH` may be supplied in `prop` to keep the CEF viewport and mouse coordinate mapping tied to the replacement texture dimensions.

**Mouse/input behavior:** DUI controller input is now transported through the fullscreen NUI capture layer. Mouse coordinates are raycast against the configured world/prop screen in Lua and then sent to the DUI browser with `SendDuiMouseMove`, `SendDuiMouseDown`, `SendDuiMouseUp`, and `SendDuiMouseWheel`. This means HTML buttons, sliders, drag controls, and `<input>` elements receive real browser mouse interaction instead of relying on disabled GTA controls.

**Per-prop UV calibration:** `prop.uv` is available directly in the `StartDui` / `PlayDui` export. `uMin/uMax/vMin/vMax` define the normalized clickable screen rectangle. `flipX`, `flipY`, and `rotate` (`0`, `90`, `180`, `270`) correct texture orientation when a model's screen is mirrored or rotated.

```lua
prop = {
    -- ...
    uv = {
        uMin = 0.0,
        uMax = 1.0,
        vMin = 0.0,
        vMax = 1.0,

        flipX = false,
        flipY = false,
        rotate = 0
    }
}
```


When you use `StartDui` / `PlayDui`, the same HTML minigame that normally appears in the fullscreen NUI is loaded into a FiveM DUI browser. The DUI browser is then used as a **runtime texture replacement on an existing prop**, or as a **two-coordinate world screen**.

#### 1. Prop texture-replace DUI

This is the recommended DUI mode when the minigame should appear on a monitor, tablet, terminal, arcade screen, etc.

The resource does **not** spawn the prop. It finds the existing object, creates a DUI browser, creates a runtime texture from the DUI handle, and calls `AddReplaceTexture(originalTxd, originalTexture, runtimeTxd, runtimeTexture)`. The replacement is removed when the minigame ends.

```lua
CreateThread(function()
    local success = exports.eye_minigames:PlayDui('password', {
        difficulty = 2,
        password = '1234',

        prop = {
            model = 'hei_prop_hei_securitypanel',
            coords = vec4(144.69, -1048.38, 29.88, 173.16),
            txd = 'hei_prop_hei_securitypanel',
            texture = 'prop_hei_securitypanel_screen',

            -- Interactive Bounds & Click Area
            screenWidth = 0.60,
            screenHeight = 0.34,
            screenOffset = vector3(0.0, 0.0, 0.0),

            -- Camera Positioning
            camera = true,
            cameraDistance = 1.0,
            cameraHeight = 0.0,
            cameraFov = 40.0,
            cameraSide = 1.0,

            -- Optional UV adjustment (defaults to 0..1)
            uv = { uMin = 0.0, uMax = 1.0, vMin = 0.0, vMax = 1.0 }
        }
    })

    print('result:', success)
end)
```

**Important:** `txd` and `texture` are the **original texture dictionary/name on the prop**, not the runtime DUI texture. They are model-specific. The prop should already exist when the call is made.

If the prop was spawned by another resource, you can pass its entity handle as `prop.entity` instead of relying on the nearby-object lookup.

#### 2. Two-coordinate world DUI

If you do not want a prop, provide two opposite world coordinates. The HTML is still the exact same minigame UI, but the DUI is rendered on a world-space screen.

```lua
CreateThread(function()
    local success = exports.eye_minigames:PlayDui('vaultspin', {
        difficulty = 3,
        topLeft = vector4(123.40, -456.70, 30.20, 90.0),
        bottomRight = vector4(127.40, -456.70, 28.20, 90.0),
        duiRange = 25.0
    })

    print('result:', success)
end)
```

`w` is the heading of the screen plane. The heading is now used to build the screen's right/normal axes, so rotated two-coordinate screens stay aligned with the DUI camera and mouse raycast.

#### DUI exports

```lua
exports.eye_minigames:StartDui(game, opts, callback)
exports.eye_minigames:PlayDui(game, opts)

exports.eye_minigames:SetDuiCameraDistance(1.25)
exports.eye_minigames:SetDuiCameraFov(40.0)
exports.eye_minigames:SetDuiCameraSide(1) -- 1 or -1
exports.eye_minigames:ToggleDuiCamera(true)
```

`StartDui` / `PlayDui` require a valid `prop` or both `topLeft` and `bottomRight`. They no longer silently fall back to fullscreen NUI when an explicit DUI call is missing placement data.

#### DUI test commands

Test commands are enabled by default with `Config.EnableTestCommands = true` in `config.lua`.

**Two-coordinate DUI:**

```text
/mgdui <id> <difficulty> <topLeft vector4> <bottomRight vector4>
```

Example:

```text
/mgdui password 2 vector4(123.40,-456.70,30.20,90.0) vector4(124.80,-456.70,29.40,90.0)
```

The original `/mg` also supports the same two-coordinate syntax:

```text
/mg password 2 vector4(123.40,-456.70,30.20,90.0) vector4(124.80,-456.70,29.40,90.0)
```

**Prop texture-replace DUI:**

Stand within roughly 3 metres of the existing prop and run:

```text
/mgduiprop <id> [difficulty] [model] [txd] [texture]
```

For example:

```text
/mgduiprop password 2 prop_monitor_01b prop_monitor_01b prop_monitor_01b
/mgduiprop password 2 hei_prop_hei_securitypanel hei_prop_hei_securitypanel prop_hei_securitypanel_screen
```

The command searches for the configured model within 3 metres of the player, then uses the **actual existing object's position and rotation**. It does **not** spawn the model. The DUI screen plane and camera are aligned to the prop's front direction. You can also configure the defaults in `config.lua`:

```lua
local success = exports.eye_minigames:PlayDui('password', {
    -- ============================================
    -- GAME SETTINGS
    -- ============================================
    
    -- difficulty: How hard the minigame is (1-5)
    -- 1 = Very Easy, 2 = Easy, 3 = Medium, 4 = Hard, 5 = Very Hard
    -- Higher difficulty = shorter timers, more complex puzzles
    difficulty = 2,
    
    -- password: The password the player needs to enter
    -- This can be any string. The UI will show input fields for each character.
    -- Example: "HELLO" would show 5 input boxes
    password = lib.callback.await('flex_bankrob:server:fleeca:GetVaultPassword', false),
    
    -- ============================================
    -- PROP SETTINGS (What prop to show the DUI on)
    -- ============================================
    prop = {
        
        -- ============================================
        -- PROP IDENTIFICATION
        -- ============================================
        
        -- model: The GTA prop model name to look for
        -- The script will find this prop near the player (within 3m)
        -- Change this to match the prop you want to use
        model = 'hei_prop_hei_securitypanel',
        
        -- coords: The exact world position of the prop
        -- Format: vec4(x, y, z, heading)
        -- The heading controls which direction the prop faces
        -- Use /coords in game to find exact coordinates
        coords = vec4(144.69186401367, -1048.3861083984, 29.882019042969, 173.16479492188),
        
        -- ============================================
        -- TEXTURE REPLACEMENT SETTINGS
        -- ============================================
        
        -- txd: The texture dictionary (container) name
        -- This is the .ytd file name without the extension
        -- Must match exactly what the prop uses
        txd = 'hei_prop_hei_securitypanel',
        
        -- texture: The specific texture name within the TXD
        -- This is the texture that will be replaced with the DUI
        -- Must match exactly what the prop uses
        texture = 'prop_hei_securitypanel_screen',
        
        -- ============================================
        -- CLICKABLE AREA SETTINGS (Most important for fixing click issues)
        -- ============================================
        
        -- screenWidth: The width of the clickable area in world units
        -- This determines how far left/right you can click
        -- Too small = can't click edges, Too large = clicks outside the UI
        -- Default: 0.60, Range: 0.10 to 2.0
        -- Increase if buttons on the sides aren't clickable
        screenWidth = 0.60,
        
        -- screenHeight: The height of the clickable area in world units
        -- This determines how far up/down you can click
        -- Too small = can't click top/bottom, Too large = clicks outside the UI
        -- Default: 0.34, Range: 0.10 to 2.0
        -- Increase if buttons at top/bottom aren't clickable
        screenHeight = 0.34,
        
        -- screenOffset: Moves the entire clickable area
        -- Format: vector3(x, y, z) where z is up/down (0 = no offset)
        -- Positive x = right, Negative x = left
        -- Positive y = forward/back (rarely used for flat surfaces)
        -- Positive z = up, Negative z = down
        -- Use this if the UI appears shifted relative to the clickable area
        -- Example: vector3(0.05, 0, 0) moves it 0.05 units right
        screenOffset = vector3(0.0, 0.0, 0.0),
        
        -- ============================================
        -- CAMERA SETTINGS (Controls the view of the prop)
        -- ============================================
        
        -- camera: Whether to enable the scripted camera
        -- true = Camera will automatically look at the prop
        -- false = Camera won't move, player can look manually
        camera = true,
        
        -- cameraDistance: How far the camera is from the screen
        -- Smaller = closer (zoomed in), Larger = farther (zoomed out)
        -- Default: 1.0, Range: 0.1 to 10.0
        -- 0.5 = Very close, 1.0 = Good default, 2.0 = Far away
        cameraDistance = 1.0,
        
        -- cameraHeight: Vertical offset of the camera
        -- Positive = camera is higher, Negative = camera is lower
        -- Default: 0.0, Range: -5.0 to 5.0
        -- Use this to center the view vertically on the screen
        cameraHeight = 0.0,  -- Not shown in your example but available
        
        -- cameraFov: Field of view in degrees
        -- Smaller = more zoomed in, Larger = more zoomed out
        -- Default: 40.0, Range: 10.0 to 120.0
        -- 30 = Very zoomed, 40 = Good default, 60 = Wide view
        cameraFov = 40.0,
        
        -- cameraSide: Which side of the prop to view from
        -- 1 = Front of the screen (normal view)
        -- -1 = Back of the screen (looking through it)
        -- Default: 1.0
        -- Change to -1 if the camera appears on the wrong side
        cameraSide = 1.0,
        
        -- cameraOffset: Additional offset for the camera position
        -- Format: vector3(x, y, z)
        -- Use this if the camera needs fine-tuning relative to the screen
        -- Example: vector3(0, 0, 0.1) moves camera up slightly
        cameraOffset = vector3(0.0, 0.0, 0.0),  -- Not shown but available
        
        -- UV rectangle used for click mapping.
        -- Default maps the complete physical screen to the DUI.
        uv = {
            uMin = 0.0,
            uMax = 1.0,
            vMin = 0.0,
            vMax = 1.0
        },

    },
})
```

```lua
Config.DuiTestProp = {
    model = 'prop_monitor_01b',
    txd = 'prop_monitor_01b',
    texture = 'prop_monitor_01b',
    screenWidth = 0.60,
    screenHeight = 0.34,
    screenOffset = vector3(0.0, 0.0, 0.0),
    camera = true,
    cameraDistance = 1.0,
    cameraFov = 40.0,
    cameraSide = 1.0
}
```

Then:

```text
/mgduiprop password 2
```

**Stop/debug:**

```text
/mgduistop
/mgcam
/mgcamdist 1.25
/mgcamfov 40
/mgcamside 1
/mgduidebug
```

Use `/mglist` to see the available game IDs.

#### How the DUI keeps the same minigame UI

There is only one HTML game implementation. Normal NUI opens `html/index.html` with the game payload; DUI creates another instance of that same `index.html` inside Chromium and sends the same `game`, difficulty, options, seed, and session information to it.

The DUI page changes only its outer presentation to fill the DUI browser surface. The game scripts, HUD, timer, board, sounds, success/failure logic, and result contract are the same ones used by normal `/mg`.

Keyboard input is captured once by the hidden NUI page and forwarded to the controller DUI. Mouse input goes from the GTA cursor to the world/prop screen ray and then into the DUI browser. This avoids the duplicate key/click behavior that can otherwise occur when mixing NUI and DUI input paths.

#### Lifecycle

- DUI is created only for explicit DUI calls or `/mgdui`/`/mgduiprop`.
- Prop texture replacement is removed when the session ends.
- The DUI browser and runtime texture are destroyed on cleanup/resource stop.
- Normal fullscreen NUI behavior is untouched.
- Synchronized observers remain read-only and follow the controller session.


### DUI virtual cursor implementation

The DUI page-side cursor is shipped as plain browser JavaScript (`html/cursor.js`,
`html/keys.js`, `html/scroll.js`) so FiveM CEF can load it directly without a
TypeScript/Vite build step. It follows the `kkMihai/fivem-dui-virtual-cursor-example`
architecture: Lua moves CEF's mouse position, the page draws the virtual cursor,
and keyboard/scroll behavior is synthesized inside the DUI document.

## Chain mode (multi-game sequences)

Run several minigames back-to-back — perfect for heists and multi-stage
jobs. Blocking; returns `success, completed, total`.

```lua
CreateThread(function()
    -- simple: list of ids, shared difficulty
    local success, completed, total = exports.eye_minigames:PlayChain({
        { game = 'keypad', difficulty = 2 },
        { game = 'livewire', difficulty = 3 },
        { game = 'vaultspin', difficulty = 4 }
    }, {
        allowCancel = false
    })

    if success then
        print("All security layers bypassed!")
    else
        print(string.format("Failed at step %d of %d", completed + 1, total))
    end
end)
```

Per-stage control (different game settings each step):

```lua
exports.eye_minigames:PlayChain({
    { game = 'lockpick',     difficulty = 2 },
    { game = 'breachmatrix', difficulty = 4 },
    { game = 'override',     difficulty = 5, allowCancel = false }
})
```

Chain options: `difficulty`, `allowCancel`, `stopOnFail`
(default `true` — stop the moment a stage is failed).

---

## Options

Every call takes an options table. All fields optional.

| field | type | default | notes |
|-------|------|---------|-------|
| `difficulty` | number 1–5 | per-game (config.lua) | scales speed/size/timer |
| `allowCancel` | bool | `Config.AllowCancelByDefault` | ESC to bail |

Per-game extras:

| game | extra option | default |
|------|--------------|---------|
| `skillcheck` | `rounds` | 2 + diff/1.5 |
| `flatline` | `rounds` (shocks needed) | 3 |
| `deadcalm` | `shots` | 3 |
| `vaultspin` | `tumblers` | 2 + diff/2 |
| `bluff` | `hands` | 3 |

All advanced games are driven purely by `difficulty` (1–5) — no extra
options needed.

---

## Test in-game

Test commands are on by default (`Config.EnableTestCommands`). Turn the
flag off in `config.lua` for production.

```
/mg <id> [difficulty]   play one game, e.g. /mg lockpick 4
/mglist                 list every game id by category
/mgrandom [difficulty]  play a random game
/mgall [difficulty]     play every game back-to-back (QA sweep)
```

Results print to console and chat. The commands have chat autocomplete
suggestions.

---

## Sound

Synthesized sound effects (Web Audio — no audio files, zero extra deps).
Clicks, ticks, success/fail stings, and per-game cues are built in.

Global toggles in `config.lua`:

```
Config.Sound  = true    -- master on/off
Config.Volume = 0.5     -- 0.0 - 1.0
```

Override per call:

```
exports.eye_minigames:Play('lockpick', { difficulty = 3, sound = false })
exports.eye_minigames:Play('mining',   { difficulty = 2, volume = 0.8 })
```

---

## Notes

- Core skill checks remain client-side. `server/main.lua` is a stub for your own
  anti-abuse hooks (rate-limiting etc.); synchronized world DUI sessions are
  handled separately by `server/dui.lua`.
- Built on canvas + vanilla JS NUI. Zero external runtime deps.
- One game runs at a time; concurrent calls return `false` immediately.


## DUI orientation notes (2.6.0)

- Two-coordinate DUI: the `heading` in the first `vector4` is the direction the camera faces. The camera is placed on the opposite side of the screen and looks toward the center.
- `prop_monitor_01b`: the screen is 90 degrees left of the prop entity forward vector, so the prop DUI camera and screen plane use that orientation.
- Prop DUI texture replacement waits for the source texture dictionary and stabilizes the CEF/runtime texture before applying `AddReplaceTexture`. `prop_monitor_01b` uses `prop_desk_monitor` as its texture dictionary.


## DUI fixes in v2.7.0

- DUI runtime textures no longer depend on a returned value from `CreateRuntimeTextureFromDuiHandle`; the native is treated as a successful void-style call when it executes successfully.
- Removed the multi-second original-TXD streaming wait from prop DUI startup.
- Removed unnecessary startup waits after the DUI runtime texture is created.
- Two-coordinate DUI renders through `DrawSpritePoly` using the runtime DUI texture.
- `vector4(..., heading)` now controls the world-screen facing direction used by the camera.
- Prop DUI camera is flipped 180 degrees so it views the monitor from the front.
- Camera activation no longer adds an extra artificial delay after the DUI becomes available.

### Test commands

```text
/mgdui password 2 vector4(x1,y1,z1,heading) vector4(x2,y2,z2,heading)
/mgduiprop password 2
/mgduistop
```

`/mgdui` is the two-coordinate world DUI. `/mgduiprop` replaces the configured existing prop texture.
