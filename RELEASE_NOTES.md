# v0.1.0

Initial public release of Codex Computer Use Doctor for Windows.

## Highlights

- Diagnose Windows Codex Desktop Computer Use, Chrome, and Browser plugin failures.
- Detect common local state problems in `.codex`, bundled plugin cache, Chrome native messaging, and Chrome extension installation.
- Generate text or JSON reports for GitHub issues, support threads, and community troubleshooting.
- Preview a repair plan with `-Repair`.
- Apply a conservative repair workflow with `-Repair -Apply`.

## Safety

The default mode is read-only. Repair mode backs up Codex config before changing plugin marketplace or plugin installation state. The tool does not read credentials, delete the whole `.codex` directory, or bypass workspace or product policy.
