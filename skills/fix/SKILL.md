---
name: fix
description: Use when the user types /fix <task> or asks for an ad-hoc code change outside the sprint workflow.
---

Parse `--merge-target=<branch>` from the args (default: origin's default branch) and pass it through with the rest.

Dispatch the `engineer` subagent via the Agent tool with the user's task description as the prompt. It sets up its own worktree and context per the protocol's **Standalone invocation** section and **defers teardown** — worktree stays up through merge.

From its summary, capture the **worktree path**, **branch**, and **PR URL**.

- **Hand back for merge:** end the turn with the PR URL and a note that the worktree is retained — the human can merge it, or ask for follow-up fixes, then reply `continue`.
- **Follow-up fixes (before merge):** re-dispatch `engineer` with the retained **worktree path** and **branch** as explicit dispatch context so it reuses the worktree (no recreate) and updates the same PR.
- **Confirm-on-resume:** `gh pr view <URL> --json mergedAt,state`; unmerged → re-end the turn. Merged → tear down: `cd "<parent-repo>" && git worktree remove <worktree-path> && git branch -d <branch>` (no `--force`/`-D`; on failure, leave it and tell the human).
