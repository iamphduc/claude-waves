# Handoff Queue

Inter-agent communication. **The human is the ultimate arbiter** — `BLOCKED` entries halt the orchestrator until acknowledged. **One line per entry** so the queue is graspable at a glance; never break an entry across multiple lines.

Format: `` - #<N> `[YYYY-MM-DD · TYPE · from → to · sprint: <slug> · slice: <code>]` <body> **Resolution:** pending `` (or `**Resolution:** <YYYY-MM-DD> — <what changed> [optional link to docs/decisions.md#anchor]`).

`#<N>` is the entry's current position (oldest = #1); glance at the tail to see total count and judge whether prune is due (>100). `from` / `to` may be any of `engineer-junior` / `engineer-senior` / `orchestrator` / `sprint-planner` / `planner` / `human` — anyone can address anyone. Omit `slice:` for sprint-wide entries; omit `sprint:` for project-wide entries.

Types: `BLOCKED` halts · `PENDING` defers (defaults taken, knowingly-incomplete spots, scope-creep opportunities) · `SOLVED` informational, only emitted alongside a `BLOCKED` or `PENDING` to mark a related thing resolved inline.

Resolve inline (do not delete prematurely); if decision-worthy, write a one-liner to `docs/decisions.md` and link from the Resolution line. At sprint end the orchestrator prunes resolved entries to the 100 latest and renumbers from #1; unresolved entries (`Resolution: pending`) are never pruned.

---
