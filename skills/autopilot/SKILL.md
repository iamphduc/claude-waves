---
name: autopilot
description: Use when the user types /autopilot or asks to run the workflow autonomously across a plan. Also the resume command after a halt.
---

Dispatch the `orchestrator-autonomous` subagent via the Agent tool, passing the user's args (if any) as the prompt.
