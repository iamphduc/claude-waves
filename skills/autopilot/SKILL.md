---
name: autopilot
description: Use when the user types /autopilot or asks to run the workflow autonomously across a plan. Also the resume command after a halt.
---

Work in thinking mode. **You run this yourself, in the main loop** — you have the `Agent` and `PushNotification` tools, so you dispatch engineers / reviewer / sprint-planner and send halt notifications directly. Do not delegate to a subagent (subagents cannot spawn further subagents, so they cannot dispatch engineers).

Run the **`/code` wave loop** — read `.claude/skills/code/SKILL.md` and follow it — with the autonomous deltas below. Read `docs/autonomous-policy.md` at the start of your turn; it defines the auto-merge criteria, the eight halt gates, inter-wave verification, and the safety bounds.

## Args

Parse from the user's args: optional plan slug, `--max-sprints=<N>`, `--max-waves=<N>`, `--max-runtime=<duration>`. Defaults per policy.

## Auto-merge (replaces `/code` step 2g "Hand back for merge")

After each wave's engineers ship, for each open PR, apply the policy's **mechanical-mergeability criteria** and the **escalation valve**:

1. **Mergeable + no risk signal** → merge with a **merge commit** (not squash): `gh pr merge <url> --merge --delete-branch`. Update the sprint doc's PR cell to `merged` and Status to `done`.
2. **A mechanical criterion fails** (failing/pending check, not CLEAN, changes-requested, unresolved thread) → halt + notify per gate 4. Leave the wave's PRs for human triage.
3. **Mechanically mergeable but a risk signal is present** (low-confidence slice, non-trivial smoke fix, `SEVERE:`) → merge the wave's *other* clean PRs, then halt + notify per gate 8 (escalation) for the flagged PR — the human reviews and merges just that one.

Once all wave PRs are merged: sync trunk per `/code` step 2a, run **inter-wave verification** per policy, then dispatch the next wave.

Same logic for the **smoke PR** (`/code` step 3a) and the **reviewer PR** (`/code` step 3b). If either returns `PR: clean`, no merge step.

## Sprint-draft gate (between sprints)

When the `/code` flow would end with "Reply 'continue' to start the next sprint" (step 3g):

1. Check `--max-sprints`. If reached → halt + notify per gate 6.
2. Read the main plan; find the next `planned` row. If none → halt cleanly with a `PENDING` queue entry "plan complete", notify, end turn.
3. Otherwise dispatch the `sprint-planner` (Agent call) for that row.
4. After it returns, **halt + notify per gate 2** — the human must ack the draft. Do not proceed to dispatch this sprint's first wave.

On resume (human re-invokes `/autopilot`), re-read disk state: a fresh sprint doc with all rows `pending` means the gate was ack'd; proceed to wave 1.

## Halt + notify

Halt per policy (queue entry from `orchestrator` + `PushNotification` + end turn). Body of both: one sentence naming the gate and pointing at the artifact (PR URL, queue entry, sprint slug, command output snippet).

## Safety counters

Track sprints completed, waves dispatched, and start time across the turn. Check bounds before each new wave and after each sprint archive.
