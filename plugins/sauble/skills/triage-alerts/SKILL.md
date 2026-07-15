---
name: triage-alerts
description: Browse recent RCA/alert sessions in a Sauble-curated environment and drill into the most important one. Sauble-curated environments only — for playground / bring-your-own-source environments where you connected your own MCP sources, use the correlate skill instead.
---

# Triage recent alerts in a Sauble-curated environment

## When to use
The user wants to see what's been happening in a **Sauble-curated** environment — browse recent RCA/alert
sessions and drill into the most important one.

**Not for playground / bring-your-own-source environments.** The RCA-session store is empty for
environments where you connected your own MCP data sources — to find and separate the real problem from
alert noise there, use the **correlate** skill instead. Run connect-and-verify if you're unsure which
kind of environment you have.

## How to run
1. List recent sessions with `list_rca_sessions` (optional filters: `severity`, `limit`, `offset`,
   `search` to filter by serial/text or page). Present a short ranked list: session_id, severity,
   serial, summary.
2. On the user's selection: re-fetch the chosen session with `get_rca_session`, or run a fresh
   analysis with `run_rca` if no session covers it.

*If a tool name or argument here differs from the server's live tool list, trust the live
definitions and run `/plugin marketplace update` to refresh this pack.*

## How to present results
Show a compact list first, then — once the user picks one — the chosen session's RCA in the
Root cause → Findings → Recommended actions structure.

## Example prompts
- "Show me recent alerts."
- "Triage the most severe recent alert."
