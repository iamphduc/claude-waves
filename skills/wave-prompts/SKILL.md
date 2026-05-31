---
name: wave-prompts
description: Use when the user types /wave-prompts or asks to emit per-wave dispatch prompts to run engineers in separate Claude Code sessions (session fan-out instead of subagent dispatch).
---

Read-only and one-shot: read the sprint doc and emit one paste-ready dispatch prompt per slice in the requested wave, then stop. Do **not** dispatch subagents, create worktrees, write the status board / handoff-queue, or merge PRs — the engineers and the human do that. This is the session-fan-out alternative to `/code`'s subagent fan-out.

Parse from args: the sprint slug (if any), the wave number (default `1`), and `--merge-target=<branch>` (default `main`). If no slug is given, use the sole non-archived `docs/sprints/*.md`; if several exist, list them and stop.

## Inputs

- `docs/sprints/<slug>.md` — status board (Wave / Slice / Branch columns) + per-slice detail (scope, files owned, success criteria).
- `docs/engineer-protocol.md` — the Required dispatch context fields each prompt must carry.

## Preflight (read-only)

Check `origin` exists (`git remote get-url origin`) and the merge-target is on origin (`git ls-remote --heads origin <merge-target>`). On failure, print a warning banner atop your output — do not halt; you only emit text.

## Emit

For the requested wave's slices (grouped by the **Wave** column):

1. Print a header: the wave number, the slices in it, and the reminder — *launch one session per block **at the project root**, paste it, merge the PRs when green, then re-run `/wave-prompts <slug> <next-wave>`.*
2. Print one fenced block per slice, filled from the sprint doc:

   ```
   You are implementing one slice of sprint `<slug>`. Read and follow docs/engineer-protocol.md exactly.

   - sprint slug:      <slug>
   - slice code:       <code>
   - branch:           <slug>-<code>
   - merge-target:     <merge-target>
   - parent-repo:      <absolute project root>
   - worktree:         <parent>/.worktrees/<slug>-<code>/
   - scope:            <from per-slice detail>
   - files owned:      <paths>
   - success criteria: <criteria>

   Create your worktree: git worktree add <worktree> -b <branch> origin/<merge-target>, then proceed per the protocol (ship a PR, clean up).
   ```

   `<absolute project root>` is your cwd; `branch` is the sprint doc's Branch column; `worktree` is `<parent>/.worktrees/<slug>-<code>/`.

Then end your turn — there is no state to resume.
