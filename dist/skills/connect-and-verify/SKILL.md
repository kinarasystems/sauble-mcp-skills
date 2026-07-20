---
name: connect-and-verify
description: Verify the Sauble connection — confirm the token, tenant, environment, and whether you can run analyses. Use first, or whenever Sauble calls fail with an auth error.
---

# Connect and verify Sauble

## When to use
Run this first in any Sauble session, or whenever another Sauble tool fails with an
authentication or permission error.

## How to run
Call `validate_connection` — it needs no required arguments (optional `environment_id`, otherwise
defaulted from the `X-Environment-ID` header). One call is enough.

*If a tool name or argument here differs from the server's live tool list, trust the live
definitions and run `/plugin marketplace update` to refresh this pack.*

## How to present results
Report: valid? + tenant name + environment + the key permissions. Explicitly state whether
`analysis:create` is present (→ the user can run RCA/analysis) or the token is read-only.

### Then route to the right analysis skill (important)
Sauble has two analysis lanes. Pick the lane from the **`playground`** field in the
`validate_connection` result so you don't call a tool that returns no data:
- **`playground: true`** — a bring-your-own-source environment: you connected your own MCP data
  sources. → Use the **correlate** skill (`run_correlation`). The investigate / root-cause-alert /
  triage-alerts skills return no data here.
- **`playground: false`** — a Sauble-curated environment. → Use **investigate** (open-ended health),
  **root-cause-alert** (a specific alert), or **triage-alerts** (recent sessions). Correlation is not
  the tool there.

If the result has no `playground` field (older Sauble server), fall back to the sources: run
**probe_data_sources** — if it lists data sources you connected yourself, treat it as a
bring-your-own-source environment and use **correlate**; otherwise use the curated skills.

State which lane the environment is in and name the skill the user should use next.

Distinguish the two failure modes — they need different fixes:
- **Unauthorized** (no/invalid token; the shim or core rejects the key): tell the user to mint a
  fresh PAT in the Sauble UI → Agent Access Tokens and set `SAUBLE_TOKEN` (and the other env vars).
- **Valid token but lacks permission** (e.g. 403 / no `analysis:create`): tell the user to ask an
  admin to grant the role — minting a new token will not help.

## Example prompts
- "Check my Sauble connection."
- "What tenant and permissions does my Sauble token have?"
