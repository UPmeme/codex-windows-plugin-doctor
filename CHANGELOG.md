# Changelog

## 0.1.0

- Added Windows diagnostics for Codex Computer Use, Chrome, and Browser plugins.
- Added checks for Codex config, bundled marketplace, plugin cache, plugin skill files, Chrome native messaging host entries, and Codex Chrome extension installation.
- Added `-Repair` dry-run mode with a conservative repair plan.
- Added `-Repair -Apply` mode that backs up Codex state, mirrors the bundled plugin source, registers a repaired marketplace source, and reinstalls Browser, Chrome, and Computer Use.
- Added English and Chinese README files.
- Added GitHub Actions smoke test coverage.
