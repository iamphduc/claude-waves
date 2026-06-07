#!/usr/bin/env bash
#
# install.sh — bootstrap a project with the multi-claude-workflow setup.
#
# Copies, into the current directory:
#   agents/  -> .claude/agents/
#   skills/  -> .claude/skills/
#   docs/    -> docs/
#
# Run from your project root:
#   curl -fsSL https://raw.githubusercontent.com/iamphduc/multi-claude-workflow/main/install.sh | bash
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

# Copy a source dir's CONTENTS into a destination dir, merging with anything
# already there. cp -a "<dir>/." preserves dotfiles and attributes.
copy_into() {
  local src="$1" dst="$2"
  mkdir -p "$dst"
  cp -a "$TMP/repo/$src/." "$dst/"
  echo "  $src/ -> ${dst#$DEST/}/"
}

echo "Installing into $DEST ..."
copy_into agents "$DEST/.claude/agents"
copy_into skills "$DEST/.claude/skills"
copy_into docs   "$DEST/docs"

echo "Done."
