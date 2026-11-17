# Gameplay API 1.2 — private development

> Current status (November 17, 2026): basic live read/request/observed-travel/disable checks passed in both Steam games. Broader actions and lifecycle checks remain pending. Earlier implementation-stage notes below are historical; see [compatibility](COMPATIBILITY.md) and [progress](PROGRESS.md) for the current evidence.


For automation that waits between requests, use the new [workflow helpers 1.2.1](WORKFLOWS.md). They reuse these APIs and permissions, and distinguish a queued request from its acceptance result. `yuri.game.state().revision` is available with `game.read`; it changes when the worker observes a different game/world/process context or readiness state. It is an opaque worker-local counter, not a bridge token or native identifier.

This adds gameplay access to the launcher worker, an Aniimo Lua host adapter and a compiled Loftia native host adapter. It is private development, not a public release. Both adapters passed offline tests; live gameplay integration is still required. Existing public game DLLs do not include these new adapters.

These functions return unavailable until the matching private host is connected. The Loftia adapter runs on its existing game-thread callback; community Lua remains in the separate worker and is never evaluated inside the game. No upload or public release is needed during development.

## The boundary

Community code still runs in the separate limited worker. It receives copied JSON data and opaque entity handles. It receives no game objects, pointers, CLR, native functions, filesystem paths, bridge tokens or access to the game's Lua VM. The launcher and game host both validate requests. Local files are an IPC transport, not a defence against malware already running as the same Windows user. This has not had an independent security audit; do not promise a perfectly secure ecosystem.

## Permission names

| Permission | Grants |
| --- | --- |
| `game.read` | Controlled character position and available HP fields. |
| `entities.read` | Up to 128 nearby loaded entities, names, kinds, positions, distances and available HP. |
| `actions.interact` | Request a normal, currently available loot interaction on a loaded target. |
| `actions.teleport` | Request the existing guarded Yuri destination path for a loaded target. |
| `features` | Lease the allowlisted existing feature switches below. |
| `render` | Up to eight custom labels attached to loaded entities. |
| `farming.read` | Loftia's nearby owned garden beds: capacity, planted/dry counts and harvest readiness. |
| `tools.read` | Loftia's normal owned-tool enumeration: seed/tool types, equipped state and remembered farming seed. |
| `actions.equip` | Request normal equipment selection for an opaque owned-tool handle. |
| `abilities.read` | Aniimo's observed owned ability IDs/types, costs and known client readiness checks. |
| `resources.read` | Loftia loaded-resource availability, configuration tag, required tool tags and known loose-pickup quantity. |

The existing UI, notifications, storage and session permissions remain separate. Changed code or permissions requires a fresh review. Scripts start OFF.

## Read the world

```lua
local label = yuri.label("Waiting for game")
yuri.every(1, function()
    if not yuri.game.state().ready then return end
    local player = yuri.player.get()
    local nearby = yuri.entities.list("resources", 30)
    label:set_text("Nearby resources: " .. #nearby)
end)
```

Requires `ui`, `game.read`, and `entities.read`. `entities.list(kind, metres)` accepts nil for all supported kinds, with a maximum of 500 m. This only sees entities actually loaded in the current world. Snapshots reach scripts roughly once per second; they are not live object references. Positions and distances use metres, with each game's axis convention preserved (Loftia uses Z for height).

`yuri.game.state()` returns `ready` and approved capability names. It includes `game` with `session` or `game.read`, and `world` only with `game.read`. It never returns the transport token, internal instance identifier, entity arrays, garden arrays or player object. Query those through their separately permissioned modules.

## Request an interaction or teleport

```lua
yuri.button("Pick up closest resource", function()
    if not yuri.game.state().ready then return end
    local items = yuri.entities.list("resources", 6)
    if #items > 0 then
        local request = yuri.actions.interact(items[1].handle)
        print("Queued:", request)
    end
end)

yuri.on("action", function(result)
    print(result.id, result.ok, result.message)
end)
```

Requires `ui`, `entities.read`, `actions.interact`. `yuri.actions.teleport(handle)` requires `actions.teleport` and uses the existing host travel checks. `ok` reports whether the normal request was accepted, **not** verified collection/arrival. The native game remains authoritative. There are no automatic native retries. A request expires after three seconds. Target/world changes, menus, unfocused gameplay, unsupported destinations, cost-bearing interactions and missing normal interaction reach decline requests.

Ordinary loot interactions and owned-tool selection are exposed as separate typed operations. There is no release/delete/sell/purchase endpoint, unrestricted inventory modification, or arbitrary function dispatcher.

## Compose existing Yuri features

```lua
local enabled = yuri.toggle("God mode", false)
yuri.every(1, function()
    if not yuri.game.state().ready then return end
    if enabled:get() then
        yuri.features.set("god_mode", true)
    else
        yuri.features.release("god_mode")
    end
end)
```

Requires `ui` and `features`. Call `yuri.features.available()` to discover the current host's supported names. Values are strictly booleans. This uses the existing controllers and inherits their known gameplay limitations. It does not repair their combat behavior or unlock unavailable energy/buff routes.

| Host | Feature names |
| --- | --- |
| Aniimo | `god_mode`, `no_cooldown`, `multi_hit`, `infinite_stamina`, `auto_loot` |
| Loftia | `auto_plant`, `auto_water`, `auto_harvest`, `farm_walk`, `auto_collect`, `auto_perfect_chests` |

A name available in one game is not automatically available in the other. This list describes adapter support, not fresh live verification of every underlying feature.

The first active owner of a feature holds the lease. Two scripts cannot overwrite each other's live lease. Stopping, editing or disabling a script removes its leases; loss of the launcher heartbeat expires them within four seconds plus a host poll. World/control changes clear them. The previous setting is restored only if the feature still matches what the script applied, so an intervening manual change is preserved.

## Custom resource markers

```lua
yuri.every(1, function()
    if not yuri.game.state().ready then return end
    yuri.render.clear()
    local rows = yuri.entities.list("resources", 30)
    for i = 1, math.min(8, #rows) do
        yuri.render.marker("node" .. i, rows[i].handle, rows[i].name, "#a8e0ce")
    end
end)
```

Requires `entities.read`, `render`. `render.remove(id)` removes one marker. The existing Aniimo ESP renderer must be enabled for these labels; its map/menu suppression and overall label budget also apply. Loftia draws script markers through its native overlay independently of the normal ESP toggle. Projection uses the current camera on each rendered update. Markers disappear if the target leaves, the script stops, or the bridge expires. Color is `#RRGGBB`; text is plain and bounded to 120 characters.

## Loftia: build your own farming workflow

Choose **New script → Loftia → Own-garden farming** to create the full starter. Equip the seeds you want to use in the game first. The starter starts OFF and leases the existing planting, watering, harvesting and bounded walking controllers when enabled. It releases its leases when disabled or when no owned beds are visible.

`yuri.farming.beds()` requires `farming.read` and returns up to 32 owned beds within the adapter's current entity snapshot. Every row has:

| Field | Meaning |
| --- | --- |
| `handle` | Opaque target handle; changes across game/world lifetimes. |
| `owned` | True for the local player's beds; account identifiers are not exposed. |
| `capacity` | Total planting slots. |
| `planted` | Occupied slots. |
| `dry` | Planted slots that currently need watering. |
| `harvestable` | Whether the normal controller reports a harvest available. |

For example, a script can water only while a bed reports dry crops:

```lua
local enabled = yuri.toggle("Water my dry beds", false)
yuri.every(1, function()
    if not yuri.game.state().ready then return end
    local dry = 0
    for _, bed in ipairs(yuri.farming.beds()) do
        dry = dry + bed.dry
    end
    if enabled:get() and dry > 0 then
        yuri.features.set("auto_water", true)
        yuri.features.set("farm_walk", true)
    else
        yuri.features.release("auto_water")
        yuri.features.release("farm_walk")
    end
end)
```

Permissions: `ui`, `farming.read`, `features`; manifest `game` is `Loftia`, `api` is `1.2`. These are existing host controllers, not direct per-crop commands. They enforce ownership, normal interaction checks, equipped seeds, water availability and walking bounds. Normal seeds and water are spent; scripts do not accelerate growth, create items or refill water. A visible bed is not a promise that the walking controller can reach it. This new SDK route still needs live validation.

## Loftia: select owned seeds and tools

Choose **New script → Loftia → Owned tools / seeds** for a small working starter. Its buttons request the next owned seed type or a watering can. After pressing one, return focus to Loftia and hide the in-game menu within three seconds. The delayed callback makes one request; a decline is reported rather than retried.

| Function | Permission | Returns |
| --- | --- | --- |
| `yuri.tools.list(kind?)` | `tools.read` | Copied list of currently available seed/tool types. Omit kind for all supported types. |
| `yuri.tools.equipped()` | `tools.read` | Matching equipped row, or nil. |
| `yuri.tools.farming_seed()` | `tools.read` | The seed tag remembered by the existing farming controller, or nil. |
| `yuri.actions.equip(handle)` | `actions.equip` | Request ID; observe its `action` result. |

Rows contain only `handle`, `kind`, `tag`, `equipped`. Kinds are `seeds`, `watering_can`, `hammer`, `pruner`, `locator`. `tag` is the game's plain configuration identifier, not a localized item display name. The native adapter checks at most 256 normal owned-tool handles and returns up to 32 unique types. Equal tags are combined: **these rows are not individual stacks, quantities, hotbar slots or a full inventory dump**. No quantities are guessed. A tool outside this bounded snapshot may be absent even if owned.

```lua
-- Run from a callback while Loftia has focus and no game menu is open.
-- Permissions: tools.read, actions.equip.
local seeds = yuri.tools.list("seeds")
for _, seed in ipairs(seeds) do
    if seed.tag == "ItemConfig.Crop.Vegetables.Lettuce" then
        local request = yuri.actions.equip(seed.handle)
        print("Lettuce selection requested:", request)
        break
    end
end
```

The host re-enumerates owned handles before equipment selection, applies the normal game equip gate and rejects stale inventory/world contexts, active tools, ongoing farm/tool actions, manual movement/interaction input and selections less than 750 ms apart. No supplied raw tag, slot, pointer or item ID is accepted as an equip target. Read permission does not authorize equipping. Existing focus/menu/dialogue/minigame restrictions also apply.

`ok=true` reports acceptance or an already-equipped type, not confirmed replication. Query the next equipped snapshot for confirmation. Equipment selection is a discrete normal action; disabling a script does not undo a completed selection. Costs, ownership, item creation and inventory quantities are unchanged. The farming controller learns a normally equipped seed through its existing path; Lua cannot write its internal seed setting directly. This adapter route still needs a live check.

## Change-driven events

Use `yuri.on(name, callback)` or `yuri.events.subscribe(name, callback)`:

| Event | Permission | Payload and trigger |
| --- | --- | --- |
| `game` | `game.read` | `{ready, game?, world?}` when connection/world identity changes. |
| `entities` | `entities.read` | `{count}` when the copied entity snapshot changes; query `entities.list()` for data. |
| `farming` | `farming.read` | `{beds}` when the copied bed state changes, including an empty array on disconnect. |
| `tools` | `tools.read` | `{items, farming_seed}` when owned tool types, equipped state or the remembered seed change. Empty list/seed on disconnect. |
| `abilities` | `abilities.read` | `{items}` when observed owned ability metadata changes. |
| `resources` | `resources.read` | `{items}` when loaded resource metadata changes. |
| `action` | Matching action permission | `{id, ok, message}` for that script's result. |

Callbacks follow the launcher's roughly one-second update cycle. They share instruction/API budgets and are not frame-accurate engine hooks. Identical snapshots do not repeatedly fire a change event. Subscribing to an event does not grant its data permission. Existing `tick`, `session` and `control` events remain available.

## Aniimo: ability data and conditional feature logic

`yuri.abilities.list()` returns up to 32 abilities found in the controlled owned character's current ability maps. Each row has the observed configuration `id` and native `type`, plus optional `energy_cost`, `ultimate_cost`, `state_allowed`, `cooldown_ready`, `cost_available`, `ready`. It requires `abilities.read`; it does not grant player or entity access.

Foreign ability objects and unrecognized entries are skipped. Missing getters/checks stay absent, not zero or false. `ready` is present only when all three checks returned booleans, and combines them. These are current client checks, which may reflect active Yuri modifiers; they do not guarantee target/range validity, animation readiness, damage or server acceptance. The SDK does not infer which key is Q/E/R and has no arbitrary cast endpoint.

With separate `game.read` permission, `yuri.player.get()` can include Aniimo's `energy` and `ultimate_charge` if their native getters return valid readings. No resource is written or preserved by these queries.

**New script → Aniimo → Ability / health helper** demonstrates real feature composition: it shows the available readiness/energy readings and optionally leases the existing God mode controller below 30% HP. The toggle starts OFF and releases the lease above the threshold or when readings are unavailable. This inherits that controller's known limitations and the roughly one-second SDK update interval; it is not guaranteed emergency protection.

```lua
-- Permissions: abilities.read.
for _, ability in ipairs(yuri.abilities.list()) do
    if ability.ready == true then
        print("Client checks ready:", ability.id, "Energy cost:", ability.energy_cost)
    end
end
```

## Loftia: resource metadata and compatible tools

`yuri.resources.list()` requires `resources.read`. It returns up to 32 records from the current loaded entity snapshot, further limited by the bounded response size. Rows contain `handle`, `kind`, `distance`, `available`, `tool_tags`, and optional `tag`/`quantity`. Availability uses the existing host predicate, so unreadable/depleted/hidden resources are not treated as collectable. This is not a global spawn list or a respawn timer.

`quantity` is included only for a valid observed loose-pickup quantity field. It is not inferred for gathering nodes, seed stacks, unopened containers or unknown values. Up to four unique required Hammer/Pruner/Locator tags are copied from normal node data. No quantities, node availability or timers are changed.

**New script → Loftia → Resource assistant** marks available loaded materials and provides a button to select an owned tool compatible with the closest tool node. It requires `resources.read`, `tools.read`, `actions.equip`, `render`, `ui` and `notifications`. Return focus to the game during its three-second handoff. It requests ordinary equipment selection only; it does not harvest the node, extend reach or promise that every loaded node is reachable.

```lua
-- Permissions: resources.read.
for _, resource in ipairs(yuri.resources.list()) do
    if resource.available and resource.quantity ~= nil then
        print(resource.tag or resource.kind, resource.quantity)
    end
end
```

The selected-game guard also applies between launcher timer updates: a game-specific script cannot receive data, events or accepted action requests for another selected game. These new routes passed offline binding, broker and worker checks; broader live gameplay coverage remains pending; the basic Steam route is recorded in COMPATIBILITY.md.

## Still outside this increment

Full inventory/seed-stack quantities, individual crop targeting/commands, normal cast/gather action APIs, broader item/tool APIs, custom combat algorithms, numeric feature settings, free-form movement and broader end-to-end live validation. Authors can already compose owned seed/tool selection and conditional feature logic with the approved data, events, actions and existing controllers above; arbitrary native dispatch and unrestricted game-memory access are intentionally not exposed.
