---
name: autopilot
description: Use when the user types /autopilot or asks to run the workflow autonomously across a plan. Also the resume command after a halt.
---

**Run the `/code` wave loop yourself** (`.claude/skills/code/SKILL.md`) — same main-loop, self-dispatch model — with the deltas below, under `docs/autonomous-policy.md`, which you read at the start of every turn. Beyond `/code` you also dispatch the `sprint-planner` and notify on halt. Args: optional plan slug plus the policy's `--max-*` bounds.

## Teardown

Override the `/code` dispatch convention: dispatch engineers with `teardown: immediate`, not `defer`. There's no human iterating on the worktree here, so engineers tear down at ship time as usual; you don't do the post-merge worktree removal that `/code`'s confirm-on-resume does.

## Auto-merge

Don't hand back the wave or reviewer PRs. For each, apply the policy's auto-merge criteria + escalation valve: merge the clean ones; a failed criterion or risk-flagged PR halts (merge the wave's others first).

## Between sprints

Don't end with "reply continue" — run one sprint per turn:

1. `--max-sprints` reached → halt at the safety-bound gate (policy gate 5).
2. No `planned` row left in the plan → halt at the plan-complete gate (policy gate 7).
3. Else dispatch the `sprint-planner` and proceed straight into the new sprint's wave loop — no sprint-draft halt.
