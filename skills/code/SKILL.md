---
name: code
description: Use when the user types /code or asks to execute a sprint via the wave loop — dispatch engineers per wave, hand back to the human to merge each wave's PRs, then review and archive.
---

Work in thinking mode. **You run this wave loop yourself, in the main loop** — you have the `Agent` tool, so you dispatch engineers, the reviewer, and (between sprints) the sprint-planner directly. Do **not** try to delegate the loop to a subagent: subagents cannot spawn further subagents, so an orchestrator-as-subagent cannot dispatch engineers. You are the orchestrator.

Parse the plan slug (if any) from the user's args.

Your state lives on disk: `docs/sprints/<slug>.md` (status board), `docs/handoff-queue.md` (concerns), `docs/plans/<plan-slug>.md` (master plan). On every resume, read those to figure out where you left off.

If no plan was specified, list `docs/plans/*.md` (excluding `Status: archived`) and ask which to execute.

## Preflight (once, before the first wave)

Worktrees are cut from `origin/<merge-target>` and engineers push PRs, so the base must be on the host first. Before pre-creating any worktree, verify:

- An `origin` remote exists (`git remote get-url origin`). If not → halt: "No `origin` remote — create the GitHub repo and push before running `/code`."
- The merge-target branch exists on origin (`git ls-remote --heads origin <merge-target>` returns a ref; default `<merge-target>` is `main`). If not → halt: "Merge-target `<merge-target>` isn't on origin — push it first."
- Any sprint prerequisite that isn't code-in-a-slice (a new dependency the sprint assumes, the plan/sprint docs) is committed and pushed to the merge-target — otherwise slice worktrees branch off a base that lacks it. If a prerequisite is missing, halt and name it.

Skip the preflight on resume mid-sprint.

## The loop

For each row in the plan's Sprint sequence:

1. **Read the sprint doc** at `docs/sprints/<sprint-slug>.md`. If missing, halt and tell the human to run `/sprint` first — never draft the sprint doc yourself. The doc is your source of truth for slice scope, wave grouping, agent assignments, file ownership, and branches; trust it. On resume mid-sprint, re-read it to figure out which wave is next.

2. **For each wave, in order:**

   a. **Sync.** On resume, `gh pr view <URL> --json mergedAt,state` every `pr open` slice from the prior wave; if any unmerged, re-end the turn — never dispatch on partial merges. Once confirmed, in the parent repo: `git checkout <merge-target>` then `git pull origin <merge-target>`, and update those PR cells to `merged` and Status to `done`. Skip the checkout+pull on the very first wave of the very first sprint.

   b. **Pre-create worktrees:** for each slice, `git worktree add <worktree-path> -b <branch-name> origin/<merge-target>`. Use `<parent-repo>/.worktrees/<sprint-slug>-<slice-code>/` for the worktree path (a flat filesystem dir, collision-free across sprints). Branch names come from the sprint doc and are **flat** (`<sprint-slug>-<slice-code>`, no `/`) so they can never D/F-collide with a `<sprint-slug>`-named integration branch used as the merge-target.

   c. **Dispatch in parallel:** in a single message, one `Agent` call per slice (subagent_type `engineer-junior` or `engineer-senior` per the sprint doc), **no `isolation`** (the worktrees already exist). Each prompt passes the engineer's full Required dispatch context (see `docs/engineer-protocol.md`) and the `cd <worktree-path>` first-action instruction.

   d. **Translate concerns:** for each `[TYPE] body` line in each engineer summary's `Concerns`, append one entry to `docs/handoff-queue.md` per `docs/templates/handoff-queue.md` with `from: engineer-<tier>`. Create the file from the template if missing.

   e. **Update status board:** per slice, edit the sprint doc — set PR and Status per the value sets in `docs/templates/sprint.md`.

   f. **Halt check.** `PENDING` and `SOLVED` are non-halting. If any engineer emitted a `BLOCKED` concern this wave, halt the turn — end with a halt message naming the trigger and pointing at the queue entry. If additionally >50% of the wave's slices ended `blocked`, before halting append a wave-summary `BLOCKED` entry to `docs/handoff-queue.md` from `orchestrator` describing the failure pattern, and point the halt message at that summary entry instead.

   g. **Hand back for merge.** End the turn with:

      ```
      Wave <N> of sprint <slug> awaiting merge:
      - <slice-code>: <PR URL>
      - <slice-code>: <PR URL>

      Merge in any order, then reply `continue` to dispatch wave <N+1>.
      ```

      Do not poll, auto-merge, or proceed.

3. **Sprint complete** when all functional waves are `done`:

   a. **Runtime smoke (main-loop gate).** Static checks (engineers) and the code reviewer cannot see runtime or visual regressions — this gate runs the actual app and exercises the sprint's runtime-observable behavior. **You run it from the main loop**: you have a browser via the chrome-devtools MCP and can start servers; it cannot be delegated to a sandboxed agent. Runs in both `/code` and `/autopilot` — it is a hard gate.
      - **Recipe.** Read the `## Smoke recipe` section of `docs/codebase-structure.md` (bring-up commands, DB migrate/seed, login creds, key URLs). If it is missing or insufficient to start the app, **halt** and ask the human to add it — do not skip the gate (fail closed).
      - **Worktree.** Pre-create `<parent-repo>/.worktrees/<sprint-slug>-smoke/` on branch `<sprint-slug>-smoke` from `origin/<merge-target>` (mirrors the reviewer). Smoke fixes land here, never on the merge-target directly.
      - **Bring up** the app from that worktree per the recipe: install if needed, migrate + seed the DB, start the server(s); confirm reachable before testing. If the deployed preview is auth-walled (e.g. Vercel SSO), smoke locally.
      - **Checklist.** Collect the runtime-observable behaviors to verify: each engineer summary's `Runtime to smoke` field plus the sprint doc's per-slice runtime success criteria. Drive the app (browser / curl) and verify against the actual page/DOM/response, never against assumptions.
      - **On failure → auto-fix, then re-smoke.** Diagnose, fix in the worktree, commit (slice-prefixed), re-run the failed check; repeat until green. **Halt** instead of fixing when a failure is unfixable, ambiguous, or needs a judgment call (logic, data, or a multi-file change) — end with the diagnosis (`/autopilot` notifies). Log every fix and finding to `docs/handoff-queue.md`.
      - **Record + tear down.** Append a smoke-run summary to the sprint doc (checked / found+fixed / deferred). Stop every server you started; leave the worktree for the PR.
      - **Ship.** If you committed fixes: push `<sprint-slug>-smoke`, open a PR, and **hand back for merge** (`/code`) or auto-merge it (`/autopilot`) before continuing. If nothing needed fixing: smoke clean, no PR — proceed.

   b. **Dispatch the reviewer** (Agent call, subagent_type `reviewer`) as a final review wave — it is the sprint's last defense layer (simplify code, simplify tests, find bugs, check security), starting from the sprint's diff (including any smoke fixes) but free to chase a finding's call chain into adjacent code:
      - **Resume mid-review:** if branch `<sprint-slug>-review` already exists, check for an associated PR. PR open → re-end turn pointing at it per (c). PR merged → sync (`checkout` + `pull`) and skip to (d). No PR → reset the worktree (`git reset --hard origin/<merge-target> && git clean -fd`) and re-dispatch, skipping pre-create.
      - Pre-create worktree at `<parent-repo>/.worktrees/<sprint-slug>-review/` on branch `<sprint-slug>-review` from `origin/<merge-target>`.
      - Single `Agent` call (no `isolation`), passing the same Required dispatch context an engineer would get, plus the sprint slug and the list of merged slice branches from this sprint.
      - Translate any `PENDING` / `SOLVED` concerns into `docs/handoff-queue.md` as usual. Reviewer does not emit `BLOCKED`; severe findings come through as `PENDING` with body prefixed `SEVERE:` — surface those in the halt message in (c) if a PR is also shipped, or in the end-of-turn message in (h) if not.
      - If reviewer returns a PR URL, proceed to (c). If reviewer returns `PR: clean`, skip to (d).

   c. **Hand back for review-PR merge.** End the turn with:

      ```
      Sprint <slug> review awaiting merge:
      - review: <PR URL>

      Merge, then reply `continue` to archive.
      ```

      Do not poll, auto-merge, or proceed. On resume, `gh pr view <URL> --json mergedAt,state`; if unmerged, re-end the turn. Once confirmed, `git checkout <merge-target>` then `git pull origin <merge-target>` in the parent repo, then proceed to (d).

   d. Append the Sprint summary section to the sprint doc per `docs/templates/sprint.md` (slices shipped, **runtime-smoke outcome**, queue entries resolved/deferred, approximate token cost, reviewer outcome).
   e. Flip the sprint doc header `Status:` to `archived`, then `mv` the file to `docs/sprints/archive/`.
   f. **Prune the handoff queue.** If the file exceeds 100 entries, drop the oldest **resolved** entries (by date) until ≤100 remain; never drop entries with `Resolution: pending`. Entries are date-keyed and stable — do not renumber.
   g. `Edit` the just-completed sprint's row in `docs/plans/<plan-slug>.md`: set its Status cell to `done`. If unresolved `PENDING` entries warrant reshaping later sprints (rescope, reorder), edit those rows too — but only that; never destructively rewrite history.
   h. End the turn with `Sprint <slug> complete. Reply 'continue' to start the next sprint.`

## Unattended variant

`/autopilot` runs this same loop without the per-wave merge hand-back — it auto-merges per `docs/autonomous-policy.md`, chains across sprints, and halts only at policy gates. Use `/code` when you want to merge each wave yourself.
