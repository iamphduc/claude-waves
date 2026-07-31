# claude-waves

Ship a plan in **waves** of parallel Claude engineers: strategy → sprint → parallel waves → review, with you as the merge gate between every wave.

A *wave* is a batch of slices with non-overlapping file ownership, built concurrently in isolated worktrees. Each wave integrates into **one PR** onto a long-lived **plan branch**, is verified, and lands behind you; then the next wave dispatches. At the plan's end, **one final PR** merges the plan branch to `main`. Run it with `/code`, or unattended with `/autopilot`.

## Install

Requires Claude Code, `git`, and an authenticated `gh` CLI. From your project root (new or existing repo), run:

```bash
curl -fsSL https://raw.githubusercontent.com/iamphduc/claude-waves/main/install.sh | bash
```

This copies into your project:

- `agents/` → `.claude/agents/`
- `skills/` → `.claude/skills/`
- `docs/` → `docs/`

It merges into existing folders and overwrites same-named files, so review your working tree afterward (or copy the folders by hand if you prefer).

Everything the workflow needs ships in those folders, scaffolding included. Then fill two stubs for your project:

- `docs/codebase-structure.md` — your codebase brief; the **`## Smoke recipe`** section is required (engineers use it to bring the app up and browser-verify each slice before shipping).
- `docs/decisions.md` — architectural decisions, as you make them.

### Update

Refresh the agents/skills/templates and policy docs to the latest. It only overwrites files that ship in this repo — it never deletes anything and never touches your `codebase-structure.md`, `decisions.md`, plans, or sprints:

```bash
curl -fsSL https://raw.githubusercontent.com/iamphduc/claude-waves/main/update.sh | bash
```

Because it never deletes, retired files linger. Agents now ship under a `waves-` prefix so they can't collide with — or silently overwrite — an agent of your own, and the standalone review skill is gone (`/code` dispatches the reviewer itself). If you installed before that, remove the old copies by hand — otherwise an in-flight sprint doc can still dispatch them, and the stale `/review` skill points at an agent you just deleted:

```bash
rm -f  .claude/agents/engineer-junior.md .claude/agents/engineer-senior.md \
       .claude/agents/reviewer.md .claude/agents/sprint-planner.md \
       docs/templates/engineer-summary.md
rm -rf .claude/skills/review .claude/skills/waves-review
```

## Manual flow — you ride each wave

| Step | Skill | What happens |
|---|---|---|
| 1 | `/plan` | Planner interviews you, writes `docs/plans/<slug>.md` |
| 2 | `/sprint [slug]` | Drafts `docs/sprints/<slug>.md` — slices grouped into waves by file ownership |
| — | *read the sprint doc* | **Your quality gate** — catch bad wave grouping or overlapping file ownership before any engineer runs |
| 3 | `/code [slug]` | Runs the **wave loop**: one worktree per slice, all engineers in the wave dispatched at once, then integrates them into **one PR** onto the plan branch and halts for you to merge |
| — | merge the wave's PR, reply `continue` | Next wave dispatches — repeat until the sprint's waves are done |
| 4 | *reviewer (auto)* | Code audit; opens a follow-up PR onto the plan branch or returns `PR: clean` |
| — | merge review PR, reply `continue` | Sprint archives; `continue` chains into the next sprint |
| 5 | *plan complete* | One final PR merges the plan branch → `main` |

### Which command, and what it branches off

The three execution commands differ by **base branch**, not by size of change:

| Command | Cuts off | Lands on | Cleans up after itself |
|---|---|---|---|
| `/code`, `/autopilot` | the plan branch | plan branch, one PR per wave | the orchestrator, post-merge |
| `/fix <task>` | trunk (`origin`'s default branch, or `--merge-target=`) | trunk, one PR | the `/fix` loop, after you merge |

`/fix` is for work that stands alone — it never touches a plan branch, so running it mid-plan gives you a change that diverges from the plan until both land on trunk. The reviewer has no command of its own: `/code` dispatches it automatically at sprint end, and re-runs it on resume if its PR isn't merged.

## Autonomous flow — the waves ride themselves

`/autopilot [plan-slug] [--max-sprints=N] [--max-waves=N] [--max-runtime=Nh]` runs the whole plan unattended: dispatches each wave, integrates + verifies it, auto-merges the wave PR onto the plan branch (escalating risky ones), chains sprints, then opens and merges the final plan→`main` PR — halting + notifying at each gate. Invoking it is your consent to the auto-merges. Criteria, defaults, and resume behavior live in `docs/autonomous-policy.md`.

```
                                       ┌────────────────────────────────── SPRINT LOOP (outer) ──────────────────────────────────┐
                                       v                                                                                         │
┌───────────┐   ┌────────────┐   ┌────────────┐   ╔═══════════ WAVE LOOP (inner) ═══════════╗   ┌───────────┐   ┌───────────┐    │
│ /autopilot│──>│ Read policy│──>│ Read sprint│──>║ ┌──────────┐   ┌──────────┐   ┌───────┐ ║──>│ Reviewer  │──>│ Archive   │    │
│ plan-slug │   │ + bounds   │   │ doc        │   ║ │ Dispatch │──>│Integrate │──>│ Merge │ ║   │ +auto-mrg │   │ +mark     │    │
└───────────┘   └────────────┘   └────────────┘   ║ │ engineers│   │+ verify  │   │wave PR│ ║   └───────────┘   │ plan row  │    │
                                                  ║ └──────────┘   └──────────┘   └───┬───┘ ║                   └─────┬─────┘    │
                                                  ║      ^                            │     ║                         │          │
                                                  ║      └──── more waves <───────────┘     ║                         │          │
                                                  ╚═════════════════════════════════════════╝                         │          │
                                                                                        ┌─────────────────────────────┘          │
                                                                                        │                                        │
                        ┌──────────────┐                                       planned rows left?                                │
                        │ Plan complete│<──── no ───────────────────────────────────────┴─────── yes ───────┐                    │
                        └──────────────┘                                                       ┌────────────v─────────────┐      │
                                                                                               │sprint-planner drafts next│──────┘
                                                                                               │sprint ──> (re-read doc)  │
                                                                                               └──────────────────────────┘

Any policy gate at any step → halt + notify, then end the turn.
```

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
