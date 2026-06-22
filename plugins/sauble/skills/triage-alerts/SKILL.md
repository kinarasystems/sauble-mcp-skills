---
name: triage-alerts
description: Triage recent Sauble alerts — browse recent RCA/alert sessions and dig into the most important one.
---

# Triage recent Sauble alerts

## When to use
The user wants to see what's been happening — browse recent alerts/RCA sessions and drill into
the most important one.

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
