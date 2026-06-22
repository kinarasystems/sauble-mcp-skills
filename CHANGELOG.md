# Changelog

All notable changes to the `sauble` skills pack. The pack follows [Semantic Versioning](https://semver.org);
the `version` field in `plugin.json` / `marketplace.json` is the source of truth.

## [0.1.0] — 2026-06-17
### Added
- Initial release: one `sauble` plugin bundling four skills — `connect-and-verify`,
  `root-cause-alert` (flagship), `investigate`, and `triage-alerts` — plus the bundled MCP server
  config (`.mcp.json`, env-var auth) and a stdlib manifest/skill validator (`scripts/validate.py`).
- Skills are written intent-first and defer to the server's live tool list, so additive server
  changes need no pack update.
