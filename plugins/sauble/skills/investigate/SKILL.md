---
name: investigate
description: Investigate your network's current health with Sauble — ask open-ended questions about an environment (not a specific alert).
---

# Investigate network health with Sauble

## When to use
Open-ended questions about an environment's current state ("any unhealthy APs?", "summarize
this site's health"). For a specific incident/alert, use the root-cause-alert skill instead.

## How to run
Call `run_analyze(query, ...)`. The signature is `(query, session_id, context, environment_id)` —
there is **no `wait` parameter**; it returns the analysis synchronously. It can take a couple of
minutes, so tell the user it's running. Pass the returned `session_id` back on a follow-up `query`
to continue the same investigation, and use `get_analysis_session` to re-fetch a prior result.

Note: conversational analysis sessions use `get_analysis_session` — not `get_rca_session`,
which is for alert/RCA sessions.

## How to present results
Present the message + findings + recommendations readably (not raw JSON). Offer concrete
follow-up questions the user can ask in the same session.

## Example prompts
- "Any unhealthy access points right now?"
- "Summarize the health of this environment."
