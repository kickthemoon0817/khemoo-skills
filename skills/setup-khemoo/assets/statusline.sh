#!/usr/bin/env bash
# setup-khemoo HUD — one-line status for Claude Code's statusLine.
# Reads the status JSON payload from stdin, prints a single line to stdout.
# Dependency-free: uses bash + grep + sed only.
#
# Renders: <model> · <project> · <session-short> · <N turns>
# Missing fields are dropped gracefully.

set -uo pipefail

input=$(cat)

# Pull a top-level (or nested) string value from the JSON payload.
# Fragile but works for the stable Claude Code status fields.
pull() {
  printf '%s' "$input" \
    | grep -oE "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" \
    | head -1 \
    | sed -E 's/.*:[[:space:]]*"([^"]*)"/\1/'
}

model=$(pull display_name)
[ -z "$model" ] && model=$(pull id)

session_full=$(pull session_id)
session=${session_full:0:8}

cwd=$(pull current_dir)
[ -z "$cwd" ] && cwd=$(pull cwd)

transcript=$(pull transcript_path)

project=$(basename "${cwd:-?}")
parts="${model:-?} · ${project} · ${session:-?}"

if [ -n "$transcript" ] && [ -f "$transcript" ]; then
  turns=$(wc -l < "$transcript" 2>/dev/null | tr -d ' ')
  if [ -n "$turns" ] && [ "$turns" -gt 0 ] 2>/dev/null; then
    parts="$parts · ${turns} turns"
  fi
fi

printf '%s' "$parts"
