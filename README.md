# multi-claude-workflow

Multi-agent Claude Code workflow: strategy → sprint → parallel implementation → review, with you as the merge gate.

## Prerequisites

- Claude Code.
- `gh` CLI, authenticated.
- `git`.

## Install

Copy these folders into your project (new or existing repo):

- `agents/` → `.claude/agents/`
- `skills/` → `.claude/skills/`
- `docs/` → `docs/`

Everything the workflow needs ships in those folders, scaffolding included. Then fill two stubs for your project:

- `docs/codebase-structure.md` — your codebase brief; the **`## Smoke recipe`** section is required (engineers use it to bring the app up and browser-verify each slice before shipping).
- `docs/decisions.md` — architectural decisions, as you make them.

## Manual flow

| Step | Skill | What happens |
|---|---|---|
| 1 | `/plan` | Planner interviews you, writes `docs/plans/<slug>.md` |
| 2 | `/sprint [slug]` | Drafts `docs/sprints/<slug>.md` from a plan |
| — | *read the sprint doc* | **Your quality gate** — catch bad wave grouping or overlapping file ownership |
| 3 | `/code [slug]` | Runs the wave loop: creates worktrees, dispatches engineers per wave, halts for you to merge |
| — | merge PRs, reply `continue` | Repeat per wave |

Prefer to run each wave's slices in your own Claude Code sessions instead of subagents? Use **`/wave-prompts [slug] [wave]`** to emit paste-ready prompts — same wave model, you run the sessions and merge the PRs, no automatic bookkeeping.
| 4 | *reviewer (auto)* | Code audit; opens a follow-up PR or returns `PR: clean` |
| — | merge review PR, reply `continue` | Sprint archives; `continue` chains into the next sprint |

## Autonomous flow

`/autopilot [plan-slug] [--max-sprints=N] [--max-waves=N] [--max-runtime=Nh]` runs the whole plan unattended: auto-merges clean PRs (escalating low-confidence / non-trivial / `SEVERE:` PRs to you), verifies trunk between waves, chains sprints, and halts + notifies at each gate. Invoking it is your consent to the auto-merges. Defaults: `--max-sprints` unlimited, `--max-waves=20`, `--max-runtime=4h`.

Full criteria and detection rules live in `docs/autonomous-policy.md`. Resume after a halt by re-invoking `/autopilot` with the same args.

## Shortcuts

- **`/fix <task>`** — single-task dispatch in an isolated worktree, no sprint doc.
- **`/review [slug]`** — re-run the reviewer on the active sprint. Does not auto-archive; run `/code` afterward.
- **`/wave-prompts [slug] [wave]`** — emit paste-ready dispatch prompts for one wave's slices, to run in separate Claude Code sessions instead of dispatching subagents. Read-only; you run them and merge the PRs.

## When things halt

- **Preflight** — halts before wave 1 if there's no `origin`, the merge-target isn't pushed, or a sprint prerequisite isn't on the merge-target. Fix, re-run.
- **Wave merge gate** — expected. Merge PRs, reply `continue`.
- **Escalation gate (autopilot)** — a mergeable PR carries a risk signal. Review, merge, reply `continue`.
- **`BLOCKED` in handoff-queue** — resolve the issue or update the entry's `Resolution:` line, reply.

## State on disk

```
docs/
|-- known-issues/*.md     # durable constraints
|-- plans/<slug>.md       # strategic plans
|-- sprints/
|   |-- archive/          # completed sprints
|   `-- <slug>.md         # active sprint — status board + per-slice detail
|-- templates/            # doc templates the agents fill in
|-- autonomous-policy.md  # /autopilot criteria + gates
|-- codebase-structure.md # codebase brief (you maintain)
|-- decisions.md          # architectural decisions, authoritative (you maintain)
|-- engineer-protocol.md  # engineer/reviewer contract
`-- handoff-queue.md      # inter-agent comms — BLOCKED halts, PENDING defers, SOLVED informational
```
