---
name: bootstrap
description: Use when the user types /bootstrap or asks to install the multi-claude-workflow into a target repo (templates, agents, skills, docs scaffolding).
---

**Source:** `E:\Projects\multi-claude-workflow\` (edit this skill if you move the template repo). Refuse to run if cwd equals source.

Copy into the target:
- `<source>/agents/*` → `.claude/agents/`
- `<source>/skills/*` → `.claude/skills/`
- `<source>/docs/templates/*` → `docs/templates/`
- `<source>/docs/engineer-protocol.md` → `docs/engineer-protocol.md`

Create if missing: `docs/plans/`, `docs/sprints/archive/`, `docs/known-issues/`, `docs/handoff-queue.md` (from `docs/templates/handoff-queue.md`), and minimal stubs for `docs/codebase-structure.md` and `docs/decisions.md`.

Skip files that already exist; ask the user before overwriting any. Report what was copied/created/skipped, then suggest `/plan` as the next step.
