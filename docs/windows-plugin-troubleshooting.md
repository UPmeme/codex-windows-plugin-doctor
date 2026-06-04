# Windows Plugin Troubleshooting

This page summarizes common failure modes for Codex Desktop Browser, Chrome, and
Computer Use plugins on Windows.

## Common Symptoms

- The Chrome extension says `Connected`, but Codex cannot control Chrome.
- `@chrome` or `@computer` does not expose the expected tools.
- Browser, Chrome, or Computer Use plugins disappear after restart.
- Codex shows a plugin as installed, but tool discovery returns unrelated tools.
- Computer Use appears in settings but is unavailable in a thread.

## Diagnostic Flow

Run:

```powershell
.\scripts\codex-windows-plugin-doctor.ps1
```

Then check the report in this order:

1. `Codex config.toml`
2. `Configured bundled plugin`
3. `OpenAI bundled marketplace`
4. `Cached plugin files`
5. `Chrome native messaging host registry entries`
6. `Codex Chrome extension`

The goal is to separate three different states:

- The plugin is not configured.
- The plugin is configured but local cached files are missing.
- The browser extension is installed, but the native messaging bridge is missing.

## What This Tool Does Not Do

It does not repair configuration automatically. That is intentional for the
first version because Codex plugin state can include user-specific settings,
workspace policy, and bundled marketplace cache state.

Prefer collecting a report before changing files.

## Useful Bug Report Data

When reporting a Windows Codex plugin issue, include:

- Windows version.
- Codex Desktop version.
- Whether Browser, Chrome, and Computer Use appear in Codex settings.
- Whether the Chrome extension shows `Connected`.
- The diagnostic report from this tool.
- A short reproduction step, such as `@chrome` returning no Chrome control tool.

Do not include API keys, OAuth tokens, private repository names, or screenshots
with sensitive browser content.
