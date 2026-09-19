#!/usr/bin/env bash
# setup-khemoo setup — scaffolds Claude Code and Codex instruction files.
# Idempotent: never overwrites existing files or symlinks.
#
# Usage:
#   ./setup.sh                     # project scope, Claude Code (compatible default)
#   ./setup.sh --project --cli both # shared project instructions + Claude HUD
#   ./setup.sh --user --cli codex   # ${CODEX_HOME:-$HOME/.codex}/AGENTS.md
#   ./setup.sh --cli claude|codex|both
# Exit 0 = success. Exit 2 = bad usage.

set -euo pipefail

# === arguments ===
SCOPE="project"
CLI="claude"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --project) SCOPE="project" ;;
    --user)    SCOPE="user" ;;
    --cli)
      if [ "$#" -lt 2 ]; then
        echo "--cli requires claude, codex, or both." >&2
        exit 2
      fi
      shift
      CLI="$1"
      case "$CLI" in
        claude|codex|both) ;;
        *) echo "Invalid CLI: $CLI (expected claude, codex, or both)." >&2; exit 2 ;;
      esac
      ;;
    -h|--help)
      sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      echo "Use --project (default) or --user, with --cli claude|codex|both." >&2
      exit 2
      ;;
  esac
  shift
done

# === paths & target scope ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS="$(cd "$SCRIPT_DIR/.." && pwd)/assets"
CLAUDE_ASSETS="$ASSETS/claude"

if [ "$SCOPE" = "project" ]; then
  TARGET="${ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
  CLAUDE_DIR="$TARGET/.claude"
else
  CLAUDE_DIR="${HOME}/.claude"
  CODEX_DIR="${CODEX_HOME:-${HOME}/.codex}"
fi

# === helpers ===
wrote=0
skipped=0

write_once() {
  local src="$1" dst="$2"
  # -e does not include dangling symlinks. Preserve those too.
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    echo "skip:  $dst (exists)"
    skipped=$((skipped + 1))
    return
  fi
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  if [ "${3:-}" = "executable" ]; then
    chmod +x "$dst"
  fi
  echo "wrote: $dst"
  wrote=$((wrote + 1))
}

echo "Scope: $SCOPE; CLI: $CLI"
echo

# === AI instruction templates ===
# Projects share one canonical AGENTS.md across clients. Global instructions
# must live in each client's own configuration directory to be discovered.
if [ "$SCOPE" = "project" ]; then
  write_once "$ASSETS/AGENTS.md" "$TARGET/AGENTS.md"
  if [ "$CLI" != "codex" ]; then
    write_once "$ASSETS/CLAUDE.md" "$TARGET/CLAUDE.md"
  fi
else
  if [ "$CLI" != "codex" ]; then
    write_once "$ASSETS/AGENTS.md" "$CLAUDE_DIR/AGENTS.md"
    write_once "$ASSETS/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
  fi
  if [ "$CLI" != "claude" ]; then
    write_once "$ASSETS/AGENTS.md" "$CODEX_DIR/AGENTS.md"
  fi
fi

# === Claude HUD: statusline + usage fetcher + settings ===
if [ "$CLI" != "codex" ]; then
  STATUSLINE_DST="$CLAUDE_DIR/scripts/statusline.sh"
  USAGE_FETCH_DST="$CLAUDE_DIR/scripts/usage-fetch.sh"
  SETTINGS_DST="$CLAUDE_DIR/settings.json"

  write_once "$CLAUDE_ASSETS/statusline.sh" "$STATUSLINE_DST" executable
  write_once "$CLAUDE_ASSETS/usage-fetch.sh" "$USAGE_FETCH_DST" executable

  # statusLine uses the installed path so it resolves regardless of cwd.
  if [ -e "$SETTINGS_DST" ] || [ -L "$SETTINGS_DST" ]; then
    echo "skip:  $SETTINGS_DST (exists)"
    skipped=$((skipped + 1))
  else
    mkdir -p "$(dirname "$SETTINGS_DST")"
    sed "s|@STATUSLINE_PATH@|$STATUSLINE_DST|g" "$CLAUDE_ASSETS/settings.json" > "$SETTINGS_DST"
    echo "wrote: $SETTINGS_DST"
    wrote=$((wrote + 1))
  fi
fi

# === editor & lint config (project scope only) ===
if [ "$SCOPE" = "project" ]; then
  write_once "$ASSETS/editorconfig"      "$TARGET/.editorconfig"
  write_once "$ASSETS/markdownlint.json" "$TARGET/.markdownlint.json"
fi

# === report ===
echo
echo "Setup complete: $wrote written, $skipped skipped."
