#!/usr/bin/env bash
# shellcheck disable=SC2016
# (SC2016: awk programs are single-quoted intentionally; shell variables are
#  passed in via `awk -v`, not via $-expansion inside the quotes.)
# tasks-khemoo TODO.md helper.
# Manages the bondable section between
#   <!-- tasks-khemoo:start -->
# and
#   <!-- tasks-khemoo:end -->
# in TODO.md (default) or the file in $TODO_FILE.
#
# Idempotent: `done` skips already-done lines; `remove` is a no-op on missing
# lines; `add` does not deduplicate (use the skill's duplicate-check before
# calling). Everything outside the markers is preserved untouched.
#
# Usage:
#   todo-md.sh add "description"
#   todo-md.sh done "description"
#   todo-md.sh remove "description"
#   todo-md.sh cleanup
#   todo-md.sh list

set -euo pipefail

TODO_FILE="${TODO_FILE:-TODO.md}"
TODAY="${TODAY:-$(date +%Y-%m-%d)}"
START_MARKER="<!-- tasks-khemoo:start -->"
END_MARKER="<!-- tasks-khemoo:end -->"

section_template() {
  cat <<EOF
$START_MARKER
## Quick tasks

_Auto-managed by the \`tasks-khemoo\` skill. Hand-curated content lives above this section; everything between the markers is touched by the skill._

$END_MARKER
EOF
}

ensure_section() {
  if [ ! -f "$TODO_FILE" ]; then
    section_template > "$TODO_FILE"
    return
  fi
  local has_start has_end
  grep -qF "$START_MARKER" "$TODO_FILE" && has_start=1 || has_start=0
  grep -qF "$END_MARKER"   "$TODO_FILE" && has_end=1   || has_end=0
  if [ "$has_start" = 0 ] && [ "$has_end" = 0 ]; then
    # Capture trailing-newline status BEFORE writing to avoid same-file read/write in one pipeline.
    local trailing=""
    if [ -s "$TODO_FILE" ] && tail -c1 "$TODO_FILE" | grep -q .; then
      trailing="missing"
    fi
    {
      [ "$trailing" = "missing" ] && echo
      echo
      section_template
    } >> "$TODO_FILE"
    return
  fi
  if [ "$has_start" != "$has_end" ]; then
    echo "tasks-khemoo: $TODO_FILE has a half-broken bondable section (start=$has_start, end=$has_end)." >&2
    echo "Restore the matching marker manually before continuing." >&2
    exit 2
  fi
}

awk_in_section() {
  awk -v start="$START_MARKER" -v end="$END_MARKER" "$@"
}

cmd_add() {
  local desc="${1:?usage: add \"description\"}"
  ensure_section
  local line="- [ ] $desc (added $TODAY)"
  awk_in_section -v new_line="$line" '
    $0 ~ end { print new_line }
    { print }
  ' "$TODO_FILE" > "$TODO_FILE.tmp"
  mv "$TODO_FILE.tmp" "$TODO_FILE"
}

cmd_done() {
  local desc="${1:?usage: done \"description\"}"
  ensure_section
  awk_in_section -v desc="$desc" -v today="$TODAY" '
    $0 ~ start { in_sec=1 }
    $0 ~ end   { in_sec=0 }
    {
      if (in_sec && index($0, "- [ ] " desc " (added") > 0 && index($0, ", done ") == 0) {
        sub(/^- \[ \]/, "- [x]", $0)
        sub(/\)$/, ", done " today ")", $0)
      }
      print
    }
  ' "$TODO_FILE" > "$TODO_FILE.tmp"
  mv "$TODO_FILE.tmp" "$TODO_FILE"
}

cmd_remove() {
  local desc="${1:?usage: remove \"description\"}"
  ensure_section
  awk_in_section -v desc="$desc" '
    $0 ~ start { in_sec=1; print; next }
    $0 ~ end   { in_sec=0; print; next }
    in_sec && index($0, "] " desc " (added") > 0 { next }
    { print }
  ' "$TODO_FILE" > "$TODO_FILE.tmp"
  mv "$TODO_FILE.tmp" "$TODO_FILE"
}

cmd_cleanup() {
  ensure_section
  awk_in_section '
    $0 ~ start { in_sec=1; print; next }
    $0 ~ end   { in_sec=0; print; next }
    in_sec && /^- \[x\]/ { next }
    { print }
  ' "$TODO_FILE" > "$TODO_FILE.tmp"
  mv "$TODO_FILE.tmp" "$TODO_FILE"
}

cmd_list() {
  ensure_section
  awk_in_section '
    $0 ~ start { in_sec=1; next }
    $0 ~ end   { in_sec=0; next }
    in_sec && /^- \[/ { print }
  ' "$TODO_FILE"
}

cmd="${1:-list}"
shift || true

case "$cmd" in
  add)     cmd_add     "$@" ;;
  done)    cmd_done    "$@" ;;
  remove)  cmd_remove  "$@" ;;
  cleanup) cmd_cleanup ;;
  list)    cmd_list ;;
  -h|--help)
    sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'
    ;;
  *)
    echo "Unknown command: $cmd" >&2
    echo "Run with --help for usage." >&2
    exit 1
    ;;
esac
