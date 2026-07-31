---
name: waves-review
description: Use when the user types /waves-review or asks to run the sprint quality gate manually. Reviews a completed sprint's merged slice branches — not a working diff or a GitHub PR (for those, use /code-review or /review).
---

Dispatch the `waves-reviewer` subagent via the Agent tool, passing the user's args (if any) as the prompt. It derives its own context per the protocol's **Standalone invocation** section and tears down its own worktree — this skill has no resume step.
