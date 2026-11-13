# Yuri Lua SDK 1.0 — platform foundation

Scripts use a separate managed Lua 5.2-compatible interpreter (MoonSharp), not the game's LuaJIT state. LuaJIT-specific FFI and unrestricted game calls are deliberately unavailable. This is the first host API. The goal is community-created gameplay features, not only UI extensions. See ROADMAP.md for the planned gameplay layer; it is not implemented by this release.

## Try the example

Copy `../examples/hello` into `Scripts/hello` beside YuriLauncher.exe. Open **Script library → Installed**, choose **Rescan scripts**, then **Review & enable**. Confirm the exact file hash and requested permissions. Every launch starts scripts OFF. Disable stops its worker and removes its controls. Changes to source, manifest or translations disable it until reviewed again. Downloads require an explicit click; scripts never auto-enable. The Browse tab can read a curated community catalogue once its repository is configured. See `PUBLISHING.md`.

To display the controls in Aniimo, choose the new matching Aniimo package using **Choose Yuri file**, enable **Show approved script controls in Aniimo**, and load the matching menu. In-game controls appear under **Misc → Scripts**. The connection expires when the launcher stops; stale session tokens and input outside the published control types/ranges are rejected. Loftia can use the launcher-side manager, but does not yet have this in-game adapter.

## Files and permissions

Each folder needs `script.json` and `main.lua`. IDs are unique lowercase names; `api` must be `1.0`; `game` is `Aniimo`, `Loftia` or `Any`. Optional `Locales/fr.json`, etc. are plain key/string maps used by `yuri.tr` (different from the launcher language-pack envelope). Each package may have 32 translation files. The manager binds identity to the package; Lua cannot select another owner.

Permissions: `ui`, `notifications`, `storage`, `session`. A changed hash requires new approval. Authors are self-declared, not verified signatures. Scripts get no arbitrary files, HTTP, shell, CLR/Unity objects, native DLLs, bytecode loader or debug API. A script's settings cannot name a file or access another installed script folder's data. Storage and approvals are bound to the script ID and its installation folder; moving a script folder starts fresh settings.

## API

- `yuri.ui.label(id, text)`, `toggle(id, text, default)`, `slider(id, text, min, max, default)`, `button(id, text)` return a handle. Use `handle.get()` and `handle.set_text(text)` with dot syntax.
- `yuri.on("control", callback)` receives `event.id`; read the handle for its value.
- `yuri.on("tick", callback)` runs roughly once per second. `event.seconds` is UTC Unix time; approved `session` access adds the selected game and client.
- `yuri.on("session", callback)` receives the initial selected game/client. Selection is launcher context, not verified presence in a gameplay scene.
- `yuri.notify(text)` produces an owner-labelled launcher notification. It does not impersonate an official game message.
- `yuri.storage.get(key)` / `set(key, string)` store up to 64 bounded strings, with a 32 KB total per script. Settings persist between sessions but scripts do not auto-enable.
- `yuri.tr(key, fallback)` selects a script's own translation, with fallback.

Maximum eight active scripts, 24 controls each, 256 API calls per request, bounded instruction slices and a 2.5-second response deadline. Each worker has a 128 MB process-memory limit, one-process job limit, restricted UI access and a low-integrity impersonation context with privileges removed on the interpreter thread. Elevated launcher sessions cannot enable scripts. Workers do not run inside Yuri's core or the game's VM. These measures are defense in depth, not an independently audited guarantee against all interpreter/runtime vulnerabilities.

Use VS Code's Lua extension with `../sdk/yuri.d.lua` and the root `.luarc.json` for autocomplete. Runtime source errors appear in the manager; file paths and OS secrets are not part of the API. This preview has no general gameplay-action, entity, drawing, dependency or networking API. Those require separately designed, validated host adapters.

## Platform scope and localization

API 1.0 is the implemented foundation. ROADMAP.md describes the broader gameplay SDK target and separates planned modules from current APIs.

Launcher localization work and its final volunteer template are paused while the interface develops. Existing fallback catalogues are retained internally.

Optional display metadata in script.json: `description`, `category` and `version`. These do not grant capabilities.
