# Contributing

Bug reports and diagnostic cases are useful for this project.

## Good Issue Reports

Include:

- Windows version.
- Codex Desktop version.
- Whether Computer Use appears in Codex settings.
- Whether `@computer` exposes a tool in a fresh thread.
- Whether Chrome and Browser are also unavailable.
- Output from `.\scripts\codex-computer-use-doctor.ps1`.

Do not include API keys, OAuth tokens, private repository names, sensitive browser screenshots, or private application windows.

## Pull Requests

Keep changes narrow and testable. Run:

```powershell
.\tests\smoke.ps1
```

Prefer read-only diagnostics before repair behavior. Repair actions should be conservative, explainable, and backed up.
