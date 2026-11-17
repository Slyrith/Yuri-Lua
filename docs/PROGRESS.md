# SDK progress — November 17, 2026

Current manifest/API contract: **1.2**. Current private helper revision: **1.2.2**. Compatible 1.0/1.1/1.2 scripts retain their existing APIs. Workflows require the updated worker; a manifest version alone does not add the helper to older launchers.

## What creators can build

| Area | Implemented privately | Remaining boundary |
| --- | --- | --- |
| Script manager | Discovery, review, enable/disable, reload, local creator form and catalogue tooling | Public catalogue/release curation is separate from implementation. |
| Authoring | Buttons, toggles, sliders, saved scalar settings, timers, subscriptions, examples, editor declarations | Localization expansion is paused by request. |
| Execution isolation | Separate restricted workers, permission review, bounded queues/callbacks/data and resource limits | No independent security audit; these controls are risk reduction, not proof against every hostile script/program. |
| Shared game data | Copied local-player/entity snapshots and capability negotiation | Only loaded, bounded supported data is available. |
| Game-specific data | Aniimo owned ability costs/readiness; Loftia owned beds, tools, seed selection and loaded resource metadata | No guessed inventory counts, resource yields or respawn times. |
| Gameplay requests | Existing normal interaction and guarded target teleport; Loftia owned-tool selection | Host/game checks decide. Acceptance is not verified collection, equip or arrival. No normal skill-cast API yet. |
| Feature composition | Owner-scoped Boolean leases, expiry and conditional restoration | Numeric settings are not exposed yet; underlying feature limitations still apply. |
| Display | Script controls, notices and bounded entity labels | General drawing/shapes/input APIs remain limited. |
| Workflows | Sequential steps, condition waits, one-request result waits, delays, Start/Stop/status/finish handling | No built-in retries; one step per tick; five-minute run limit. Sent actions cannot be recalled. |
| Observed tasks — new | Travel arrival observation in both games; owned-tool equip observation in Loftia; distinct fresh samples, cancellation and bounded timeouts | Observed state does not prove server authority, causation or collection. Basic live read/travel/decline/unload checks passed in both Steam games; world-change and launcher-loss checks remain pending. |
| Verification | Actual Official/UC worker tests, contract tests, isolated host tests and historical controller checks | The basic read/request/observed-arrival/disable route passed in both Steam games. World-change, launcher-loss and broader action outcomes remain pending. |

## Progression

1. **1.0 foundation:** manager, script isolation, owned UI/storage and basic events.
2. **1.1 authoring:** simpler controls, timers, multiple listeners, beginner tooling and declarations.
3. **1.2 gameplay platform:** permissioned snapshots/actions, host adapters, leases, markers and game-specific data for Aniimo/Loftia.
4. **1.2.1 workflow increment:** reusable automation sequencing and stronger context cleanup.
5. **1.2.2 observed-task increment:** typed travel and tool-equipment observations, private freshness metadata and beginner travel authoring. Implemented with offline coverage and the basic live Steam travel route in both games; no runtime release is made by this source update.

This is a working private gameplay-SDK prototype, beyond UI-only extensions. It is **not a finished public gameplay SDK**. A single percentage would hide the difference between implemented interfaces, actual game capabilities and live verification.

## Next, in order

1. **Finish lifecycle validation.** The matched private Steam builds passed read-only connection, busy declines without retries, one accepted resource travel with two-sample observed arrival, and script-disable cleanup in both games. Next check controlled world changes and launcher loss, including feature-lease restoration.
2. **Broader outcome data.** Add verified inventory deltas or specific crop-state outcomes where the game exposes them. Travel/equip observation now exists; request acceptance still does not prove collection or server authority.
3. **More game actions.** Add normal skill casts for Aniimo and specific crop/gather operations for Loftia, with native readiness, ownership, cost and input checks. Do not imply both games offer the same operations.
4. **Owned inventory summaries and numeric feature settings.** Expose verified counts and carefully bounded settings, with explicit permissions and reliable restoration. Do not infer missing fields.
5. **Developer diagnostics and release readiness.** Capability/version matrix, clearer unsupported-feature diagnostics, more independent sandbox review, then a reviewed SDK/catalogue release when Ary decides it is ready.

Private built workers/launchers are development outputs. Subsequent Steam live validation repaired transient Aniimo loader metadata and native UTC conversion failures. Both games now pass the basic read/request/observed-arrival/unload route; both live test scripts are OFF afterward. Loftia's current script controls are desktop-only; its in-game script page remains unimplemented. World-change/launcher-loss cleanup, specific crop operations, tool-equipment and other action types remain to be checked live. No gathering or inventory change is claimed from these travel tests. Nothing was uploaded or publicly released. CN/global logged-in SDK gameplay remains unverified.
