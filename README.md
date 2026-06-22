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
/plugin install sauble@sauble-mcp-skills
```

After installation, **enable** the plugin and **restart/reload** your agent. The bundled MCP server starts only once the plugin is enabled, and the skills load after a reload.

## Updating

Updates are **manual** for third-party marketplaces (auto-update is off by default). To get the latest pack:

```
/plugin marketplace update sauble-mcp-skills   # refresh the catalog
/reload-plugins                                # apply: load updated skills + MCP config
```

(`/plugin` → **Installed** tab shows what's available, and lets you enable auto-update if you'd rather not do it by hand.) The server's **tool surface is discovered live** on every connect, so new server capabilities are usable immediately — updating the pack refreshes the *guidance* (and adds any new skills). See [CHANGELOG.md](CHANGELOG.md) for what changed in each release.

## The Four Skills

### connect-and-verify

Verify the Sauble connection—confirm that your token, tenant, environment, and permissions are valid. Use this first, or whenever Sauble calls fail with an auth error.

**Example:** "Check my Sauble connection."

### root-cause-alert

Root-cause a specific network incident or alert and get findings plus recommended fixes. Give a symptom (device, site, severity) and the skill will diagnose it.

**Example:** "Root-cause: AP 903cb32d33f0 has DNS resolution failures, severity major."

### investigate

Open-ended questions about an environment's current health. Use this for questions like "Are there unhealthy access points?" or "What's the health status of this site?"

**Example:** "Any unhealthy access points right now?"

### triage-alerts

Browse recent RCA and alert sessions and drill into the most important one. Quickly see what alerts have been triggered and explore their details.

**Example:** "Show me recent alerts."

## Notes

- The `root-cause-alert` and `investigate` skills can take 2–3 minutes to complete; plan accordingly.
- If Sauble calls fail with an authentication error, run the `connect-and-verify` skill first to check your connection.
- Each skill has optional parameters (device serial, site ID, time range, severity) for more targeted analysis.

## License

Apache-2.0 (see [LICENSE](LICENSE)).
