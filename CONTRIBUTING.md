# Contributing scripts

1. Use the current documented API. Do not depend on planned gameplay modules as though they already exist.
2. Provide source: `script.json`, `main.lua`, optional `Locales/*.json`, README and your license/permission notice. No native executables, DLLs, bytecode, obfuscated loaders, arbitrary network calls or credential collection.
3. Use a unique lowercase ID such as `creator.script-name`; choose Any, Aniimo or Loftia. List only the supported permissions you actually use.
4. Describe the supported launcher/API version, behavior, limitations and how you tested it. Creator names are self-declared, not verified identities.
5. Run `python tools/catalogue_tool.py validate`. For a proposed script outside examples, package it with the documented package command, which validates its source too.
6. Open a pull request using the template. Maintainers review source before publishing a release ZIP and catalogue entry. Passing CI is format validation, not approval or a security audit.

Do not commit logs, account identifiers, credentials, `.env` files, game files or compiled third-party binaries. Include permission to redistribute your submission. Public visibility by itself does not grant a license.

Do not upload scripts with misleading author names, fake download counts, unsupported promises or claims of safety/detection immunity. Report problems using the issue templates.
