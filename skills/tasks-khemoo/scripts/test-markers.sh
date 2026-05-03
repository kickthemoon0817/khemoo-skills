#!/usr/bin/env bash
# Regression test for tasks-khemoo bondable-section integrity:
#   1. Markers (`<!-- tasks-khemoo:start/end -->`) byte-identical across
#      SKILL.md, todo-md.sh, and the project-root TODO.md.
#   2. Auto-managed paragraph (the italic `_Auto-managed by the ..._` line)
#      byte-identical between todo-md.sh's section_template and TODO.md.
# Catches drift from typos, partial renames, or accidental edits.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$SKILL_DIR/../.." && pwd)"

EXPECTED_START="<!-- tasks-khemoo:start -->"
EXPECTED_END="<!-- tasks-khemoo:end -->"

SKILL_MD="$SKILL_DIR/SKILL.md"
HELPER="$SCRIPT_DIR/todo-md.sh"
TODO_MD="$REPO_ROOT/TODO.md"

fail=0

check_marker() {
  local label="$1" file="$2" marker="$3"
  if [ ! -f "$file" ]; then
    echo "FAIL: $label not found at $file" >&2
    fail=$((fail + 1))
    return
  fi
  if ! grep -qF "$marker" "$file"; then
    echo "FAIL: $label is missing the marker: $marker" >&2
    fail=$((fail + 1))
  fi
}

check_marker "SKILL.md (start)" "$SKILL_MD" "$EXPECTED_START"
check_marker "SKILL.md (end)"   "$SKILL_MD" "$EXPECTED_END"
check_marker "todo-md.sh (start)" "$HELPER" "$EXPECTED_START"
check_marker "todo-md.sh (end)"   "$HELPER" "$EXPECTED_END"

# TODO.md may not exist yet in a fresh project — the helper creates it on first
# use. Only test it if present.
if [ -f "$TODO_MD" ]; then
  check_marker "TODO.md (start)" "$TODO_MD" "$EXPECTED_START"
  check_marker "TODO.md (end)"   "$TODO_MD" "$EXPECTED_END"
else
  echo "INFO: $TODO_MD not present — skipping TODO.md marker check (will be created on first add)."
fi

EXPECTED_PARAGRAPH="_Auto-managed by the \`tasks-khemoo\` skill. Hand-curated content lives above this section; everything between the markers is touched by the skill._"

# todo-md.sh stores this paragraph in a heredoc with escaped backticks.
# Use grep -F so backticks are matched literally, not as regex.
if ! grep -qF "$EXPECTED_PARAGRAPH" "$HELPER"; then
  echo "FAIL: todo-md.sh section_template paragraph differs from expected." >&2
  fail=$((fail + 1))
fi
if [ -f "$TODO_MD" ] && ! grep -qF "$EXPECTED_PARAGRAPH" "$TODO_MD"; then
  echo "FAIL: TODO.md bondable-section paragraph differs from expected." >&2
  fail=$((fail + 1))
fi

if [ $fail -eq 0 ]; then
  echo "PASS: bondable-section markers + auto-managed paragraph byte-identical across SKILL.md, todo-md.sh$([ -f "$TODO_MD" ] && echo ", TODO.md")."
fi

exit $fail
