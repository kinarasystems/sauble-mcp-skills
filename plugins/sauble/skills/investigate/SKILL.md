---
name: investigate
description: Investigate your network's current health with Sauble — ask open-ended questions about an environment (not a specific alert).
---

# Investigate network health with Sauble

## When to use
Open-ended questions about an environment's current state ("any unhealthy APs?", "summarize
this site's health"). For a specific incident/alert, use the root-cause-alert skill instead.

## How to run
Reach for the conversational-analysis tool — `run_analyze` in the current surface. Give it your
`query`; it returns the analysis synchronously (there's no separate wait step), so tell the user
it may take a couple of minutes. Continue a thread by passing the returned `session_id` back on a
follow-up query, and re-fetch a prior result with `get_analysis_session`. (Conversational sessions
use `get_analysis_session`; alert/RCA sessions are re-fetched with a different tool.)

*If a tool name or argument here differs from the server's live tool list, trust the live
definitions and run `/plugin marketplace update` to refresh this pack.*

## How to present results
Present the message + findings + recommendations readably (not raw JSON). Offer concrete
follow-up questions the user can ask in the same session.

## Example prompts
- "Any unhealthy access points right now?"
- "Summarize the health of this environment."
