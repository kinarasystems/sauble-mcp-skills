---
name: correlate
description: Answer a question across ALL your connected data sources and correlate the results — root-cause, health, or triage for playground / bring-your-own-source environments where you connected your own MCP data sources. The default when you've connected your own sources.
---

# Correlate across your connected sources

## When to use
Any root-cause, health-check, or "which alert is the real one" question in an environment that has
**your own** connected MCP data sources. This is the common case for playground / bring-your-own-source
environments.

**Prefer this skill** over investigate / root-cause-alert / triage-alerts unless the environment is a
**Sauble-curated** environment. Those three use curated-environment analysis (`run_analyze` / `run_rca`)
that returns **no data** against your own connectors — correlation is what works here. (Not sure which
kind of environment you have? Run the connect-and-verify skill first; it tells you.)

## How to run
1. *(optional)* Call `probe_data_sources` to list which of your sources are connected and reachable.
2. Call `run_correlation` with your `query` — describe the symptom/question in plain language, and when
   you know it, name the site/devices so it can scope. It queries every connected source, reconciles
   them, and returns a correlated answer synchronously (~1–2 min). Continue the thread by passing the
   returned `session_id` back on a follow-up.

*If a tool name or argument here differs from the server's live tool list, trust the live definitions and
run `/plugin marketplace update` to refresh this pack.*

## How to present results
Lead with the **root cause** — or plainly "healthy — no incident to act on" when that's the finding.
Then the cross-source evidence (what each source contributed and where they agree), the confidence, and
any gaps or contradictions (don't smooth those over). Never dump raw JSON. Offer a scoped follow-up the
user can ask in the same session.

## Example prompts
- "Several access switches at my Miami hub just dropped at once — correlate across my sources and find the root cause."
- "Is my Phoenix site healthy right now, or is there something I should act on?"
- "Alerts are firing across several of my sites — which is the real outage and which are just noise?"
