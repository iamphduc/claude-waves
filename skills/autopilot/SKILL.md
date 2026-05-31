---
name: autopilot
description: Use when the user types /autopilot or asks to run the workflow autonomously across a plan. Also the resume command after a halt.
---

**You run this yourself, in the main loop** — you hold the `Agent` and `PushNotification` tools, dispatching engineers / reviewer / sprint-planner and sending halt notifications directly (a subagent can't spawn further subagents).

Run the **`/code` wave loop** — read `.claude/skills/code/SKILL.md` and follow it — with the autonomous deltas below. Read `docs/autonomous-policy.md` at the start of your turn; it defines the auto-merge criteria, the halt gates, inter-wave verification, and the safety bounds.

## Args

Parse from the user's args: optional plan slug, `--max-sprints=<N>`, `--max-waves=<N>`, `--max-runtime=<duration>`. Defaults per policy.

## Auto-merge (replaces `/code` Per-wave step 7 "Hand back for merge")

After each wave ships, apply the policy's **auto-merge criteria** and **escalation valve** to every open PR:

1. **Mergeable + no risk signal** → merge per policy, update the sprint doc.
2. **A mechanical criterion fails** → halt per gate 4; leave the wave's PRs for human triage.
3. **Mechanically mergeable but risk-flagged** → merge the wave's *other* clean PRs, then halt per gate 8 for the flagged one.

Once all wave PRs are merged: sync trunk (`/code` Per-wave step 1), run inter-wave verification, dispatch the next wave. Same for the smoke and reviewer gate PRs (`/code` Sprint complete); `PR: clean` → no merge step.

## Sprint-draft gate (between sprints)

When the `/code` flow would end with "Reply 'continue' to start the next sprint" (`/code`'s Archive gate):

1. Check `--max-sprints`. If reached → halt per gate 6.
2. Read the main plan; find the next `planned` row. If none → halt per a `PENDING` queue entry "plan complete".
3. Otherwise dispatch the `sprint-planner` (Agent call) for that row.
4. After it returns, **halt per gate 2** — the human must ack the draft. Do not dispatch this sprint's first wave (one sprint per turn).

On resume (human re-invokes `/autopilot`), re-read disk state: a fresh sprint doc with all rows `pending` means the gate was ack'd; proceed to wave 1.

## Halt + notify

Halt per policy (queue entry from `orchestrator` + `PushNotification` + end turn). Body of both: one sentence naming the gate and pointing at the artifact (PR URL, queue entry, sprint slug, command output snippet).

## Safety counters

Persist a `<!-- autopilot-run: started=<ISO8601> sprints=<N> waves=<N> -->` line; it lives in the active sprint doc during a sprint, the plan doc between sprints (move it on start/archive). Create at run start (stamp `started`) if absent; after `sprint-planner` returns a fresh doc, inject it before the gate-2 halt. Re-derive counters from it each turn; check bounds before each wave and after each archive.
