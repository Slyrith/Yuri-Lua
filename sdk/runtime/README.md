# Host-provided helper sources

These are the current helpers embedded by the private Yuri worker. They are
included for API review and host integration, not as standalone scripts.
`SdkHelpers.lua` wraps the narrow host-provided `yuri` functions;
`WorkflowHelpers.lua` and `TaskHelpers.lua` build on that API.

The worker loads them automatically before community scripts. Do not paste
them into each script, call `require` on these paths, or expect them to add
missing gameplay capabilities to an older launcher. They need the matching
restricted host and its permission checks. These files grant no raw OS,
native pointer or unrestricted game-memory access.
