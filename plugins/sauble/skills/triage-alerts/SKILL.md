---
name: triage-alerts
description: Triage recent Sauble alerts — browse recent RCA/alert sessions and dig into the most important one.
---

# Triage recent Sauble alerts

## When to use
The user wants to see what's been happening — browse recent alerts/RCA sessions and drill into
the most important one.

## How to run
1. Call `list_rca_sessions` (optional `severity`, `limit`, `offset`, `search` — use `search` to
   filter by serial/text, `offset` to page). Present a short ranked list: session_id, severity,
   serial, summary.
2. On the user's selection: call `get_rca_session(session_id)` to show the existing RCA, or
   `run_rca` to analyze a fresh incident if no session covers it.

## How to present results
Show a compact list first, then — once the user picks one — the chosen session's RCA in the
Root cause → Findings → Recommended actions structure.

## Example prompts
- "Show me recent alerts."
- "Triage the most severe recent alert."
