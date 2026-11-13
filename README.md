<p align="center"><img src="assets/yuri.png" width="96" alt="Yuri"></p>
<h1 align="center">Yuri Lua</h1>
<p align="center">Community scripts, SDK documentation and examples for Yuri.</p>

## Get started

- **Players:** open **Script library** in Yuri Launcher v0.10.0 or later. Download a script, then use **Installed → Review & enable**. Downloads do not automatically run scripts.
- **Creators:** start with [Hello Yuri](examples/hello), read the [API reference](docs/API.md), and use [sdk/yuri.d.lua](sdk/yuri.d.lua) for editor autocomplete.
- **Contributors:** read [CONTRIBUTING.md](CONTRIBUTING.md). Submit scripts through pull requests; maintainers review catalogue entries before publication.
- **Maintainers:** use [PUBLISHING.md](docs/PUBLISHING.md) to publish ZIP assets and update the catalogue.

## What is available now?

API **1.0 foundation** supports script controls, notifications, private settings and launcher session/tick events. Scripts run in an isolated Lua interpreter; they do not get unrestricted access to Yuri, the OS or the game's Lua state.

Broader gameplay modules for player/entity data, supported actions, custom visuals and automation are planned. They are **not implemented by this SDK yet**. See the [platform roadmap](docs/ROADMAP.md).

| Location | Purpose |
| --- | --- |
| `catalogue.json` | Machine-readable list used by Yuri's shared library. |
| `examples/hello/` | Working starter script with its manifest and script-local translations. |
| `sdk/yuri.d.lua` | Lua editor type declarations. |
| `docs/` | API, publishing, architecture and review documentation. |
| `tools/catalogue_tool.py` | Validate data and package scripts without executing Lua. |
| `.github/` | Contribution templates and an automatic validation workflow. |

The catalogue starts empty. This is intentional: add an entry only after its release ZIP exists. The Hello Yuri example is already bundled with Yuri Launcher and also lives in this repository as source.

## Connect the launcher

Create `ScriptLibrarySource.json` beside `YuriLauncher.exe`:

```json
{"repository": "Slyrith/Yuri-Lua"}
```

In the Official edition, click **Script library → Refresh library**. Yuri reads `catalogue.json` from this repository's default branch. UC remains an offline/manual-download edition. A local `ScriptCatalogue.json`, if present beside the launcher, takes precedence over the online source.

## Validate and package

Python 3.10+ is required only for maintainers and contributors, not for players. No third-party Python packages are needed.

```text
python tools/catalogue_tool.py validate
python tools/catalogue_tool.py package --script examples/hello --repo Slyrith/Yuri-Lua --tag sdk-v1.0.0 --output dist
```

The package command produces a ZIP and a proposed `catalogue-entry.json`. It does **not** upload anything, edit the live catalogue or run Lua. Follow the publishing guide before adding that entry.

No database, web server, Discord login or launcher account is required. GitHub hosts the curated catalogue and release assets; its pull requests provide contribution review. This repository is not a discussion forum or an automatically executing script store.

## Review and safety

Creator names are self-declared. ZIP hashes detect mismatches, not malicious intent. Each exact installed version still needs permission review. Read [SECURITY.md](SECURITY.md) for the current boundaries and reporting process.

## Project links

- [Yuri Aniimo](https://github.com/Slyrith/Yuri-Aniimo)
- [Yuri Loftia](https://github.com/Slyrith/Yuri-Loftia)
- [Yuri community](https://discord.gg/DvP8UxQP3J)
- [Support the project](https://www.paypal.com/ncp/payment/ZFAGRQRSCT6SQ)

A repository-wide license has not been selected yet. Do not assume the project or third-party submissions use a particular open-source license. Contributors must state the rights they grant for their own scripts.
