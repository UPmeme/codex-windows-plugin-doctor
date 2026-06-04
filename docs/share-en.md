# Codex Computer Use unavailable on Windows? A diagnostic and repair tool

Some Windows Codex Desktop users run into a confusing plugin state:

```text
Computer Use appears installed in settings,
but @computer does not expose a desktop-control tool in the thread.
```

A related Chrome symptom is:

```text
The Codex Chrome extension says Connected,
but Codex cannot control Chrome.
```

I built a small open-source diagnostic tool:

https://github.com/UPmeme/codex-windows-plugin-doctor

It checks local state before recommending repairs:

- Codex `config.toml`
- Browser / Chrome / Computer Use plugin config
- OpenAI bundled marketplace config
- plugin cache files
- plugin `SKILL.md` files
- Chrome native messaging host entries
- Codex Chrome extension installation

Run a read-only diagnostic:

```powershell
.\scripts\codex-computer-use-doctor.ps1
```

Preview a repair plan:

```powershell
.\scripts\codex-computer-use-doctor.ps1 -Repair
```

Apply the conservative repair workflow:

```powershell
.\scripts\codex-computer-use-doctor.ps1 -Repair -Apply
```

The default mode is read-only. It does not read credentials, delete `.codex`, or bypass policy.

If you have a reproducible Windows Computer Use / Chrome plugin failure, please share a sanitized diagnostic report here:

https://github.com/UPmeme/codex-windows-plugin-doctor/issues/1
