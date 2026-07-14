---
name: root-cause-alert
description: Root-cause a specific incident/alert in a Sauble-curated environment (device/site/client symptoms). Sauble-curated environments only — for playground / bring-your-own-source environments where you connected your own MCP sources, use the correlate skill instead.
---

# Root-cause an alert in a Sauble-curated environment

## When to use
A specific incident or alert in a **Sauble-curated** environment — a device, site, or client symptom to
diagnose. For open-ended "how healthy is my network?" questions in such an environment, use investigate
instead.

**Not for playground / bring-your-own-source environments.** If you connected your own MCP data sources,
`run_rca` returns no data — use the **correlate** skill instead. Run connect-and-verify if you're unsure
which kind of environment you have.

## How to run
Call `run_rca`. Compose the arguments from what the user gives you:
- `incident_summary` (required) — a specific, concrete symptom, not a vague phrase.
- Optional: `severity` (Critical/Major/Minor), `serial` (device/AP), `site_id` (venue/site),
  `client` (MAC), `start_time`/`end_time` (ISO; defaults to the last 15 minutes).
- Leave `transformer_type` = `KIC` and `environment_id` defaulted unless the user specifies otherwise.
- `wait` defaults to `true` (blocks and returns the analysis). **Tell the user it runs ~2–3 min.**

The returned `session_id` can be re-fetched later with `get_rca_session`.

*If a tool name or argument here differs from the server's live tool list, trust the live
definitions (you can see them) and run `/plugin marketplace update` to refresh this pack.*

## How to present results
Use a clean structure — **Root cause** → **Key findings** → **Recommended actions** → session id.
Do not dump raw JSON. On error, surface it plainly:
- 402 → out of Sauble credits.
- 403 → the token lacks `analysis:create` (run connect-and-verify to confirm).

## Example prompts
- "Root-cause: AP 903cb32d33f0 has DNS resolution failures, severity major."
- "Why is site X dropping clients? Diagnose it."
