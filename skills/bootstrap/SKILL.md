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
- `<source>/docs/autonomous-policy.md` → `docs/autonomous-policy.md` (the `/autopilot` skill reads it)

Create if missing: `docs/plans/`, `docs/sprints/archive/`, `docs/known-issues/`, `docs/handoff-queue.md` (from `docs/templates/handoff-queue.md`), and minimal stubs for `docs/codebase-structure.md` and `docs/decisions.md`.

The `docs/codebase-structure.md` stub must include a **`## Smoke recipe`** section for the runtime-smoke gate (`/code` step 3a) to read — scaffold it with these headers for the human to fill: `Start commands` (web/api/etc.), `DB setup` (migrate + seed commands), `Login credentials` (seeded test accounts per role), `Key URLs` (per shell/route), and a `Verification:` line (the headless build/test command). Tell the user the smoke gate is fail-closed: it halts until this section is filled.

Skip files that already exist; ask the user before overwriting any. Report what was copied/created/skipped, then suggest `/plan` as the next step.
