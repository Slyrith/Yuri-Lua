# Workflows: build automation one step at a time

Introduced in private SDK helpers **1.2.1**, retained in **1.2.2**, using the existing API **1.2** manifest and host protocol. Aniimo and Loftia share these helpers; each host still decides which game data and actions it supports. This increment has offline worker checks, not live SDK gameplay verification. [Action tasks](ACTION-TASKS.md) now provide reusable travel/equipment observations that can be composed with a workflow condition step.

In **Script library → New script**, select Aniimo or Loftia and **Game — one resource workflow**. The launcher fills in the permissions. Your script starts OFF. Review it, enable it, then press its Collect button near an ordinary resource.

## A small example

```lua
-- Permissions: game.read, entities.read, actions.interact, ui.
local target
local job = yuri.workflow.new("Collect once")
job:delay(3) -- Switch back to the game and hide its menu.
job:run(function()
    local rows = yuri.entities.list("resources", 6)
    assert(#rows > 0, "Stand near a resource first.")
    target = rows[1].handle
end)
job:request(function()
    return yuri.actions.interact(target)
end, 5)
job:on_finish(function(result)
    print(result.state, result.message)
end)

yuri.button("Start", function() job:start() end)
yuri.button("Stop", function() job:cancel() end)
```

`request` waits for the matching action result, so the next step does not run merely because a request was queued. **An accepted request is not proof that loot arrived, a tool equipped or travel finished.** Add `wait_until` with an appropriate observed condition when needed. A disappearing nearby resource is not an inventory receipt: moving out of range can also remove it from that snapshot.

## Methods

| Method | What it does |
| --- | --- |
| `yuri.workflow.new(name)` | Creates an idle workflow. Does not perform actions. |
| `job:run(fn)` | Adds a short Lua step. An error stops this workflow. |
| `job:delay(seconds)` | Adds a delay without blocking the worker. |
| `job:wait_until(fn, timeout?)` | Continues only when the predicate returns exactly `true`; default timeout 10 seconds. |
| `job:request(fn, timeout?)` | Calls once; `fn` must return an ID from `yuri.actions`. Waits for acceptance/decline; default 5 seconds. |
| `job:on_finish(fn)` | Receives a copied final status after completion, decline, error, cancellation or timeout. |
| `job:start()` | Returns `true`, or `false, reason` if no ready game is connected. Requires `game.read`. |
| `job:cancel()` | Stops remaining steps. Cannot recall requests already sent to the host/game. |
| `job:status()` | Returns copied `name`, `state`, `step`, `total`, `message` and optional `last_result`. |
| `job:dispose()` | Cancels and frees the workflow slot. A disposed object cannot restart. |

States: `idle`, `running`, `waiting`, `completed`, `declined`, `failed`, `timed_out`, `cancelled`, `disposed`. Completed means the scripted steps finished; choose observation steps that match the effects you actually need.

## Limits and cleanup

- Four workflow objects per script; 24 steps each. Dispose unused objects.
- Delays/timeouts from 1 to 60 seconds; a run lasts at most five minutes.
- At most one new step per workflow per tick. Ticks normally arrive about once per second.
- No built-in repeats, native retries, purchases, releases or item creation.
- Game/world/process changes or loss of a ready host cancel remaining steps. A non-sensitive worker-local `revision` in `yuri.game.state()` makes a same-world process restart distinguishable without exposing bridge IDs.
- Stopping/reloading the script terminates its worker, including workflows and callbacks. Existing host leases and their expiry rules are unchanged.
- A timeout/decline requires an explicit new start. Scripts cannot edit or restart a running workflow.
- Functions retain all existing permissions and action limits. Workflows provide no filesystem, network, CLR, process-memory or game-Lua access.

Do not use a blocking loop inside a step. Its normal instruction budget still applies. A normal callback error stops that job; an instruction/memory-budget failure may terminate the script worker.
