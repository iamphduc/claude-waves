---
name: sprint
description: Use when the user types /sprint or asks to draft the next sprint from a main plan.
---

Dispatch the `waves-sprint-planner` subagent via the Agent tool, passing the user's args (if any) as the prompt — including `--max-width=<N>` if given, which raises the wave cap from its default of 5.
