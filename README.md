# Codex Computer Use Doctor for Windows

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE)
![Platform](https://img.shields.io/badge/platform-Windows-0078D4)
![License](https://img.shields.io/badge/license-MIT-green)

Diagnose Codex Desktop Computer Use, Chrome, and Browser plugin availability
problems on Windows.

Codex Desktop can use Computer Use to operate desktop apps, Chrome to work with
logged-in browser sessions, and Browser for in-app web testing. On Windows,
users can run into states where Computer Use or Chrome appears installed or
connected but the corresponding tool is not available in a Codex thread.

`codex-windows-plugin-doctor` is a small read-only PowerShell diagnostic tool
focused on the common Windows failure mode: Computer Use, Chrome, or Browser is
configured locally, but Codex cannot expose the expected `@computer`, `@chrome`,
or browser-control tools in the active session.

The report is designed to be pasted into a GitHub issue, Reddit post, support
thread, or Codex troubleshooting conversation.

## What It Checks

- Codex home directory and `config.toml`.
- Bundled plugin config entries for Browser, Chrome, and Computer Use.
- OpenAI bundled plugin marketplace config.
- Cached plugin directories.
- Plugin skill files for Computer Use, Chrome, and Browser.
- Chrome native messaging host registry entries.
- Codex Chrome extension installation in common Chrome profiles.
- A short next-step repair plan based on the missing signals.

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

## Common Computer Use Symptom

This project is especially aimed at this Windows symptom:

```text
Computer Use is installed in Codex settings, but @computer or @Computer Use
does not expose a desktop-control tool in the current thread.
```

The same diagnostic also covers related Chrome symptoms:

```text
The Codex Chrome extension says Connected, but Codex cannot control Chrome.
```

## Scope

This tool is read-only by default. It does not modify Codex configuration, clear
caches, install extensions, edit registry keys, read credentials, or bypass
workspace policy.

The first version intentionally reports what is missing before proposing a
manual fix. Automatic repair is risky because Codex plugin state can involve
config files, bundled marketplace cache, native messaging hosts, extension
state, and per-thread tool exposure.

It is not affiliated with OpenAI. It is a community diagnostic helper for users
who need a structured local report.

## Troubleshooting

See [Computer Use troubleshooting](docs/computer-use-troubleshooting.md) and
[Windows plugin troubleshooting](docs/windows-plugin-troubleshooting.md).

## Test

```powershell
.\tests\smoke.ps1
```

## License

MIT
