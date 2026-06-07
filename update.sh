#!/usr/bin/env bash
#
# update.sh — refresh the multi-claude-workflow machinery in an existing project.
#
# Refreshes (mirrors upstream, add/overwrite):
#   agents/         -> .claude/agents/
#   skills/         -> .claude/skills/
#   docs/templates/ -> docs/templates/
# Overwrites these standalone docs:
#   docs/autonomous-policy.md, docs/engineer-protocol.md
#
# Leaves your project content untouched: docs/codebase-structure.md,
# docs/decisions.md, docs/handoff-queue.md, plans/, sprints/, known-issues/.
#
# Stale files (present locally, gone upstream) are listed and deleted ONLY after
# you confirm [y/N]. With no terminal (e.g. piped non-interactively) they are kept.
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

# Mirrored dirs as "src_rel:dst_abs".
mirrors=(
  "agents:$DEST/.claude/agents"
  "skills:$DEST/.claude/skills"
  "docs/templates:$DEST/docs/templates"
)

# 1) Collect stale files: present locally but no longer upstream.
stale=()
for entry in "${mirrors[@]}"; do
  src="$TMP/repo/${entry%%:*}"
  dst="${entry#*:}"
  [[ -d "$dst" ]] || continue
  while IFS= read -r rel; do
    [[ -e "$src/$rel" ]] || stale+=("$dst/$rel")
  done < <(cd "$dst" && find . -type f | sed 's|^\./||')
done

# 2) Warn and confirm before deleting anything.
if [[ ${#stale[@]} -gt 0 ]]; then
  echo
  echo "These local files no longer exist upstream:"
  printf '  %s\n' "${stale[@]#"$DEST"/}"
  if { exec 3</dev/tty; } 2>/dev/null; then
    read -r -p "Delete them to mirror upstream? [y/N] " ans <&3
    exec 3<&-
  else
    ans="n"
    echo "(no terminal: keeping them)"
  fi
  if [[ "$ans" == [yY] ]]; then
    for f in "${stale[@]}"; do rm -f "$f"; done
    echo "Deleted ${#stale[@]} stale file(s)."
  else
    echo "Kept stale files."
  fi
fi

# 3) Refresh machinery dirs from upstream (add/overwrite), then prune empty dirs.
echo "Updating ..."
for entry in "${mirrors[@]}"; do
  src="$TMP/repo/${entry%%:*}"
  dst="${entry#*:}"
  mkdir -p "$dst"
  cp -a "$src/." "$dst/"
  find "$dst" -mindepth 1 -type d -empty -delete 2>/dev/null || true
  echo "  ${entry%%:*}/ -> ${dst#"$DEST"/}/"
done

# 4) Overwrite standalone policy/protocol docs (never user stubs).
for f in docs/autonomous-policy.md docs/engineer-protocol.md; do
  mkdir -p "$DEST/$(dirname "$f")"
  cp -a "$TMP/repo/$f" "$DEST/$f"
  echo "  $f"
done

echo "Done."
