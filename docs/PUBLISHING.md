# Publish a script

## First release: Hello Yuri

The supplied first-release asset is `community.hello.zip`. It contains the exact current Hello Yuri source, not a new gameplay module. You can rebuild it from this repository:

```text
python tools/catalogue_tool.py package --script examples/hello --repo Slyrith/Yuri-Lua --tag sdk-v1.0.0 --output dist
```

1. Commit this repository starter with its empty root `catalogue.json`.
2. Create a GitHub release with the exact tag `sdk-v1.0.0`, title **Yuri Lua SDK 1.0 — Foundation**, and upload `community.hello.zip` as its release asset. The SDK is still foundation scope; describe that accurately in the release notes. You may label this development release pre-release.
3. Publish the release and confirm its asset downloads normally.
4. Only then copy the proposed entry from `dist/catalogue-entry.json` into the root catalogue's `scripts` array. For the first and only entry, the supplied proposal can replace the empty root catalogue. Keep existing entries when publishing later scripts.
5. Run `python tools/catalogue_tool.py validate`, commit the catalogue change, then refresh the launcher library.

If you use a different owner, repository name, tag or asset filename, rebuild the package metadata with those values. The URL and hash must describe the actual published ZIP. Do not edit the ZIP after calculating its hash.

## Later scripts

- Each ZIP must contain exactly one `script.json` and a matching `main.lua`. It may contain the script at the ZIP root or inside one containing folder.
- Supported file types: `.lua`, `.json`, `.md`, `.txt`. No symlinks or native binaries.
- ZIP and expanded contents: at most 1 MB; at most 40 archive entries. Main Lua: at most 64 KB. Manifest: 16 KB. Optional translation files: at most 32, each at most 32 KB.
- Catalogue: schema 1, at most 200 entries and 256 KB; unique script IDs. Supported games: Any, Aniimo, Loftia. API: 1.0. Permissions: ui, notifications, storage, session.
- Optional manifest display fields: description (500 chars), category (40), version (40).
- Source changes are a new reviewable version. Existing script folders are never silently overwritten by the current launcher; users stop/back up/remove the old folder before installing a replacement.
- Review pull requests manually. CI checks JSON/source structure and packaging rules, not semantics or malicious intent.

The tool emits a **one-entry proposal**, not the complete catalogue for every existing script. Merge later entries by ID; never replace a populated catalogue with a one-entry file accidentally.

## Release labels versus catalogue data

The launcher's Stable/Beta game-package update channel follows GitHub Latest/pre-release labels. This **script catalogue** is a separate curated list fetched from the default branch. The current catalogue schema does not filter scripts by release label. Add only the exact versions you want library users to see.

## Launcher connection

Place `ScriptLibrarySource.json` beside the Official launcher, with `{"repository":"Slyrith/Yuri-Lua"}`. No token is needed for the public catalogue. If you rename or transfer the repository, update this value too. A local `ScriptCatalogue.json` overrides the online catalogue.
