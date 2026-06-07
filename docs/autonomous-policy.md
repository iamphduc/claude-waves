# Autonomous mode policy

## Auto-merge criteria

For the run's duration, invoking `/autopilot` is standing consent to merge any PR clearing the bar below, overriding a general "confirm each merge" preference. (If `CLAUDE.md` hard-forbids unattended merges, add an autopilot carve-out there or run `/code` for the supervised flow.)

A PR is **mechanically mergeable** only if **all** hold:

- `gh pr checks <url>` reports every required check as `pass` (no `pending`, no `fail`).
- `gh pr view <url> --json mergeable,mergeStateStatus` returns `mergeable: MERGEABLE` and `mergeStateStatus: CLEAN`.
- No reviews marked `CHANGES_REQUESTED`.
- No unresolved review threads — `gh api graphql -f query='{repository(owner:"<owner>",name:"<repo>"){pullRequest(number:<n>){reviewThreads(first:100){nodes{isResolved}}}}}'` returns no node with `isResolved: false`.

**Precondition.** The merge target's branch protection must **not** require a human approving review. If approval is required `mergeStateStatus` stays `BLOCKED` and every PR halts at gate 3 until the rule is relaxed or an approval is supplied.

**Escalation valve.** Even when mechanically mergeable, **withhold the merge and halt (gate 6)** if the slice's engineer summary reported `Confidence: low` (e.g. a runtime behavior it couldn't verify, or a non-trivial runtime fix it made).

Otherwise merge with a **merge commit** (not squash): `gh pr merge <url> --merge --delete-branch`. Update the sprint doc's PR cell to `merged` and Status to `done`. Any merge failure → halt + notify (gate 3).

## Halt gates

| # | Name | Trigger | Queue type |
|---|---|---|---|
| 1 | blocked-concern | `BLOCKED` concern from any engineer or from you | `BLOCKED` |
| 2 | severe-finding | Reviewer finding prefixed `SEVERE:` | `PENDING` |
| 3 | auto-merge-fail | Auto-merge fails per criteria above | `BLOCKED` |
| 4 | inter-wave-verify | Inter-wave verification fails | `BLOCKED` |
| 5 | safety-bound | Safety bound hit | `PENDING` |
| 6 | escalation-valve | A mechanically-mergeable PR carries a risk signal; withheld for human review | `PENDING` |
| 7 | plan-complete | Plan complete — the next-sprint check finds no `planned` rows left in the main plan | `PENDING` |

**All gates halt the same way** — end the turn. `Queue type` only labels the handoff-queue entry (`BLOCKED` = resolve before resuming; `PENDING` = a checkpoint the human can ack); it does **not** decide whether the gate halts. A `PENDING` gate still stops the run.

On halt: append a one-line `docs/handoff-queue.md` entry from `orchestrator` describing the gate and pointing at the artifact, then `PushNotification`, then end the turn. Resume via human re-invoking `/autopilot`.

## Inter-wave verification

After trunk sync, before dispatching the next wave: run the project's verification command in the parent repo. A `Verification:` line in `docs/codebase-structure.md` → fall back to detecting the test command from repo files. Non-zero exit → halt + notify (gate 4).

## Safety bounds

Three independent caps parsed from `/autopilot` args; hitting any → halt cleanly at gate 5:

- `--max-sprints=<N>` — cap on sprints completed this run. Default: unlimited (run until plan has no `planned` rows).
- `--max-waves=<N>` — emergency cap on total waves dispatched this run. Default: `20`.
- `--max-runtime=<duration>` — wall-clock cap (`30m`, `4h`, etc). Default: `4h`.

Track progress against them with a persisted counter line — `<!-- autopilot-run: started=<ISO8601> sprints=<N> waves=<N> -->` — kept in the active sprint doc during a sprint and the plan doc between sprints (move it on start/archive; re-inject after `sprint-planner` writes a fresh doc). Re-derive the counters each turn and check all three bounds before each wave and after each archive.
