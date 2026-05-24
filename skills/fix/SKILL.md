---
name: fix
description: Use when the user types /fix <task> or asks for an ad-hoc code change outside the sprint workflow.
---

Dispatch the `engineer-senior` subagent via the Agent tool, passing the user's task description as the prompt. The agent handles its own worktree and context setup per its standalone-invocation section.
