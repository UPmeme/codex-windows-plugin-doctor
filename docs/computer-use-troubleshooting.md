# Computer Use Troubleshooting on Windows

This document focuses on the most visible failure mode:

```text
Computer Use appears installed in Codex Desktop, but the current thread cannot
use a desktop-control tool.
```

## Why This Happens

There are several distinct layers:

- The plugin must be installed and enabled in Codex Desktop.
- The bundled plugin files must exist in the local Codex plugin cache.
- The plugin skill metadata must be discoverable.
- The active Codex thread must expose the corresponding MCP tools.
- Workspace policy and product rollout rules may still restrict availability.

A machine can pass the first three checks and still fail the fourth. That is why
the diagnostic separates local plugin state from active-thread tool exposure.

## First Diagnostic

Run:

```powershell
.\scripts\codex-windows-plugin-doctor.ps1
```

If Computer Use config, cache, and skill files are present but the active thread
still cannot use Computer Use, collect the report and try:

1. Restart Codex Desktop.
2. Create a fresh thread and mention `@computer` or `@Computer Use`.
3. Disable and re-enable the Computer Use plugin from Codex settings.
4. If Chrome also fails, reinstall the Chrome plugin and extension together.
5. Keep the diagnostic report before deleting caches or restoring backups.

## Do Not Start With Destructive Fixes

Avoid these as first steps:

- Deleting the whole `.codex` directory.
- Restoring an old `.codex` backup over the current one.
- Copying plugin cache folders from another machine.
- Running random repair scripts that rewrite `config.toml`.

Those actions can remove working connectors, saved plugin state, or local
automation configuration.

## Good Bug Report Shape

Include:

- Windows version.
- Codex Desktop version.
- Whether Computer Use appears in Codex settings.
- Whether `@computer` exposes a tool in a new thread.
- Whether Chrome and Browser tools are also missing.
- The full diagnostic report.

Do not include tokens, private repository names, private screenshots, or browser
content.
