# Updating Slyrith/Yuri-Lua

1. Extract the update ZIP. Its files are already laid out at repository root.
2. Merge its contents into your existing Yuri-Lua checkout, or upload the
   extracted files into the GitHub repository root. Do not upload only the ZIP
   as a source file, and do not nest everything under a new wrapper folder.
3. Review and commit the changes. This updates documentation, examples,
   declarations, helper sources and validation tools; it does not create a release.
4. Keep the existing root `catalogue.json`. It is deliberately absent from
   this update so no published entries or download hashes are replaced.
5. Run `python tools/catalogue_tool.py validate` and
   `python -m unittest discover -s tools/tests` after merging.

No release ZIP assets or catalogue entries need to be published for this SDK
source update. When a script release is ready, follow PUBLISHING.md separately.
Do not add catalogue URLs before their actual release files exist.

Launcher localization work remains paused. Existing script-local translations
are preserved; this package does not publish a launcher translation template.
