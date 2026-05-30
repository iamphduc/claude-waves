# multi-claude-workflow

Multi-agent Claude Code workflow: strategy → sprint → parallel implementation → review, with you as the merge gate.

## Prerequisites

- Claude Code installed.
- `gh` CLI installed and authenticated (the wave loop and engineers use it for PRs).
- `git` worktree support (any modern git).

## Install in a target repo

From within the target repo, run `/bootstrap`. It copies `agents/`, `skills/`, `docs/templates/`, and `docs/engineer-protocol.md` from this template repo, scaffolds the `docs/` subdirs, and creates stub `codebase-structure.md` / `decisions.md`.

**Chicken-and-egg:** install `skills/bootstrap/` to `~/.claude/skills/` once by hand so the first `/bootstrap` works. The source path is hardcoded in `skills/bootstrap/SKILL.md` as `E:\Projects\multi-claude-workflow\` — edit it if you move or clone this repo elsewhere.

## Manual flow

| Step | Skill | What happens |
|---|---|---|
| 1 | `/plan` | Planner interviews you (via `grill-me`), writes `docs/plans/<slug>.md` |
| 2 | `/sprint [slug]` | Sprint-planner drafts `docs/sprints/<slug>.md` from a plan |
| — | *(read the sprint doc)* | **Your quality gate** — catches bad wave grouping or overlapping file ownership |
| 3 | `/code [slug]` | The main loop runs the wave loop directly: pre-creates worktrees, dispatches engineers per wave, halts for you to merge PRs |
| — | merge wave PRs, reply `continue` | Repeat per wave |
| 4 | *(runtime smoke auto-fires)* | Main loop starts the app and exercises each slice's runtime behavior (per the `## Smoke recipe` in `docs/codebase-structure.md`); auto-fixes bugs static checks missed and opens a smoke PR, or proceeds clean. Catches the regressions `typecheck/lint/build` can't see |
| — | merge smoke PR (if any), reply `continue` | — |
| 5 | *(reviewer auto-fires)* | Last-defense code audit; opens a follow-up PR or returns `PR: clean` |
| — | merge review PR, reply `continue` | Sprint archives. `continue` again to chain into the next sprint. |

Each agent ends its turn telling you the next step.

## Shortcuts

- **`/fix <task>`** — ad-hoc single-task dispatch (engineer-senior, isolated worktree, no sprint doc). For typos, renames, one-off bugs.
- **`/review [slug]`** — manually invoke reviewer on the active sprint. Use for mid-sprint sanity passes or re-reviews after fixing prior findings. Note: standalone reviewer does **not** auto-archive the sprint — run `/code` afterward or archive manually.

## State on disk

| Path | Purpose |
|---|---|
| `docs/plans/<slug>.md` | Strategic plans |
| `docs/sprints/<slug>.md` | Active sprint (status board + per-slice detail) |
| `docs/sprints/archive/` | Completed sprints |
| `docs/handoff-queue.md` | Inter-agent comms; `BLOCKED` halts, `PENDING` defers, `SOLVED` informational |
| `docs/codebase-structure.md` | Codebase brief (you maintain) |
| `docs/decisions.md` | Authoritative architectural decisions (you maintain) |
| `docs/known-issues/*.md` | Durable constraints |

All workflow state lives on disk — any agent can be resumed cold from a fresh session.

## When things halt

- **Preflight** — `/code`/`/autopilot` halts before the first wave if there's no `origin` remote, the merge-target isn't pushed, or a sprint prerequisite (a new dep, the docs) isn't on the merge-target. Push/set it up, re-run.
- **Wave merge gate** — expected. Merge PRs in any order, reply `continue`.
- **Runtime smoke** — the main loop runs the app before review; it auto-fixes bugs it can and only halts if a runtime failure needs your judgment, or if `docs/codebase-structure.md` has no `## Smoke recipe` to bring the app up (fail-closed — add one).
- **Escalation gate (autopilot)** — a PR is mechanically mergeable but carries a risk signal (low-confidence slice, non-trivial smoke fix, or a `SEVERE:` review finding). Autopilot merged the clean PRs and left this one for you — review and merge it, reply `continue`.
- **`BLOCKED` in handoff-queue** — read the entry, resolve the underlying issue or update the entry's `Resolution:` line, reply.
- **Sprint complete** — reply `continue` to chain into the next sprint (or `/sprint` first if no `planned` row remains in the plan).
- **Engineer PR has failing CI but local tests passed** — no auto-handler. Investigate manually; push a fix to the branch or close the PR and re-dispatch.
- **Sprint-planner draft is wrong** — re-run `/sprint`, choose "discard" when prompted.
- **Plan needs updating mid-execution** — `/plan` with the same slug, choose "update."

## Layout

```
agents/        # subagent definitions (planner, sprint-planner,
               # engineer-junior, engineer-senior, reviewer)
skills/        # slash-command triggers (plan, sprint, code, review, fix,
               # bootstrap, autopilot). code + autopilot carry the wave loop,
               # which the main loop runs directly (no orchestrator subagent —
               # subagents can't dispatch the engineer subagents the loop needs)
docs/
  templates/   # copied into target repos by /bootstrap
  engineer-protocol.md   # shared contract for engineers and reviewer
```

## Autonomous flow

`/autopilot [plan-slug] [--max-sprints=N] [--max-waves=N] [--max-runtime=Nh]` runs the workflow unattended across a whole plan: auto-merges clean PRs with a **merge commit** (escalating low-confidence / non-trivial / `SEVERE:` PRs to you), verifies trunk between waves, chains into the next sprint, runs the runtime-smoke gate before each sprint's review, halts + notifies via `PushNotification` at eight gates. Invoking `/autopilot` is your standing consent to the auto-merges. Defaults: `--max-sprints` unlimited, `--max-waves=20`, `--max-runtime=4h`.

Full criteria, gates, and detection rules live in `docs/autonomous-policy.md`. Resume after halt: re-invoke `/autopilot` (same args).

For one-off manual runs, use `/code` — same wave loop, no auto-merge, no chaining.
