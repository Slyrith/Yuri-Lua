# Yuri community gameplay platform

The intended scope is a platform where authors can create their own gameplay features and automation. UI extensions are the first foundation, not the final product scope.

## Available in API 1.0

- Script discovery, exact-version review, enable/disable and reload.
- Script-owned controls, notifications, private saved settings and launcher session/tick events.
- A separately executed Lua interpreter and a narrow data bridge for matching Aniimo menus.

These APIs are documented in README.md and yuri.d.lua. This release does not expose gameplay actions or raw game entities. Do not advertise them as implemented.

## Next platform layer — planned, not shipped

| Module | Intended capabilities |
| --- | --- |
| Game | Detect the active game, world/session state, adapter version and supported capabilities. |
| Player | Read local character state, position, inventory summaries and available tools/abilities. |
| Entities | Query supported entity categories, positions, distances and state using stable handles. |
| Events | Subscribe to supported world, entity, inventory, farming and interaction changes. |
| Actions | Request supported movement, interaction, tool selection and other game-specific actions. |
| Rendering | Build custom ESP labels, markers and other visual displays from approved game data. |
| Features | Compose supported Yuri functions into community automation and custom workflows. |

This should support meaningful scripts such as farming logic, tool switching, custom ESP and collection workflows. Each game's adapter must implement and test its actual data and actions; Lua syntax alone cannot supply a missing host capability.

## Host design

- The universal launcher owns discovery, permissions, scripts, editor documentation and worker lifetime.
- Each game-specific Yuri host supplies a versioned adapter with capability negotiation. Aniimo and Loftia can expose different supported modules.
- Scripts receive data snapshots and stable handles rather than CLR objects, process pointers or access to Yuri's internal Lua state.
- Gameplay requests are typed, permission-gated and associated with the correct game/session. Unavailable capabilities return an explicit unsupported result.
- Enabling a script with new capabilities requires a new review. Scripts cannot replace another script's controls/settings or invoke arbitrary system commands.
- Events, action queues and rendering need explicit budgets, cancellation, unload cleanup and live verification.

These boundaries protect the host while allowing a substantially broader gameplay API. The existing UI-only API is not a permanent restriction on the platform's goal.

JSON localization work is paused until the interface and feature catalogue settle. A final volunteer translation template will be prepared later.
