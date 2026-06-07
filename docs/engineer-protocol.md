# Engineer protocol

Execute a scoped task on a dedicated branch in an isolated worktree. Report only via the final structured summary — the **orchestrator** (`/code` or `/autopilot`) parses your concerns into `docs/handoff-queue.md`.

## Required dispatch context

- **sprint slug**, **slice code**, **branch name**
- **scope**, **files owned**, **success criteria**
- **merge-target branch** (usually `main`)
- **parent-repo path** — absolute path of the main repo
- **worktree path** — absolute path of your working dir
- **teardown** *(optional, default `immediate`)* — `defer` (leave the worktree after the PR; orchestrator removes it post-merge) or `immediate` (remove it yourself at ship).

Any required field missing → minimal summary with a `BLOCKED` concern naming the gaps, skip all work, end. (Never `BLOCKED` on `teardown` — it's optional.)

## Your worktree

The orchestrator normally pre-creates your worktree and passes its path; `cd` into it. If it doesn't exist (standalone `/fix`/`/review`, or a pasted prompt), create it first:

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
   - **Bring the app up** per the `## Smoke recipe` in `docs/codebase-structure.md` (start commands, DB setup, URLs, seeded credentials).
   - **Drive it** with the `chrome-devtools` tools: navigate to each affected route and confirm every runtime-observable behavior your slice introduces — check the real DOM snapshot, console, and network, not just that the page loaded.
   - **On a failing behavior:** fix and re-verify, or `BLOCKED` if it needs judgment.
   - **When done:** stop any servers you started; record what you drove in the summary's `Runtime verified` field.
   - **No `## Smoke recipe`, or a pure-static slice** with nothing to drive → note it there and cap Confidence at `medium`.
3. **Commit, push, open the PR** against the merge-target. Prefix the commit message and PR title with the slice code.
4. **Clean up — only when `teardown` is `immediate`:** `cd "<parent-repo-path>"` → `git checkout <merge-target>` → `git worktree remove <worktree-path>` → `git branch -d <branch-name>`. On failure → `PENDING`, set Cleanup to `partial`, stop further cleanup. When `defer`, skip removal: leave worktree and branch intact for the orchestrator's post-merge teardown, set Cleanup to `deferred — worktree <worktree-path> retained`.

Never use `--force` or `-D` — if something blocks, let a human investigate.

## Final output

End your turn with the structured summary at `docs/templates/engineer-summary.md`, inline (not written to a file); read it at turn start.
