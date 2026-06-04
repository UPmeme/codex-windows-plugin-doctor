# Codex Windows Plugin Doctor

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE)
![Platform](https://img.shields.io/badge/platform-Windows-0078D4)
![License](https://img.shields.io/badge/license-MIT-green)

Diagnose Codex Desktop Browser, Chrome, and Computer Use plugin availability
problems on Windows.

Codex Desktop can use plugins to inspect browsers, control Chrome, and operate
desktop apps. On Windows, users can run into states where a plugin appears
installed or connected but the corresponding tool is not available in a Codex
thread.

`codex-windows-plugin-doctor` is a small read-only PowerShell diagnostic tool
that checks common local signals and prints a report you can paste into a bug
report or support thread.

## What It Checks

- Codex home directory and `config.toml`.
- Bundled plugin config entries for Browser, Chrome, and Computer Use.
- OpenAI bundled plugin marketplace config.
- Cached plugin directories.
- Chrome native messaging host registry entries.
- Codex Chrome extension installation in common Chrome profiles.

## Install

Clone the repository:

```powershell
git clone https://github.com/UPmeme/codex-windows-plugin-doctor.git
cd codex-windows-plugin-doctor
```

No dependencies are required beyond Windows PowerShell.

## Quick Start

Run:

```powershell
.\scripts\codex-windows-plugin-doctor.ps1
```

Generate JSON:

```powershell
.\scripts\codex-windows-plugin-doctor.ps1 -Json
```

Save a report:

```powershell
.\scripts\codex-windows-plugin-doctor.ps1 -OutFile .\reports\codex-plugin-report.txt
```

## Scope

This tool is read-only by default. It does not modify Codex configuration, clear
caches, install extensions, edit registry keys, read credentials, or bypass
workspace policy.

It is not affiliated with OpenAI. It is a community diagnostic helper for users
who need a structured local report.

## Troubleshooting

See [Windows plugin troubleshooting](docs/windows-plugin-troubleshooting.md).

## Test

```powershell
.\tests\smoke.ps1
```

## License

MIT
