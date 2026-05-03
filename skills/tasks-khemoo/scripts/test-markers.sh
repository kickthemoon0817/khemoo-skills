#!/usr/bin/env bash
# Regression test for tasks-khemoo: the bondable-section markers must be
# byte-identical across SKILL.md, todo-md.sh, and the project-root TODO.md.
# Catches drift from typos, partial renames, or accidental TODO.md edits.

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

if [ $fail -eq 0 ]; then
  echo "PASS: bondable-section markers byte-identical across SKILL.md, todo-md.sh$([ -f "$TODO_MD" ] && echo ", TODO.md")."
fi

exit $fail
