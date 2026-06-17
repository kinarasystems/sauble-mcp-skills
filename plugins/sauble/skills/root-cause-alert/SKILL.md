---
name: root-cause-alert
description: Root-cause a specific network incident or alert with Sauble — give a symptom (device/site/severity) and get findings plus recommended fixes.
---

# Root-cause an alert with Sauble

## When to use
The user has a specific incident or alert — a device, site, or symptom they want diagnosed.
For open-ended "how healthy is my network?" questions, use the investigate skill instead.

## How to run
Call `run_rca`. Compose the arguments from what the user gives you:
- `incident_summary` (required) — a specific, concrete symptom, not a vague phrase.
- Optional: `severity` (Critical/Major/Minor), `serial` (device/AP), `site_id` (venue/site),
  `client` (MAC), `start_time`/`end_time` (ISO; defaults to the last 15 minutes).
- Leave `transformer_type` = `KIC` and `environment_id` defaulted unless the user specifies otherwise.
- `wait` defaults to `true` (blocks and returns the analysis). **Tell the user it runs ~2–3 min.**

The returned `session_id` can be re-fetched later with `get_rca_session`.

## How to present results
Use a clean structure — **Root cause** → **Key findings** → **Recommended actions** → session id.
Do not dump raw JSON. On error, surface it plainly:
- 402 → out of Sauble credits.
- 403 → the token lacks `analysis:create` (run connect-and-verify to confirm).

## Example prompts
- "Root-cause: AP 903cb32d33f0 has DNS resolution failures, severity major."
- "Why is site X dropping clients? Diagnose it."
