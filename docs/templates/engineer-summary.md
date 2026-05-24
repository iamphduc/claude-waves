# Engineer summary template

Engineers end their turn with this structured summary inline in their response (free-form prose gets truncated when relayed to the orchestrator).

- **Slice:** <slice-code>
- **Changed files:** path → one-line description per file
- **PR:** URL — or `blocked` — or `skipped — verification failed` — or `clean` (no change warranted)
- **Concerns:** list each as `[TYPE] one-line body`, or `none`
- **Verification:** commands run and their results — or `no verification harness found` — or `failed — see concerns`
- **Cleanup:** `done` / `partial — see concerns` / `skipped — blocked`
- **Confidence:** high / medium / low — and why
