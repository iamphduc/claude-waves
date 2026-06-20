# Engineer summary template

Engineers end their turn with this structured summary, inline in their response (never written to a file).

- **Slice:** <slice-code>
- **Changed files:** path → one-line description per file
- **Pushed branch / PR:** wave-loop → `<branch-name>` (pushed; no PR). Standalone `/fix` → PR URL. Or `blocked` / `skipped — verification failed` / `clean`.
- **Concerns:** list each as `[TYPE] one-line body`, or `none`
- **Static checks:** commands run and their results — or `no harness found` — or `failed — see concerns` (tests / typecheck / lint / build)
- **Runtime verified:** runtime-observable behaviors you drove in the browser and confirmed (e.g. `/guide hard-loads`, `Nunito renders`, `locale switch persists`) — or `none — pure static slice` — or `not verified — no smoke recipe` (cap Confidence at `medium`)
- **Cleanup:** `done` / `partial — see concerns` / `skipped — blocked` / `deferred — worktree <path> retained` (teardown left to the orchestrator post-merge)
- **Confidence:** high / medium / low — and why
