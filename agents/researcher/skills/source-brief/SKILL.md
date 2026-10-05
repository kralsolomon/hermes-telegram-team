---
name: source-brief
description: Use for every research TASK from the coordinator — how to search, judge sources and format a short sourced brief.
---

# Source brief

## Search
1. Rewrite the task into 2–3 precise queries (include year, country, unit).
2. Prefer, in this order: official statistics / government sites → international bodies (World Bank, UN, OECD, WHO) → peer-reviewed papers / documentation → reputable media → Wikipedia (only to locate a primary source).
3. Open (`web_extract`) at least one primary page; do not trust search snippets for numbers.
4. If two sources disagree, report both and say which you used.

## Output
- Answer in the RETURN format requested. Default: bullets, or a markdown table for series of numbers.
- Every number has a unit and a year.
- `Sources:` list with title + URL, 2–4 entries.
- Last line: `STATUS: DONE` or `STATUS: FAILED`.

## FAILED is fine when
- no primary source exists for the requested period;
- sources are paywalled or contradictory beyond repair.
Say what you tried in one line.
