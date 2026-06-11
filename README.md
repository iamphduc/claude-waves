# claude-waves

Ship a plan in **waves** of parallel Claude engineers: strategy → sprint → parallel waves → review, with you as the merge gate between every wave.

A *wave* is a batch of slices with non-overlapping file ownership, built concurrently in isolated worktrees. Each wave lands behind you, trunk is verified, then the next wave dispatches — manually with `/code`, or unattended with `/autopilot`.

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

## Manual flow — you ride each wave

| Step | Skill | What happens |
|---|---|---|
| 1 | `/plan` | Planner interviews you, writes `docs/plans/<slug>.md` |
| 2 | `/sprint [slug]` | Drafts `docs/sprints/<slug>.md` — slices grouped into waves by file ownership |
| — | *read the sprint doc* | **Your quality gate** — catch bad wave grouping or overlapping file ownership before any engineer runs |
| 3 | `/code [slug]` | Runs the **wave loop**: one worktree per slice, all engineers in the wave dispatched at once, then halts for you to merge |
| — | merge the wave's PRs, reply `continue` | Next wave dispatches — repeat until the sprint's waves are done |
| 4 | *reviewer (auto)* | Code audit; opens a follow-up PR or returns `PR: clean` |
| — | merge review PR, reply `continue` | Sprint archives; `continue` chains into the next sprint |

## Autonomous flow — the waves ride themselves

`/autopilot [plan-slug] [--max-sprints=N] [--max-waves=N] [--max-runtime=Nh]` runs the whole plan unattended: dispatches each wave, auto-merges clean PRs (escalating risky ones), verifies trunk between waves, chains sprints, and halts + notifies at each gate. Invoking it is your consent to the auto-merges. Criteria, defaults, and resume behavior live in `docs/autonomous-policy.md`.

```
                                       ┌────────────────────────────────── SPRINT LOOP (outer) ──────────────────────────────────┐
                                       v                                                                                         │
┌───────────┐   ┌────────────┐   ┌────────────┐   ╔═══════════ WAVE LOOP (inner) ═══════════╗   ┌───────────┐   ┌───────────┐    │
│ /autopilot│──>│ Read policy│──>│ Read sprint│──>║ ┌──────────┐   ┌──────────┐   ┌───────┐ ║──>│ Reviewer  │──>│ Archive   │    │
│ plan-slug │   │ + bounds   │   │ doc        │   ║ │ Dispatch │──>│Auto-merge│──>│ Verify│ ║   │ +auto-mrg │   │ +mark     │    │
└───────────┘   └────────────┘   └────────────┘   ║ │ engineers│   │clean PRs │   │(waves)│ ║   └───────────┘   │ plan row  │    │
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
