---
name: investigate
description: Open-ended health questions about a Sauble-curated environment (e.g. "any unhealthy access points?"). Sauble-curated environments only — for playground / bring-your-own-source environments where you connected your own MCP sources, use the correlate skill instead.
---

# Investigate a Sauble-curated environment's health

## When to use
Open-ended questions about the current state of a **Sauble-curated** environment ("any unhealthy APs?",
"summarize this site's health"). For a specific incident/alert in such an environment, use
root-cause-alert instead.

**Not for playground / bring-your-own-source environments.** If you connected your own MCP data sources,
`run_analyze` returns no data — use the **correlate** skill instead. Run connect-and-verify if you're
unsure which kind of environment you have.

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
