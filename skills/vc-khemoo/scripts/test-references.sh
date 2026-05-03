#!/usr/bin/env bash
# Regression test for vc-khemoo: every references/...md mentioned in SKILL.md
# must exist on disk, and every reference file on disk must be mentioned in
# SKILL.md. Catches drift introduced by renames, additions, or deletions.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL_MD="$SKILL_DIR/SKILL.md"
REF_DIR="$SKILL_DIR/references"

if [ ! -f "$SKILL_MD" ]; then
  echo "FAIL: $SKILL_MD not found" >&2
  exit 1
fi
if [ ! -d "$REF_DIR" ]; then
  echo "FAIL: $REF_DIR not found" >&2
  exit 1
fi

referenced=$(grep -oE 'references/[a-zA-Z0-9_/.-]+\.md' "$SKILL_MD" | sort -u)
actual=$(cd "$SKILL_DIR" && find references -type f -name "*.md" | sort)

missing=$(comm -23 <(echo "$referenced") <(echo "$actual"))
orphan=$(comm -13 <(echo "$referenced") <(echo "$actual"))

fail=0

if [ -n "$missing" ]; then
  echo "FAIL: SKILL.md mentions reference files that do not exist on disk:" >&2
  while IFS= read -r line; do echo "  - $line" >&2; done <<< "$missing"
  fail=$((fail + 1))
fi

if [ -n "$orphan" ]; then
  echo "FAIL: reference files exist on disk but are never mentioned in SKILL.md:" >&2
  while IFS= read -r line; do echo "  - $line" >&2; done <<< "$orphan"
  fail=$((fail + 1))
fi

if [ $fail -eq 0 ]; then
  count=$(echo "$referenced" | wc -l | tr -d ' ')
  echo "PASS: all $count vc-khemoo references resolve and every reference is mentioned."
fi

exit $fail
