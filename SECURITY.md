# Script platform boundaries

The implemented SDK is API 1.0 foundation, not the finished gameplay SDK. The launcher uses restricted, separate Lua workers, explicit permissions, exact-version review and bounded resources. Source changes require another review; downloaded scripts remain OFF. The platform has not had an independent security audit.

The catalogue is data, not executable Lua. Entries need a supported GitHub release ZIP URL and the ZIP's SHA-256. The launcher checks archive paths, source-only file types, limits, manifest identity and supported capabilities before installing. Hashes verify consistency; they do not establish trust in a creator.

Maintainers must review source and grants of redistribution before publication. Keep catalogue changes behind normal pull-request review. The provided validation workflow has read-only repository permissions and receives no project secrets; it never executes submitted Lua.

For a suspected sandbox escape, credential exposure or other sensitive issue, contact Slyrith privately through the existing Yuri community rather than posting exploit details in a public issue. Do not include tokens or private account data in public reports. No automated log submission is provided here.
