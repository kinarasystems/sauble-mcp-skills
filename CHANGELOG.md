# Changelog

All notable changes to the `sauble` skills pack. The pack follows [Semantic Versioning](https://semver.org);
the `version` field in `plugin.json` is the source of truth.

## [0.1.0-beta.4] — 2026-07-14
### Fixed
- **`connect-and-verify` lane routing.** It now picks the analysis lane from the `playground` field
  the server returns, instead of inferring it from a controller type. Bring-your-own-source
  environments that carry a default controller type were being misrouted to the curated skills (and
  told correlation was "not the tool") — they now correctly route to **correlate**. Falls back to
  `probe_data_sources` when an older server doesn't return the `playground` field.

## [0.1.0-beta.3] — 2026-07-14
### Added
- **`correlate` skill** → `run_correlation`. Answers a question across all your connected MCP data
  sources and correlates them (root-cause / health / triage). This is the skill for
  **playground / bring-your-own-source** environments where you connected your own sources.

### Changed
- **Environment-aware routing.** `connect-and-verify` now identifies which analysis lane the environment
  is in (playground / bring-your-own-source → `correlate`; Sauble-curated → `run_analyze`/`run_rca`)
  and names the skill to use next.
- **Rescoped `investigate` / `root-cause-alert` / `triage-alerts`** to **Sauble-curated environments
  only** — their `run_analyze` / `run_rca` tools return no data against your own connectors, so they no
  longer auto-select there; the correlate skill owns that case.
- README reframed around the two analysis lanes.

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
