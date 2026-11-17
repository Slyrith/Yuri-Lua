# Publishing scripts when ready

Updating this repository's SDK source does not require a GitHub release.
Do not publish script assets or edit catalogue entries merely to upload this SDK.
The following steps are for a later, intentionally reviewed script release.

1. Review the source, permission scope, supported host versions and redistribution rights.
2. Package the script without executing Lua:

```text
python tools/catalogue_tool.py package --script examples/quickstart --repo Slyrith/Yuri-Lua --tag YOUR-REVIEWED-TAG --output dist
```

3. When the release is actually ready, upload the generated script ZIP to a
   public GitHub release with that exact tag. Confirm the asset exists first.
4. Merge the generated `dist/catalogue-entry.json` proposal by script ID into
   the existing root `catalogue.json`. Do not replace a populated catalogue
   with the one-entry proposal. Do not invent download URLs or placeholder hashes.
5. Run `python tools/catalogue_tool.py validate`, commit the catalogue change,
   then refresh the launcher library. Downloads start OFF and require review.

## Supported format

- Manifest API: `1.0`, `1.1`, or `1.2`; games: `Any`, `Aniimo`, `Loftia`.
- Explicit permissions: `ui`, `notifications`, `storage`, `session`, `game.read`,
  `entities.read`, `actions.interact`, `actions.teleport`, `features`, `render`,
  `farming.read`, `tools.read`, `actions.equip`, `abilities.read`, `resources.read`.
  There are at most 15 unique grants. Request only what the script needs.
- Exactly one `script.json` and a root `main.lua`; only Lua source, JSON and docs.
  No symlinks, native binaries, bytecode or obfuscated loaders.
- Expanded content and compressed ZIP: at most 1 MB. At most 40 source entries;
  main Lua: 64 KB; manifest: 16 KB; 32 locale files at most 32 KB each.
- Optional display fields: description (500 characters), category (40), version (40).
- Catalogue schema 1: at most 200 scripts and 256 KB, unique IDs, supported GitHub
  release ZIP URLs and exact SHA-256 values. The hash checks consistency, not trust.

The package command does not upload files, change the live catalogue or execute Lua.
CI validates structure; it does not approve behavior or certify script security.
The catalogue is independent of the launcher's Stable/Beta game-package channel.
API 1.2 examples need the matching private worker/host described in COMPATIBILITY.md.

## Launcher connection

In the Official launcher, `ScriptLibrarySource.json` can contain
`{"repository":"Slyrith/Yuri-Lua"}`. A local `ScriptCatalogue.json` takes precedence.
UC remains an offline/manual-download edition. Existing catalogue entries are
preserved by this SDK update; no token, database or Discord login is needed.
