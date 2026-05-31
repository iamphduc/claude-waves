# Autonomous mode policy

Read before changing autonomous behavior.

## Auto-merge criteria

Invoking `/autopilot` is the user's standing consent to merge PRs that clear the bar below — for the duration of the run, this overrides a general "confirm each merge" preference. (If the user's `CLAUDE.md` hard-forbids unattended merges, add an autopilot carve-out there, or run `/code` for the supervised, merge-it-yourself flow.)

A PR is **mechanically mergeable** only if **all** hold:

- `gh pr checks <url>` reports every required check as `pass` (no `pending`, no `fail`).
- `gh pr view <url> --json mergeable,mergeStateStatus` returns `mergeable: MERGEABLE` and `mergeStateStatus: CLEAN`.
- No reviews marked `CHANGES_REQUESTED`.
- No unresolved review threads — `gh api graphql -f query='{repository(owner:"<owner>",name:"<repo>"){pullRequest(number:<n>){reviewThreads(first:100){nodes{isResolved}}}}}'` returns no node with `isResolved: false`.

**Precondition.** Autopilot assumes the merge-target's branch protection does **not** require a human approving review. The machine never approves its own PRs, so if approval is required, `mergeStateStatus` stays `BLOCKED` (never `CLEAN`) and **every** PR halts at gate 4 by design — autopilot will merge nothing until the rule is relaxed or an approval is supplied.

**Escalation valve.** Even when mechanically mergeable, **withhold the merge and halt for human review (gate 8)** if the PR carries a risk signal — the machine merges what it's confident about and escalates the rest:

- the slice's engineer summary reported `Confidence: low`, or
- (smoke PR) the smoke gate's fix was **non-trivial** — touched logic, data, or multiple files rather than a localized wiring/config fix.

(A reviewer `SEVERE:` finding is **not** an escalation-valve signal: it already halts at gate 3 the moment it's emitted, before the reviewer PR's merge step is reached.)

Otherwise merge with a **merge commit** (not squash): `gh pr merge <url> --merge --delete-branch`. Update the sprint doc's PR cell to `merged` and Status to `done`. Any merge failure → halt + notify (gate 4), leave the PR for human triage.

## Halt gates

| # | Trigger | Queue type |
|---|---|---|
| 1 | `BLOCKED` concern from any engineer or from you (the loop driver) | `BLOCKED` |
| 2 | Sprint-draft review — after `sprint-planner` writes a new doc | `PENDING` |
| 3 | Reviewer finding prefixed `SEVERE:` | `PENDING` |
| 4 | Auto-merge fails per criteria above | `BLOCKED` |
| 5 | Inter-wave verification fails | `BLOCKED` |
| 6 | Safety bound hit | `PENDING` |
| 7 | Runtime smoke fails and can't be auto-fixed (unfixable / ambiguous / needs a judgment call), or no smoke recipe exists | `BLOCKED` |
| 8 | Escalation valve — a mechanically-mergeable PR carries a risk signal (see *Auto-merge criteria*), withheld for human review | `PENDING` |
| 9 | Plan complete — the next-sprint check finds no `planned` rows left in the main plan | `PENDING` |

**All gates halt the same way** — by ending the turn (see *On halt* below) and waiting for a human re-invoke. The `Queue type` column is only the label and urgency written on the handoff-queue entry (`BLOCKED` = must resolve before resuming, `PENDING` = a checkpoint the human can ack); it does **not** decide whether the gate halts. This is why a `PENDING`-typed gate here still stops the run, even though `PENDING` "defers" in the general queue semantics.

The runtime smoke (`/code`'s smoke gate) runs before the reviewer in autopilot too. It **auto-fixes** failures it can (commit on the smoke branch, re-smoke) and only halts per gate 7 when a failure needs a human — so a clean run never stops here.

On halt: append a one-line `docs/handoff-queue.md` entry from `orchestrator` describing the gate and pointing at the artifact (PR URL, queue entry, sprint slug, command output), then `PushNotification` with the same one-liner, then end the turn. Resume via human re-invoking `/autopilot`.

## Inter-wave verification

After trunk sync, before dispatching the next wave: run the project's verification command in the parent repo. Detection order: a `Verification:` line in `docs/codebase-structure.md` → fall back to detecting `npm test` / `pytest` / `cargo test` / `go test ./...` from repo files. Non-zero exit → halt + notify (gate 5).

## Safety bounds

Parsed from `/autopilot` args:

- `--max-sprints=<N>` — cap on sprints completed this run. Default: unlimited (run until plan has no `planned` rows).
- `--max-waves=<N>` — emergency cap on total waves dispatched this run. Default: `20`.
- `--max-runtime=<duration>` — wall-clock cap (`30m`, `4h`, etc). Default: `4h`.

Bounds are independent halt gates: hitting any → halt cleanly per gate 6.

