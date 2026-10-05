---
name: team-handoff
description: Use whenever a human gives the coordinator a request that needs research and/or computation — how to split it, delegate via @mentions with task ids, and decide when the work is finished.
---

# Team handoff protocol

## 1. Decide: delegate or answer?

| Request looks like | Do |
|---|---|
| greeting, question about the team, one fact you are certain of | answer yourself, no delegation |
| needs current facts / numbers / sources | T → researcher |
| needs calculation, table, chart, code check | T → coder (data must be in the task) |
| needs data **and** analysis | T1 → researcher, then T2 → coder with T1's data pasted in |

## 2. Message templates

Plan (to the human):
```
Plan: T1 → researcher: <goal>. T2 → coder: <goal>. I'll post the final answer when both are done.
```

Delegation:
```
@<specialist> [T1] TASK: <self-contained instruction + any data>
RETURN: <exact format>
```

## 3. State machine per request

```
PLANNED → WAITING(T1..Tn) → (all DONE) → FINAL
                     ↘ FAILED → retry once → still FAILED → FINAL (partial, explain)
```

Limits: max 6 delegation messages per request; max 1 retry per task id.

## 4. Final answer

- First line `✅ FINAL ANSWER`
- 3–8 bullet points or a short table, then `Sources:` (from researcher) and any `MEDIA:` file from coder
- **No @mentions of bots.** This closes the loop.

## Worked example

Human: "Compare the population of Kazakhstan and Uzbekistan over the last 10 years and plot it."

1. `Plan: T1 → researcher: yearly population 2015–2024 for both. T2 → coder: growth % and line chart.`
2. `@researcher [T1] TASK: Find yearly population of Kazakhstan and Uzbekistan for 2015–2024 from official statistics or World Bank. RETURN: table year|KZ|UZ in millions + sources.`
3. researcher → `[T1] RESULT ... STATUS: DONE`
4. `@coder [T2] TASK: Using this table <pasted>, compute total and average annual growth % for each country and draw a line chart. RETURN: numbers + PNG.`
5. coder → `[T2] RESULT ... MEDIA:/.../population.png STATUS: DONE`
6. `✅ FINAL ANSWER ...` (no bot mentions)
