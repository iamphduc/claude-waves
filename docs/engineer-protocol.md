# Engineer protocol

Execute a scoped task on a dedicated branch in an isolated worktree. Report only via the final structured summary — the skill that dispatched you files your concerns into `docs/handoff-queue.md`.

## Required dispatch context

- **sprint slug**, **slice code**, **branch name**
- **scope**, **files owned**, **success criteria**
- **merge-target branch** — the branch you base your worktree on and the orchestrator integrates into: `<plan-slug>` under the wave loop; standalone callers derive it per **Standalone invocation**.
- **parent-repo path** — absolute path of the main repo
- **worktree path** — absolute path of your working dir
- **dev ports** *(optional, default `web 3900` / `api 3901`)* — use exactly these; never pick your own, never retry on a neighbouring port.
- **teardown** *(optional, default `immediate`)* — `defer` (leave the worktree after pushing; orchestrator removes it post-merge) or `immediate` (remove it yourself once pushed — the orchestrator integrates from the origin ref).

Any required field missing → minimal summary with a `BLOCKED` concern naming the gaps, skip all work, end. Never on `teardown` or `dev ports` (optional), and never when dispatched standalone — derive it per the next section.

## Standalone invocation

Only `/fix` dispatches you with just a task description. Derive the rest, don't block:

- **parent-repo:** `git rev-parse --path-format=absolute --git-common-dir`, trailing `/.git` stripped. Never cwd.
- **merge-target:** the `--merge-target=<branch>` you were passed, else origin's default branch (`git symbolic-ref refs/remotes/origin/HEAD`), else `main`. A fix cuts off trunk, never off a plan branch.
- **naming:** slug is short kebab-case from the task — `sprint slug` = `fix`, `slice code` = `<slug>`, `branch` = `fix-<slug>`, worktree `<parent-repo>/.claude/worktrees/fix-<slug>/`.
- **scope, files owned, success criteria:** infer from the task, capping files owned to what it plausibly touches.
- **teardown:** `defer` — the `/fix` loop removes the worktree once the PR merges.
- **worktree:** a follow-up fix names an existing worktree path — `cd` in and reuse it; otherwise create it per **Your worktree**.

## Your worktree

The orchestrator normally pre-creates your worktree and passes its path; `cd` into it. If it doesn't exist (standalone `/fix`, or a pasted prompt), create it first:

`git fetch origin && git worktree add <worktree-path> -b <branch-name> origin/<merge-target>`

## Path discipline

Never touch the parent repo. **Every `Edit`/`Write` path must be absolute and under `<worktree-path>` — never relative, never outside it. Verify before writing; if not, stop.** (`Read` outside is fine.)

`cd "<worktree-path>"` once at turn start so Bash runs there.

## Surfacing concerns

Never silently fill ambiguity — flag it. In your summary, list each as `[TYPE] one-line body`:

- `BLOCKED` — you cannot proceed, or verification failed.
- `PENDING` — defensible default taken, knowingly-incomplete spot, or scope-creep opportunity.
- `SOLVED` — only alongside a `BLOCKED` or `PENDING`: marks a related thing resolved inline.

Any `BLOCKED` → stop immediately: no push, no PR, no cleanup. Leave the worktree intact for inspection.

## Shipping the work (only when no BLOCKED)

1. **Static checks.** Run the project's headless checks (tests / typecheck / lint / build). Any failure → `BLOCKED`, stop. No harness → note it in the summary's Static checks field, cap Confidence at `medium`.
2. **Runtime verification.** Verify your slice in a real browser before shipping:
   - **Bring the app up** per the `## Smoke recipe` in `docs/codebase-structure.md` (start commands, DB setup, URLs, seeded credentials), on your assigned **dev ports**.
   - **Drive it** with the `chrome-devtools` tools: navigate to each affected route and confirm every runtime-observable behavior your slice introduces — check the real DOM snapshot, console, and network, not just that the page loaded.
   - **On a failing behavior:** fix and re-verify, or `BLOCKED` if it needs judgment.
   - **When done:** stop every server you started and any stray you found; record what you drove in the summary's `Runtime verified` field.
   - **No `## Smoke recipe`, or a pure-static slice** with nothing to drive → note it there and cap Confidence at `medium`.
3. **Commit and push your branch** (commit message prefixed with the slice code). Then:
   - **Slice engineer in the wave loop:** **don't open a PR** — the orchestrator integrates your branch into the wave's one PR; report the pushed branch.
   - **Everyone else** — standalone `/fix`, and the reviewer whether or not its worktree was pre-created: **open a PR** against the merge-target (title prefixed with the slice code), report its URL.
4. **Clean up — only when `teardown` is `immediate`:** `cd "<parent-repo-path>"` → `git worktree remove <worktree-path>` → `git branch -d <branch-name>`. Never `git checkout` in the parent repo. On failure → `PENDING`, set Cleanup to `partial`, stop further cleanup. When `defer`, skip removal: leave worktree and branch intact for the orchestrator's post-merge teardown, set Cleanup to `deferred — worktree <worktree-path> retained`.

Never use `--force` or `-D` — if something blocks, let a human investigate.

## Final output

End your turn with the structured summary at `docs/templates/engineer-summary.md`, inline (not written to a file); read it at turn start.
