# Security

This tool inspects local Codex and Chrome plugin state. Reports can contain local file paths and plugin configuration details.

Do not publish reports containing:

- API keys or tokens.
- OAuth callback secrets.
- Private repository names.
- Private browser screenshots.
- Organization-specific policy details.

The tool does not intentionally read credentials. If you find behavior that exposes sensitive data, please open a minimal issue without including the secret itself.
