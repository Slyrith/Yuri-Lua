# Script platform boundaries

The current SDK is a development API 1.2 / helpers 1.2.2 snapshot. Scripts run
in separate restricted workers with explicit permissions, exact-version review
and bounded resources. Changed source needs review again. Downloaded scripts
start OFF. The sandbox has not had an independent security audit.

Gameplay APIs expose bounded copied state and typed requests through a matching
game adapter. Handles are opaque, grants are checked, requests expire, and
features/labels have script ownership. Scripts do not receive raw pointers,
native invocation, arbitrary process memory, shell execution, unrestricted file
or network access, or the game's native Lua environment. These restrictions are
risk reduction, not a guarantee against every hostile script or dependency.

Maintainers must review source, permission scope and redistribution rights.
Catalogue hashes check consistency, not creator trust or malware safety. Local
validation checks structure and packaging without executing submitted Lua; it
cannot prove that script logic is safe. Do not automatically approve a source
revision because a previous version was approved.

The validation workflow has read-only repository permissions and does not need
project secrets. Report suspected sandbox escapes, credential exposure or other
sensitive findings privately to Slyrith through the existing Yuri community.
Do not put tokens or personal logs in public issues.
