---
name: code
description: Use when the user types /code or asks to execute a sprint via the wave loop — dispatch engineers per wave, hand back to the human to merge each wave's PRs, then review and archive.
---

Work in thinking mode. You run this wave loop in the main loop yourself — dispatch engineers, the reviewer, and (between sprints) the sprint-planner via `Agent`.

Parse from args: the plan slug (if any) and `--merge-target=<branch>` (the run's trunk; default `main`). If no plan is given, list `docs/plans/*.md` (excluding `Status: archived`) and ask which to run.

State on disk, re-read every resume: `docs/sprints/<slug>.md` (status board), `docs/handoff-queue.md` (concerns), `docs/plans/<plan-slug>.md` (master plan).

## Conventions

- **Dispatch:** one `Agent` call per slice in one message, **no `isolation`**; pass each engineer its dispatch context per `docs/engineer-protocol.md`.
- **Hand back for merge:** end the turn listing each open PR as `- <label>: <PR URL>` under a one-line header plus a "reply `continue`" line. Don't poll, auto-merge, or proceed.
- **Confirm-on-resume:** `gh pr view <URL> --json mergedAt,state` each PR you handed back; any unmerged → re-end the turn. Once all are merged, sync trunk (`git checkout <merge-target> && git pull origin <merge-target>`) and set the PR/Status cells to `merged`/`done`.
- **Gate-worktree resume** (smoke, reviewer): if the branch exists, find its PR — open → re-end the turn pointing at it; merged → confirm-on-resume, then skip ahead; none → reset (`git reset --hard origin/<merge-target> && git clean -fd`) and re-run, skipping pre-create.

## Preflight (once, before the first wave; skip on resume mid-sprint)

Worktrees branch from `origin/<merge-target>`, so before pre-creating any, halt naming the first that fails:

- `origin` remote exists (`git remote get-url origin`).
- The merge-target is on origin (`git ls-remote --heads origin <merge-target>` returns a ref).
- Every non-slice prerequisite (new dependencies, the plan/sprint docs) is committed and pushed to the merge-target.

## The loop

For each row in the plan's Sprint sequence:

1. **Read the sprint doc** `docs/sprints/<sprint-slug>.md` (re-read on resume to find the next wave). If missing → halt and tell the human to run `/sprint`; never draft it yourself. It is your source of truth — trust it.

2. **For each wave, in order:**

   **Resume a halted wave:** any `blocked` slice (a prior `BLOCKED` halt the human has since resolved at its cause, not by editing the worktree) → re-dispatch it fresh: reset its worktree if it exists (`git reset --hard origin/<merge-target> && git clean -fd`, skip pre-create) else recreate per (b), then dispatch in (c) with any still-`pending` slice. Skip `merged`/`done` slices.

   a. **Sync** (skip on the first wave of the first sprint). Confirm-on-resume the prior wave's `pr open` slices.

   b. **Pre-create worktrees:** per slice, `git worktree add <parent-repo>/.worktrees/<sprint-slug>-<slice-code>/ -b <branch-name> origin/<merge-target>`. Branch names come from the sprint doc, **flat** (`<sprint-slug>-<slice-code>`, no `/`).

   c. **Dispatch** per the Dispatch convention, one call per slice (subagent_type `engineer-junior`/`engineer-senior` per the sprint doc).

   d. **Translate concerns:** per `[TYPE] body` line in each engineer summary's `Concerns`, append an entry to `docs/handoff-queue.md` per `docs/templates/handoff-queue.md` (`from: engineer-<tier>`; create the file if missing).

   e. **Update the status board:** per slice, set PR and Status in the sprint doc per `docs/templates/sprint.md`.

   f. **Halt check.** `PENDING`/`SOLVED` are non-halting. Any `BLOCKED` concern this wave → halt, naming the trigger and queue entry. If >50% of the wave's slices ended `blocked`, first append a wave-summary `BLOCKED` entry from `orchestrator` describing the pattern and point the halt at it.

   g. **Hand back for merge:**

      ```
      Wave <N> of sprint <slug> awaiting merge:
      - <slice-code>: <PR URL>
      - <slice-code>: <PR URL>

      Merge in any order, then reply `continue` to dispatch wave <N+1>.
      ```

3. **Sprint complete** when all functional waves are `done`:

   a. **Runtime smoke (hard gate).** Drive the actual app yourself from the main loop.
      - **Resume:** gate-worktree resume on `<sprint-slug>-smoke`; merged → skip to the reviewer (b).
      - **Set up.** Read the `## Smoke recipe` in `docs/codebase-structure.md`; if missing or insufficient to start the app, halt and ask the human to add it (fail closed). Pre-create `<parent-repo>/.worktrees/<sprint-slug>-smoke/` from `origin/<merge-target>`, bring the app up there per the recipe, and confirm reachable. Fixes land in this worktree, never on trunk; smoke an auth-walled preview locally.
      - **Verify.** Drive the app (browser / curl) against each engineer summary's `Runtime to smoke` plus the sprint doc's per-slice runtime criteria — check the actual page/DOM/response, never assumptions.
      - **On failure → auto-fix, re-smoke.** Fix in the worktree, commit (slice-prefixed), re-run until green. Halt instead when a failure is unfixable, ambiguous, or needs a judgment call (logic, data, multi-file) — end with the diagnosis. Log every fix and finding to `docs/handoff-queue.md`.
      - **Ship.** Record a smoke summary in the sprint doc (checked / found+fixed / deferred) and stop every server you started. Nothing fixed → no PR, go to (b). Fixes → push `<sprint-slug>-smoke`, open a PR (leave the worktree), and hand back:

        ```
        Sprint <slug> smoke awaiting merge:
        - smoke: <PR URL>

        Merge, then reply `continue` to dispatch the reviewer.
        ```

   b. **Dispatch the reviewer** (subagent_type `reviewer`) over the sprint's diff (including smoke fixes) as the final wave.
      - **Resume:** gate-worktree resume on `<sprint-slug>-review`; merged → skip to (d).
      - Pre-create `<parent-repo>/.worktrees/<sprint-slug>-review/` on branch `<sprint-slug>-review` from `origin/<merge-target>`.
      - Dispatch per the convention, plus the sprint slug and this sprint's merged slice branches.
      - Translate `PENDING`/`SOLVED` concerns; a `SEVERE:`-prefixed `PENDING` finding → surface it in the (c) hand-back if a PR ships, else in the (h) message.
      - PR URL → (c). `PR: clean` → (d).

   c. **Hand back for review-PR merge:**

      ```
      Sprint <slug> review awaiting merge:
      - review: <PR URL>
      - SEVERE: <finding>   (omit unless the reviewer emitted a `SEVERE:` finding)

      Merge, then reply `continue` to archive.
      ```

   d. Append the Sprint summary to the sprint doc per `docs/templates/sprint.md`.
   e. Flip the sprint doc `Status:` to `archived`, then `mv` it to `docs/sprints/archive/`.
   f. **Prune the handoff queue:** if over 100 entries, drop the oldest **resolved** ones until ≤100; never drop `Resolution: pending`. Entries are date-keyed — don't renumber.
   g. **Update the plan:** set the sprint's row in `docs/plans/<plan-slug>.md` to `done`. If unresolved `PENDING`s warrant reshaping later sprints (rescope, reorder), edit those rows too — only that, never rewrite history.
   h. End the turn: `Sprint <slug> complete. Reply 'continue' to start the next sprint.`
