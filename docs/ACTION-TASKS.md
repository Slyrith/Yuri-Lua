# Action tasks: wait for an observed effect

Private helpers **1.2.2**, manifest/API **1.2**. Requires the matching updated desktop launcher and worker, plus the existing private game adapter. Updating a manifest or downloading these docs does not update an older worker.

Choose **Script library → New script → Game — travel and observe**, select Aniimo or Loftia, and create the script. It starts OFF. Review its permissions before enabling. Press Travel once near a loaded resource, then return to the game and hide its menu during the three-second preparation delay. Stop cancels the remaining observation; it cannot recall a sent request.

## Travel in either game

```lua
-- Permissions: game.read, entities.read, actions.teleport.
local nearby = yuri.entities.list("resources", 100)
assert(#nearby > 0, "No loaded resource nearby.")
local travel = yuri.tasks.teleport(nearby[1].handle, {
    timeout = 15, radius = 3, samples = 2
})
travel:on_finish(function(result)
    print(result.state, result.message)
end)
local started, reason = travel:start()
if not started then print(reason) end
```

Constructing a task sends nothing. `start` sends one existing guarded teleport request. A matching accepted result changes the task from `waiting` to `observing`. It then needs two distinct, fresh snapshot samples showing the local player's position within three metres of the captured destination. The player must also have moved at least 0.25 metres from the start position. The acceptance snapshot itself does not count as a later observation.

**`observed` means the requested state was seen.** It does not prove server authority, identify what caused the movement, or verify collection/inventory gain. Travel can still be declined by the host/game. Moving targets are checked against their position captured at task start. If you start inside the radius, the result is `already_satisfied`, `observed` is false and nothing is sent.

## Equip a currently owned tool in Loftia

```lua
-- Permissions: game.read, tools.read, actions.equip.
local cans = yuri.tools.list("watering_can")
assert(#cans > 0, "No owned watering can in this snapshot.")
local select = yuri.tasks.equip(cans[1].handle, {timeout = 10})
select:on_finish(function(result)
    print(result.state, result.message)
end)
local started, reason = select:start()
if not started then print(reason) end
```

An accepted equip request alone is insufficient. Two distinct fresh snapshots must list that same owned tool as equipped. An already equipped tool returns `already_satisfied` without an action. A disappearing tool is not successful equipment selection. Aniimo currently has no tool/equip adapter; this helper does not add one.

## Methods and results

| Method | Behaviour |
| --- | --- |
| `yuri.tasks.teleport(handle, options?)` | Creates an idle travel task for a loaded entity. Both games. |
| `yuri.tasks.equip(handle, options?)` | Creates an idle owned-tool task. Loftia only. |
| `task:start()` | Returns `true`, or `false, reason`. Requires a fresh ready snapshot and the documented permissions. An immediate no-op or failure may invoke `on_finish` before returning. |
| `task:status()` | Copied `kind`, `state`, `message`, `request_id`, `accepted`, `observed`, `samples`, `elapsed`. |
| `task:on_finish(fn)` | One callback for each started task that reaches a terminal state. Register before starting. |
| `task:cancel()` | Stops pending observation. A sent action may still finish. |
| `task:dispose()` | Cancels and frees the object slot. Idempotent; disposed objects cannot restart. |

States: `idle`, `waiting`, `observing`, `observed`, `already_satisfied`, `declined`, `timed_out`, `cancelled`, `failed`, `disposed`.

Four task objects per script, separate from the four workflow objects. Dispose unused objects. Timeouts: 1–60 seconds, default 15. Consecutive samples: integer 2–5, default 2. Travel radius: 1–10 metres, default 3. Unknown options are rejected. No automatic retries. Timeout includes waiting for acceptance. A timeout or decline needs an explicit new start. An early validation failure returns `false, reason`, sets status to `failed` and clears any earlier success. It does not invoke `on_finish` because the attempt did not start.

Do not restart, dispose or replace the callback from inside its finish callback; do that later from a button or another update. Ordinary callback errors are contained, but the worker's instruction/memory limits can still terminate a script.

## Freshness and context

The desktop bridge validates native snapshot identity, expiry and bounded data before sending a permissioned view to the worker. `yuri.game.state()` adds `sample` and `sample_age` for `game.read` scripts. `sample` is a worker-local counter of distinct increasing validated snapshot expiry stamps, **not a render-frame counter**. Duplicate events do not make a sample fresh again. Missing or regressing stamps cannot count as a new observation. A snapshot older than three seconds cannot confirm a task or start a new one; stale data resets the consecutive-match count. No fresh data eventually means timeout.

Game, world, process-instance or readiness changes cancel active tasks. The worker exposes only its context revision, sample counter and sample age; the native token, instance identity and raw expiry stamp are not available through `game.state()`. Script stop/reload terminates the worker. Existing permissions, action limits, ownership checks and host cleanup remain in force.

## Combine with a workflow

Create the task in a `run` step, start it there, then use `wait_until` to detect a terminal result. For example, a predicate can return true on `observed` or `already_satisfied` and raise an error on `declined`, `failed`, `cancelled` or `timed_out`. Cancel/dispose the task from the workflow's finish callback too: the two objects have separate lifetimes. Never treat `accepted == true` as arrival.

This increment is verified offline using real worker processes and mocked game snapshots. The complete script → desktop → game → observed-state route still needs live checks on both games.
