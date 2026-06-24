# Changelog

All notable changes to the `sauble` skills pack. The pack follows [Semantic Versioning](https://semver.org);
the `version` field in `plugin.json` is the source of truth.

## [0.1.0-beta.2] — 2026-06-24
### Changed
- **Renamed the plugin `sauble` → `sauble-mcp`** to avoid a name collision with the internal `sauble`
  dev-skills plugin. Claude Code namespaces a plugin's skills and MCP server by plugin name, so two
  plugins named `sauble` collide. **Install is now `/plugin install sauble-mcp@sauble-mcp-skills`**
  (the marketplace name `sauble-mcp-skills` is unchanged). Skills now load under the `sauble-mcp:`
  namespace, and the MCP server as `plugin:sauble-mcp:sauble`.

## [0.1.0-beta.1] — 2026-06-24
Preview / beta release for internal testing — not yet advertised publicly. Functionally the planned
0.1.0; the `-beta` suffix will be dropped for the public GA once testing is complete.

### Added
- One `sauble` plugin bundling four skills — `connect-and-verify`, `root-cause-alert` (flagship),
  `investigate`, and `triage-alerts` — plus the bundled MCP server config (`.mcp.json`, env-var auth)
  and a stdlib manifest/skill validator (`scripts/validate.py`).
- Skills are written intent-first and defer to the server's live tool list, so additive server
  changes need no pack update.
- "Updating" guidance in the README (`/plugin marketplace update` then `/reload-plugins`).
