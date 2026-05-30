# Autonomous mode policy

The `/autopilot` skill (run by the main loop) operates under this policy. Read before changing autonomous behavior.

## Auto-merge criteria

A PR is safe to auto-merge only if **all** hold:

- `gh pr checks <url>` reports every required check as `pass` (no `pending`, no `fail`).
- `gh pr view <url> --json mergeable,mergeStateStatus` returns `mergeable: MERGEABLE` and `mergeStateStatus: CLEAN`.
- No reviews marked `CHANGES_REQUESTED`.
- No unresolved review threads.

Merge: `gh pr merge <url> --squash --delete-branch`. Any failure → halt + notify, leave the PR for human triage.

## Halt gates

| # | Trigger | Queue type |
|---|---|---|
| 1 | `BLOCKED` concern from any engineer or from you (the loop driver) | `BLOCKED` |
| 2 | Sprint-draft review — after `sprint-planner` writes a new doc | `PENDING` |
| 3 | Reviewer finding prefixed `SEVERE:` | `PENDING` (already emitted) |
| 4 | Auto-merge fails per criteria above | `BLOCKED` |
| 5 | Inter-wave verification fails | `BLOCKED` |
| 6 | Safety bound hit | `PENDING` |

On halt: append a one-line `docs/handoff-queue.md` entry from `orchestrator` describing the gate and pointing at the artifact (PR URL, queue entry #, sprint slug, command output), then `PushNotification` with the same one-liner, then end the turn. Resume via human re-invoking `/autopilot`.

## Inter-wave verification

After trunk sync, before dispatching the next wave: run the project's verification command in the parent repo. Detection order: a `Verification:` line in `docs/codebase-structure.md` → fall back to detecting `npm test` / `pytest` / `cargo test` / `go test ./...` from repo files. Non-zero exit → halt + notify (gate 5).

## Safety bounds

Parsed from `/autopilot` args:

- `--max-sprints=<N>` — cap on sprints completed this run. Default: unlimited (run until plan has no `planned` rows).
- `--max-waves=<N>` — emergency cap on total waves dispatched this run. Default: `20`.
- `--max-runtime=<duration>` — wall-clock cap (`30m`, `4h`, etc). Default: `4h`.

Bounds are independent halt gates: hitting any → halt cleanly per gate 6.

