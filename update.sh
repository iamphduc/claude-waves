#!/usr/bin/env bash
#
# update.sh — refresh the multi-claude-workflow machinery in an existing project.
#
# Overwrites/creates ONLY the files that ship in this repo:
#   agents/         -> .claude/agents/
#   skills/         -> .claude/skills/
#   docs/templates/ -> docs/templates/
#   docs/autonomous-policy.md, docs/engineer-protocol.md
#
# It never deletes anything. Your own files are left as-is: docs/codebase-structure.md,
# docs/decisions.md, docs/handoff-queue.md, plans/, sprints/, known-issues/, and any
# custom skills/agents you added locally.
#
# Run from your project root:
#   curl -fsSL https://raw.githubusercontent.com/iamphduc/multi-claude-workflow/main/update.sh | bash
#
set -euo pipefail

REPO="https://github.com/iamphduc/multi-claude-workflow.git"
BRANCH="main"
DEST="$(pwd)"

# Shallow clone into a temp dir so no git history comes along.
TMP="$(mktemp -d)"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

echo "Fetching multi-claude-workflow ..."
git clone --depth 1 --branch "$BRANCH" "$REPO" "$TMP/repo" >/dev/null 2>&1

echo "Updating ..."

# Refresh a dir: add/overwrite repo files only; local-only files are left untouched.
copy_into() {
  local src="$1" dst="$2"
  mkdir -p "$dst"
  cp -a "$TMP/repo/$src/." "$dst/"
  echo "  $src/ -> ${dst#"$DEST"/}/"
}
copy_into agents        "$DEST/.claude/agents"
copy_into skills        "$DEST/.claude/skills"
copy_into docs/templates "$DEST/docs/templates"

# Overwrite standalone policy/protocol docs (never user stubs).
for f in docs/autonomous-policy.md docs/engineer-protocol.md; do
  mkdir -p "$DEST/$(dirname "$f")"
  cp -a "$TMP/repo/$f" "$DEST/$f"
  echo "  $f"
done

echo "Done."
