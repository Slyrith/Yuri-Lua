# Yuri community gameplay platform

> Current status (November 17, 2026): basic live read/request/observed-travel/disable checks passed in both Steam games. Broader actions and lifecycle checks remain pending. Earlier implementation-stage notes below are historical; see [compatibility](COMPATIBILITY.md) and [progress](PROGRESS.md) for the current evidence.


## Private 1.2 implementation

### Helpers 1.2.2 increment — November 15, 2026

Typed tasks now observe travel arrival for both games and owned-tool equipment state for Loftia, using fresh distinct bridge snapshots after a correlated accepted request. Missing, repeated, regressing or stale snapshots do not create confirmations. Tasks have explicit status, cancellation, bounded timeouts and no automatic retries. A beginner travel template, both-game examples and an equipment example accompany the helpers. Observation is evidence of copied state, not proof of server authority, causation or inventory gain. See [ACTION-TASKS.md](ACTION-TASKS.md). The basic live Steam read/travel/disable route subsequently passed in both games; lifecycle and broader outcomes remain pending.

### Helpers 1.2.1 increment — November 15, 2026

Sequential workflows now compose existing permissioned APIs for both games. They provide short Lua steps, condition waits, one request plus correlated acceptance/decline, delays, cancellation, status and finish callbacks. A per-worker context revision stops pending work on game/world/process/readiness changes; it does not expose transport identities. The worker also clears leases on game and readiness changes. A beginner creator template, editor declarations and dedicated regression suites accompany the implementation. See [WORKFLOWS.md](WORKFLOWS.md) and [PROGRESS.md](PROGRESS.md). This is a private source/build increment, not a public runtime release or general gameplay certification.

The launcher worker now implements copied player/entity queries, typed interaction/teleport requests, result events, owner-scoped boolean feature leases and entity-attached labels. Aniimo and Loftia host source adapters are connected and tested in isolation. Aniimo source compiles in the Steam Lua runtime; Loftia compiles as a native DLL and publishes owned-bed state through a data-only bridge. Change-driven game/entity/farming/tools/abilities/resources events, Aniimo owned ability/resource readings, Loftia loaded-resource metadata, a full-cycle farming starter and owned tool/seed selection are implemented. Selection requires its own action permission and rechecks normal ownership/input gates. This is not installed in the game or publicly released. See [GAMEPLAY.md](GAMEPLAY.md).

Global PC is not installed locally. The matching private bridges subsequently passed the basic live route in both Steam games; logged-in Global/CN SDK gameplay remains unverified. Inventory summaries, individual crop actions, full inventory quantities, broader item APIs, numeric feature settings and free-form movement remain future work. The original roadmap below describes the broader target, not a list of finished capabilities.

The intended scope is a platform where authors can create their own gameplay features and automation. UI extensions are the first foundation, not the final product scope.

## Available in API 1.0

- Script discovery, exact-version review, enable/disable and reload.
- Script-owned controls, notifications, private saved settings and launcher session/tick events.
- A separately executed Lua interpreter and a narrow data bridge for matching Aniimo menus.

These foundation APIs are documented in README.md and ../sdk/yuri.d.lua. API 1.0 alone does not expose gameplay actions or raw game entities; the private 1.2 implementation described above adds its own permissioned modules.

## Broader target — partly implemented privately, not shipped

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
