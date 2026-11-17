# Compatibility and tested scope

Snapshot date: November 17, 2026. Manifest/API: **1.2**. Helpers: **1.2.2**.
Yuri game-package versions, launcher versions and SDK versions are separate.

| Component | Requirement / evidence |
| --- | --- |
| Foundation API 1.0/1.1 | Preserved by the updated worker; UI/settings examples do not need a game adapter. |
| Gameplay API 1.2 | Matching updated desktop worker plus the selected game's SDK-capable host. Version 0.11.0 alone does not identify which private worker revision is installed. |
| Workflow/task helpers | The updated worker must embed the 1.2.2 helper sources. Editing a manifest cannot upgrade it. |
| Steam Aniimo | Basic live snapshot, declined request, accepted resource travel with observed arrival, and script-disable cleanup passed in the private matched pair. |
| Steam Loftia | Basic live snapshot, declined requests, one resource travel with observed arrival, and script-disable cleanup passed in the private matched pair. |
| Global/CN Aniimo | Logged-in SDK gameplay remains unverified. Isolated runtime compatibility is narrower evidence. |
| World change / launcher loss | Cleanup implementation has offline coverage; controlled live lifecycle and lease-restoration checks remain pending. |
| Equip / crop / inventory / combat | Tool-equipment tasks have offline coverage; specific crop operations, inventory deltas and normal skill casts remain incomplete or unverified. |
| In-game Lua manager | Planned. Loftia's current SDK controls are desktop-only. Do not advertise automatic in-game script-page synchronization yet. |

This repository contains authoring material, not launcher/game binaries.
Examples do not auto-enable or send gameplay actions merely because they are
downloaded. Review every script's permissions and use the game-specific capability
checks shown in the examples. Acceptance, observation and verified server outcome
are different results.
