# Sauble MCP Skills

Skills to drive Sauble RCA and network analysis from your coding agent — **Claude Code, Codex,
Cursor, and Windsurf**. The skills are one portable [Agent Skills](https://code.claude.com/docs/skills)
format; only the way you register the MCP server and drop in the skills differs per tool.

## Prerequisites

Mint a Personal Access Token (PAT) in the Sauble UI:

1. Log into the Sauble UI
2. Navigate to **Agent Access Tokens**
3. Create a new PAT (looks like `sk_user_…`)

Then make these three values available to your agent. **They are read when the agent launches, not at
runtime** — set them before you start the agent.

| OS | Set an environment variable |
|---|---|
| **macOS / Linux** (bash/zsh) | `export SAUBLE_MCP_URL=…` |
| **Windows** (PowerShell) | `$env:SAUBLE_MCP_URL = "…"` |

The three variables are `SAUBLE_MCP_URL` (must include the `/mcp` path), `SAUBLE_TOKEN` (your PAT), and
`SAUBLE_ENVIRONMENT_ID`.

## Install

Pick your agent. macOS and Linux are identical; Windows differences are noted.

### Claude Code

The pack ships as a plugin that bundles the skills **and** the MCP server:

```
/plugin marketplace add kinarasystems/sauble-mcp-skills
/plugin install sauble-mcp@sauble-mcp-skills
```

Enable the plugin and reload. Export the three variables in your shell first.

### Codex, Cursor, Windsurf

These read the same skills from the open Agent Skills standard; the installer drops the skills into the
right directory and adds the `sauble` MCP server **without touching your other servers** (it backs up
the config first and only adds/updates the `sauble` entry).

```bash
# macOS / Linux — from a checkout of this repo
./dist/install/install.sh codex      # or: cursor | windsurf | windsurf-jetbrains
```
```powershell
# Windows (PowerShell)
./dist/install/install.ps1 codex     # or: cursor | windsurf | windsurf-jetbrains
```

Pick `windsurf` for the **standalone Windsurf editor** and `windsurf-jetbrains` for the **Windsurf
plugin running inside a JetBrains IDE** (IntelliJ/PyCharm/etc.) — they use different config and skills
paths, so the target matters.

Options: `--global` (user-wide, the default for Codex/Windsurf) · `--project DIR` (repo-local skills) ·
`--skills-only` / `--mcp-only`. Uninstall with `./dist/install/uninstall.sh <agent>`.

Prefer to wire it up by hand? The exact per-tool config lives in [`dist/mcp/`](dist/mcp):

- **Codex** — add the block in [`dist/mcp/codex.toml`](dist/mcp/codex.toml) to `~/.codex/config.toml`
  (`%USERPROFILE%\.codex\config.toml` on Windows). `codex mcp add` can't set the custom headers, so use
  the block. Copy the skills into `~/.codex/skills/`.
- **Cursor** — click the one-click link in [`dist/mcp/cursor-deeplink.txt`](dist/mcp/cursor-deeplink.txt)
  (Cursor merges it for you), or add [`dist/mcp/cursor.json`](dist/mcp/cursor.json) to `.cursor/mcp.json`.
  Skills live in `.agents/skills/`.
- **Windsurf** (standalone editor) — add [`dist/mcp/windsurf.json`](dist/mcp/windsurf.json) via the
  Plugins UI or `~/.codeium/windsurf/mcp_config.json`. Skills live in `.windsurf/skills/`.
- **Windsurf plugin (JetBrains)** — the plugin inside IntelliJ/PyCharm reads MCP config from
  `~/.codeium/mcp_config.json` (top level, **not** `~/.codeium/windsurf/`) and skills from
  `~/.codeium/skills/`. Add/refresh the `sauble` server under **Settings → Tools → Windsurf Settings**
  and enable the Cascade tool window.

## Updating

The pack version is in [`dist/VERSION`](dist/VERSION); see [CHANGELOG.md](CHANGELOG.md) for what changed.
The server's **tool surface is discovered live** on every connect, so new server capabilities work
immediately — updating the pack refreshes the *guidance* and adds any new skills.

- **Claude Code** — `/plugin marketplace update sauble-mcp-skills`, then reinstall (or enable
  auto-update in the `/plugin` → **Marketplaces** tab), then `/reload-plugins`.
- **Codex / Cursor / Windsurf** — `git pull` and re-run `install.sh` / `install.ps1`. The re-run
  overwrites only the `sauble-mcp-*` skills and re-adds the server if your URL changed; other servers and
  skills are left alone. Restart the agent to pick up new skills.

## The Skills

Sauble has **two analysis lanes** — pick by the kind of environment you connected. Run
**connect-and-verify** first; it tells you which lane you're in and which skill to use.

### connect-and-verify (run first)

Verify the Sauble connection—confirm that your token, tenant, environment, and permissions are valid, and identify which analysis lane your environment is in. Use this first, or whenever Sauble calls fail with an auth error.

**Example:** "Check my Sauble connection."

### correlate — for your own connected sources (playground / bring-your-own-source)

If you connected **your own** MCP data sources, this is your skill. It answers a question across **all** your sources and correlates them — root-cause, health check, or separating a real outage from alert noise. Works with your own connectors.

**Example:** "Several access switches at my Miami hub just dropped — correlate across my sources and find the root cause."

---

The next three are for **Sauble-curated environments only**. They use curated-environment analysis and return no data against your own connectors — use **correlate** there instead.

### root-cause-alert (Sauble-curated)

Root-cause a specific incident or alert in a Sauble-curated environment. Give a symptom (device, site, severity) and the skill diagnoses it.

**Example:** "Root-cause: AP 903cb32d33f0 has DNS resolution failures, severity major."

### investigate (Sauble-curated)

Open-ended questions about a Sauble-curated environment's current health.

**Example:** "Any unhealthy access points right now?"

### triage-alerts (Sauble-curated)

Browse recent RCA/alert sessions in a Sauble-curated environment and drill into the most important one.

**Example:** "Show me recent alerts."

## Notes

- The `root-cause-alert` and `investigate` skills can take 2–3 minutes to complete; plan accordingly.
- If Sauble calls fail with an authentication error, run the `connect-and-verify` skill first to check your connection.
- Each skill has optional parameters (device serial, site ID, time range, severity) for more targeted analysis.

## How this pack is built

`plugins/sauble/` is the source of truth (the Claude plugin + skills + `.mcp.json`). The non-Claude
distributions under [`dist/`](dist) are generated from it by [`packaging/build.py`](packaging/build.py)
and kept in sync by CI — never hand-edit `dist/`. Run `python3 packaging/build.py` after changing a
skill. The per-agent × per-OS instruction matrix that the installers and the web UI both read is
[`dist/instructions.json`](dist/instructions.json).

## License

Apache-2.0 (see [LICENSE](LICENSE)).
