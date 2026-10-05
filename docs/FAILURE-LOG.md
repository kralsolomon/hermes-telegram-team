# Failure log

Record every request where the team misbehaved. For the defense, reproduce at least one live.

## Template

```
### F<n> — <short title>
Date:
Request (exact text):
What happened: (paste the relevant Telegram messages / gateway.log lines)
Root cause: prompt | config | model | Telegram setting | tool backend
Fix applied: (file + change)
Re-test result:
```

---

## Ready-to-reproduce scenarios

### F1 — Data that does not exist (shows the FAILED path)
**Request:** `@coordinator_bot Plot the hourly temperature in Astana for yesterday and compare it with the same hours 10 years ago.`
**Expected failure:** researcher cannot find hourly historical data from a citable source → `STATUS: FAILED` → coordinator retries once with a looser task (daily averages) → final answer is partial and says so.
**If instead** researcher invents numbers: root cause = model/prompt; fix = stronger "never invent numbers" rule in `source-brief`, or a stronger researcher model.

### F2 — Results landing in the wrong session (config bug we hit during setup)
**Symptom:** researcher posts `[T1] RESULT`, coordinator does nothing.
**Root cause:** Hermes keys group sessions per sender by default, so the bot's message went into a separate coordinator session that had no plan in it.
**Fix:** `group_sessions_per_user: false` in all three `config.yaml` files.

### F3 — Bots not seeing each other at all
**Symptom:** coordinator posts `@researcher_bot [T1] TASK…`, researcher stays silent; works when a human mentions it.
**Root cause:** Telegram does not deliver bot messages to bots unless Bot-to-Bot Communication Mode is on and the bot is admin with privacy off.
**Fix:** README step 2–3; remove and re-add bots after changing privacy.

### F4 — Coder gets a task without data
**Symptom:** coder answers `STATUS: FAILED — no data in task`.
**Root cause:** coordinator wrote "use the data from T1" instead of pasting it (each specialist only reliably sees messages addressed to it).
**Fix:** rule "paste the needed data into the T2 TASK" in coordinator `SOUL.md` + example in `team-handoff`.

---

## Observed

### F5 — Coder addressed its RESULT to the Researcher (2026-10-05, Haiku 4.5)
**Request:** `@coordinator Посчитай сложные проценты: 500 000 тенге под 14% на 5 лет, график`
**What happened:** coder computed correctly and sent the chart, but its message started with `@researcher… [T1] RESULT` instead of `@coordinator…`. The coordinator was never woken, so no `✅ FINAL ANSWER`; the researcher woke up instead and replied "I should stay silent…".
**Root cause (found with `cat ~/.hermes/profiles/coder/SOUL.md`):** a configuration typo — `.env` had `COORDINATOR_BOT_USERNAME` set to the *researcher's* username. `setup.sh` substituted it for `{{COORDINATOR}}`, so the coder's (and researcher's) SOUL.md literally told them "the Coordinator is @researcher…". The model followed its prompt correctly. Our first guess (the small model copying a handle from a "never mention" rule) was wrong — lesson: inspect the rendered prompt before blaming the model.
**Fix:** corrected `.env`, re-ran `scripts/setup.sh`, reset sessions with `/new@<bot>` for each bot. Also removed other specialists' handles from specialist prompts (less chance of mis-addressing) and fixed the reply header to an exact template.
**Prevention:** `setup.sh` now refuses to run if two of the three usernames are equal.

### F6 — Coordinator woke both specialists while describing the team
**What happened:** answering "who is in your team?", the coordinator listed `@researcher…` and `@coder…`; Hermes (correctly) routed the message to both bots, which replied "ready for tasks".
**Fix:** coordinator rule — a bot's @username may appear only as the first word of a TASK message; elsewhere use plain names.

### F7 — Coder kept writing `@researcher` after the config was fixed
**What happened:** after correcting `.env`, re-running `setup.sh`, restarting the gateway and `/new`, the coder still started its RESULT with `@researcher…`. Its SOUL.md, MEMORY.md and skills contained no researcher handle.
**Root cause:** exporting the coder's session (`hermes -p coder sessions export --format trace`) showed its context still held its own earlier RESULT messages (written while the typo existed) and the coordinator's team list with all handles. The model copied its previous format over the instruction in SOUL.md; `/new` did not clear what the model saw.
**Fix:** (1) coordinator wakes on a specialist's *reply* regardless of the @ (`bots_require_mention: false`, `exclusive_bot_mentions: false` for the coordinator only) — after this the chain reached `✅ FINAL ANSWER`; (2) `session_search` disabled for specialists; (3) session history wiped (moved `state.db*` to a backup with the gateway stopped).

### F8 — A woken specialist cannot stay silent
**What happened:** the researcher, woken by a wrong mention, replied "I stay silent on other bots' results…".
**Root cause:** once a turn is dispatched, a small model always produces a message; "stay silent" in the prompt is not enforceable.
**Fix:** remove the reason it was woken (F5/F7); rely on gateway filters, not prompts, for "who should respond".

### F9 — SOUL.md edits not taking effect
**Root cause:** the gateway loads profiles at start and a session keeps its prompt snapshot.
**Fix (procedure):** `setup.sh` → restart gateway → `/new@<bot>` for every bot (or wipe `state.db`).
