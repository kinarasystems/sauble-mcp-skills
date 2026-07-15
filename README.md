# Sauble MCP Skills

Skills to drive Sauble RCA and network analysis from your Claude Code agent.

## Prerequisites

Before using these skills, mint a Personal Access Token (PAT) in the Sauble UI:

1. Log into the Sauble UI
2. Navigate to **Agent Access Tokens**
3. Create a new PAT (looks like `sk_user_…`)

Then export these three environment variables **before launching your agent**. These are interpolated at agent startup, not at runtime—if they are not set before launch, the MCP server will fail to initialize:

```bash
export SAUBLE_MCP_URL=https://your-sauble-instance.com/mcp
export SAUBLE_TOKEN=sk_user_...
export SAUBLE_ENVIRONMENT_ID=your-environment-id
```

**Critical:** The `SAUBLE_MCP_URL` must include the `/mcp` path—a common mistake is omitting it.

## Install

Add and enable the plugin in your Claude Code agent:

```
/plugin marketplace add kinarasystems/sauble-mcp-skills
/plugin install sauble-mcp@sauble-mcp-skills
```

After installation, **enable** the plugin and **restart/reload** your agent. The bundled MCP server starts only once the plugin is enabled, and the skills load after a reload.

## Updating

Updates are **manual** for third-party marketplaces (auto-update is off by default). To get the latest pack:

```
/plugin marketplace update sauble-mcp-skills   # refresh the cached catalog from the repo
```

Then apply the new version one of two ways:

- **Turn on auto-update** — `/plugin` → **Marketplaces** tab → select `sauble-mcp-skills` → enable auto-update. Claude Code updates in the background and prompts you to run `/reload-plugins`.
- **Or by hand** — uninstall then reinstall the plugin, then `/reload-plugins` to load the new skills + MCP config (no full restart needed).

The server's **tool surface is discovered live** on every connect, so new server capabilities are usable immediately — updating the pack refreshes the *guidance* (and adds any new skills). See [CHANGELOG.md](CHANGELOG.md) for what changed in each release.

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

## License

Apache-2.0 (see [LICENSE](LICENSE)).
