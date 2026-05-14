#!/usr/bin/env bash
# setup-khemoo setup — scaffolds Claude workspace files + agent stack.
# Idempotent: never overwrites existing files.
#
# Usage:
#   ./setup.sh                # --project (default): scaffold inside the current project
#   ./setup.sh --project      # explicit project scope
#   ./setup.sh --user         # scaffold inside ~/.claude/ for user-global config
# Exit 0 = success. Exit 2 = bad usage.

set -uo pipefail

SCOPE="project"
for arg in "$@"; do
  case "$arg" in
    --project) SCOPE="project" ;;
    --user)    SCOPE="user" ;;
    -h|--help)
      sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      echo "Use --project (default) or --user." >&2
      exit 2
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS="$(cd "$SCRIPT_DIR/.." && pwd)/assets"

if [ "$SCOPE" = "user" ]; then
  TARGET="${HOME}/.claude"
  mkdir -p "$TARGET"
else
  TARGET="${ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
fi

wrote=0
skipped=0

write_once() {
  local src="$1" dst="$2"
  if [ -e "$dst" ]; then
    echo "skip:  $dst (exists)"
    skipped=$((skipped + 1))
    return
  fi
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  echo "wrote: $dst"
  wrote=$((wrote + 1))
}

echo "Scope: $SCOPE (target: $TARGET)"
echo

# CLAUDE.md at the root of the target scope.
if [ "$SCOPE" = "user" ]; then
  write_once "$ASSETS/CLAUDE.md" "$TARGET/CLAUDE.md"
else
  write_once "$ASSETS/CLAUDE.md" "$TARGET/CLAUDE.md"
fi

# HUD statusline script + Claude Code settings (statusLine wired to absolute
# script path so it works regardless of cwd at runtime).
if [ "$SCOPE" = "user" ]; then
  CLAUDE_DIR="$TARGET"
else
  CLAUDE_DIR="$TARGET/.claude"
fi
STATUSLINE_DST="$CLAUDE_DIR/scripts/statusline.sh"
SETTINGS_DST="$CLAUDE_DIR/settings.json"

write_once "$ASSETS/statusline.sh" "$STATUSLINE_DST"
chmod +x "$STATUSLINE_DST" 2>/dev/null || true

# Settings template carries a @STATUSLINE_PATH@ placeholder; substitute the
# absolute path before writing so the statusLine command resolves no matter
# what cwd Claude Code runs from.
if [ ! -e "$SETTINGS_DST" ]; then
  mkdir -p "$(dirname "$SETTINGS_DST")"
  sed "s|@STATUSLINE_PATH@|$STATUSLINE_DST|g" "$ASSETS/settings.json" > "$SETTINGS_DST"
  echo "wrote: $SETTINGS_DST"
  wrote=$((wrote + 1))
else
  echo "skip:  $SETTINGS_DST (exists)"
  skipped=$((skipped + 1))
fi

# Project-only files (editor/lint configs don't make sense at user scope).
if [ "$SCOPE" = "project" ]; then
  write_once "$ASSETS/editorconfig"      "$TARGET/.editorconfig"
  write_once "$ASSETS/markdownlint.json" "$TARGET/.markdownlint.json"
fi

# Agent stack.
if [ "$SCOPE" = "user" ]; then
  AGENT_DIR="$TARGET/agents"
else
  AGENT_DIR="$TARGET/.claude/agents"
fi
for agent in "$ASSETS"/agents/*.md; do
  name=$(basename "$agent")
  write_once "$agent" "$AGENT_DIR/$name"
done

echo
echo "Setup complete: $wrote written, $skipped skipped."
