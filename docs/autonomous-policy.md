# Autonomous mode policy

## Auto-merge criteria

Merge any PR that clears the bar below — `/autopilot` is standing consent for the run. (If `CLAUDE.md` forbids unattended merges, add an autopilot carve-out or use `/code`.)

A PR is **mechanically mergeable** only if **all** hold:

- `gh pr checks <url>` reports every required check as `pass`.
- `gh pr view <url> --json mergeable,mergeStateStatus` returns `mergeable: MERGEABLE` and `mergeStateStatus: CLEAN`.
- No reviews marked `CHANGES_REQUESTED`.
- No unresolved review threads — `gh api graphql -f query='{repository(owner:"<owner>",name:"<repo>"){pullRequest(number:<n>){reviewThreads(first:100){nodes{isResolved}}}}}'` returns no node with `isResolved: false`.

**Precondition.** Merge-target branch protection must **not** require a human approving review (else `mergeStateStatus` stays `BLOCKED` → gate 3).

**Transient vs terminal.** Before treating a non-mergeable PR as gate 3, classify the failing condition. *Transient* — required checks still `pending`/running (not `fail`), or `mergeStateStatus: BEHIND` — is **not** a halt: wait and re-poll (a `/loop` resume covers unattended runs), re-syncing the branch on `BEHIND`. **Halt (gate 3) only on terminal failures:** a check reporting `fail`, a `CHANGES_REQUESTED` review, an unresolved review thread, or `mergeStateStatus: DIRTY`/`BLOCKED`.

**Escalation valve (gate 6 — does not halt).** A mechanically-mergeable PR whose engineer summary reported `Confidence: low` still merges — but append its slice code to a `<!-- review-focus: <slice>,... -->` line in the sprint doc. The sprint reviewer must drive and inspect every `review-focus` slice (see `agents/reviewer.md`). This trades a halt for a mandatory reviewer pass.

Otherwise merge (merge commit, not squash): `gh pr merge <url> --merge --delete-branch`, then set the sprint doc's PR cell to `merged` and Status to `done`. Any failure → halt + notify (gate 3).

## Halt gates

| # | Name | Trigger | Queue type |
|---|---|---|---|
| 1 | blocked-concern | `BLOCKED` concern from any engineer or from you | `BLOCKED` |
| 2 | severe-finding | Reviewer finding prefixed `SEVERE:` | `PENDING` |
| 3 | auto-merge-fail | Auto-merge fails per criteria above | `BLOCKED` |
| 4 | inter-wave-verify | Inter-wave verification fails | `BLOCKED` |
| 5 | safety-bound | Safety bound hit | `PENDING` |
| 6 | escalation-valve | A mechanically-mergeable PR reported `Confidence: low` | — (no halt; `review-focus` tag) |
| 7 | plan-complete | Plan complete — the next-sprint check finds no `planned` rows left in the main plan | `PENDING` |

**Every gate halts — end the turn, except gate 6** (it merges and tags the slice for mandatory review instead of halting). `Queue type` only labels the queue entry (`BLOCKED` = resolve before resuming; `PENDING` = human can ack); both halt the run.

On halt: append a one-line `docs/handoff-queue.md` entry from `orchestrator` naming the gate and artifact, `PushNotification`, then end the turn.

## Inter-wave verification

After a wave's PRs merge and trunk syncs, before the next wave: run the project's verification command in the parent repo — the `Verification:` line in `docs/codebase-structure.md`, else detect it from repo files.

**Non-zero exit → restore trunk, then halt (gate 4).** A bad merge must never be left on trunk. Revert this wave's merge commits, newest first — `git revert --no-edit -m 1 <merge-sha>` each — then push and re-run verification to confirm green. Only once trunk is green again do you halt + notify (gate 4), naming the reverted PRs so the human can re-dispatch them on the next resume. If a revert itself conflicts, stop immediately and halt with trunk as-is, flagged `BLOCKED`.

## Safety bounds

Three caps from `/autopilot` args; hitting any → halt at gate 5:

- `--max-sprints=<N>` — sprints completed. Default: unlimited (until no `planned` rows).
- `--max-waves=<N>` — total waves dispatched. Default: `20`.
- `--max-runtime=<duration>` — wall-clock (`30m`, `4h`). Default: `12h`.

Persist a counter line `<!-- autopilot-run: started=<ISO8601> sprints=<N> waves=<N> -->` in the active sprint doc (the plan doc between sprints; move on start/archive, re-inject after `sprint-planner` writes a fresh doc). Re-derive each turn; check all bounds before each wave and after each archive.
