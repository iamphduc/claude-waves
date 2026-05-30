# Sprint: <name>

_From plan: docs/plans/<plan-slug>.md · Slug: <sprint-slug> · Status: <active | archived> · Generated: <YYYY-MM-DD>_

## Status board

| Slice | Title | Wave | Difficulty | Agent | Branch | PR | Status | Depends on |
|-------|-------|------|------------|-------|--------|----|--------|------------|
| <slice-code> | <one-line> | 1 | 1–5 | engineer-senior \| engineer-junior | <branch-name> | — | pending | — |

Wave membership lives in the **Wave** column; slices sharing a wave run in parallel and must own disjoint file sets.

## Per-slice detail

### <slice-code>: <title>
- **Difficulty justification:** <one line — why 1–5>
- **Scope:** what to do; what NOT to do
- **Files owned:** explicit paths (disjoint within the same wave)
- **Success criteria:** concrete checks
- **Depends on:** <slice codes or —>

---

## Field semantics

- **Slug:** matches the row in the main plan's Sprint sequence (`docs/plans/<plan-slug>.md`).
- **Sprint doc Status:** `active` while in `docs/sprints/`; flipped to `archived` immediately before `mv` to `docs/sprints/archive/`.
- **Slice Status transitions:** `pending` → `pr open` → `done`, with `blocked` as terminal.
- **PR values:** `—` / URL / `blocked` / `skipped — verification failed` / `merged`.
- **Difficulty (1–5):** 1 = trivial; 3 = ordinary; 5 = architecture-touching or ambiguous. Scored per slice; justification belongs in the per-slice detail.
- **Agent:** derived from Difficulty — **1–2 → `engineer-junior`**, **3–5 → `engineer-senior`**. The board is canonical; per-slice detail never re-states the score or agent.
- **Wave:** slices sharing a wave run in parallel and **must own disjoint file sets**. If two slices need the same file, push the dependent one to a later wave.
- **Branch naming:** `<sprint-slug>/<slice-code>` (kebab-case).
- **Files owned:** explicit paths, verified to exist; cross-checked for disjointness within the wave.

## Sprint summary

Appended by the orchestrator after the last wave completes, immediately before archive.

- **Slices shipped:** <slice-code list>
- **Runtime smoke:** <PR URL | clean> · bugs found+fixed: <N> (runtime regressions static checks missed) · deferred: <M>
- **Reviewer:** <PR URL | clean> · severe findings: <N> (count of `SEVERE:` PENDING entries emitted)
- **Queue entries:** resolved <N>, deferred <M> — link the deferred ones inline
- **Approximate token cost:** <number or rough range>
