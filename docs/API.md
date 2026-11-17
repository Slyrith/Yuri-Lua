# Yuri Lua API 1.2 — private development

The private 1.2 worker adds [gameplay APIs](GAMEPLAY.md) and six gameplay starters: nearby markers, Aniimo feature composition, Aniimo ability/health logic, Loftia own-garden farming, Loftia owned tools/seeds and Loftia resource assistance. These need the matching new trusted game host; public 0.11.0 and existing game DLLs do not provide that adapter. The 1.0/1.1 APIs below remain compatible.

Requires Yuri Launcher 0.11.0+. API 1.0 manifests and positional calls remain supported. UI-only scripts can declare `"api": "1.1"`; gameplay scripts use `"api": "1.2"`. Private helpers 1.2.2 add [observed action tasks](ACTION-TASKS.md) alongside [workflows](WORKFLOWS.md), requiring their matching updated worker/launcher.

## Simple controls

```lua
local label = yuri.label("Ready")
local button = yuri.button("Run", function() print("Clicked") end)
local enabled = yuri.toggle("Enabled", false, function(value) print(value) end)
local amount = yuri.slider("Amount", 1, 20, 5, function(value) print(value) end)
```

These assign IDs in creation order. For explicit stable IDs, existing `yuri.ui.label(id,text)`, `button(id,text,callback?)`, `toggle(id,text,default,callback?)`, and `slider(id,text,min,max,default,callback?)` remain available.

- `handle:get()` returns a toggle's boolean or slider's number; other controls return nil.
- `handle:set(value)` updates a toggle/slider without triggering its change callback. Type and bounds are enforced.
- `handle:set_text(text)` changes the label (up to 240 characters).
- `button:on_click(callback)` attaches/replaces its click callback.
- `toggle:on_change(callback)` / `slider:on_change(callback)` attaches/replaces its change callback, receiving the new value.

Handle methods accept both colon and dot syntax. A callback setter returns the handle for chaining. Existing explicit-ID code continues to work. These callbacks do not replace a legacy `yuri.on("control", ...)` handler; both can run if you register both.

## Events

- `yuri.on("session"|"tick"|"control"|"action"|"game"|"entities"|"farming"|"tools"|"abilities"|"resources", callback)` preserves API 1.0's single legacy handler for that event; registering another replaces it.
- `cancel = yuri.events.subscribe(event, callback)` adds an independent listener. Call `cancel()` to unsubscribe. At most 32 active subscribers per event.
- Control events include `event.id` and `event.value`. Tick/session payloads follow the existing approved session contract. Session means launcher game/client selection, not proof of a gameplay state.

## Timers

- `cancel = yuri.after(seconds, callback)` runs once when due on a host tick.
- `cancel = yuri.every(seconds, callback)` repeats while enabled.
- `yuri.time()` returns monotonic elapsed seconds in this worker session.

At most 16 active timers. Seconds must be from 1 to 86400. Host ticks occur roughly once per second; delays can be longer when busy. No exact subsecond scheduling or burst catch-up. Calling `cancel()` is safe more than once. Stopping the script destroys its worker, listeners and timers.

## Settings

With `storage` permission:

```lua
local count = yuri.settings.get("count", 0)
yuri.settings.set("count", count + 1)
```

Supported values: finite numbers, booleans and text. Keys follow the existing lowercase ID rules. Encoded values share the existing 1024-character per-value, 64-key and 32 KB storage limits. Typed values are stored as bounded strings; legacy `yuri.storage.get/set` remains available. API 1.0 strings stay readable. Settings and approvals remain scoped to script ID plus installation folder.

## Notifications and logging

- `yuri.notify(text)`: up to four owner-labelled notifications per update, 500 characters each; requires `notifications`.
- `yuri.log(text)` or `print(...)`: up to four local log messages per update, 500 characters each. Logging needs no extra permission and gives no arbitrary filesystem access.
- Runtime errors appear in the script manager. Source-line errors use `main.lua` line numbers. Permission/type/bounds messages include useful hints.

## Permissions and limits

Foundation permissions are `ui`, `notifications`, `storage`, `session`; private gameplay permissions are listed in [GAMEPLAY.md](GAMEPLAY.md). Manifest API version may be 1.0, 1.1 or 1.2 in the private worker. No unrestricted files, HTTP, shell, CLR, raw native calls, bytecode or game VM access was added. Resource limits and exact-version approval still apply. At most eight active script workers and 24 controls per script; 256 API calls per request; bounded instruction slices and a 2.5-second host response deadline. Repeated errors stop the affected script rather than retry forever.

The interpreter sandbox has not had an independent security audit. Hash verification checks consistency, not author intent. Gameplay data/actions need the matching trusted adapter; the private Aniimo source adapter is implemented but live testing remains pending.
