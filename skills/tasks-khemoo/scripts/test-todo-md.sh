#!/usr/bin/env bash
# Regression tests for ./todo-md.sh.
# Runs in a temp dir. Exits 0 on success, prints a diff and exits 1 on failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELPER="$SCRIPT_DIR/todo-md.sh"
TODAY=2026-05-04

PASS=0
FAIL=0

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
cd "$WORK"

assert_file_eq() {
  local label="$1" expected="$2"
  local actual; actual=$(cat TODO.md)
  if [ "$actual" = "$expected" ]; then
    PASS=$((PASS + 1))
    echo "PASS: $label"
  else
    FAIL=$((FAIL + 1))
    echo "FAIL: $label"
    diff <(echo "$expected") <(echo "$actual") | sed 's/^/  /'
  fi
}

assert_stdout_eq() {
  local label="$1" expected="$2" actual="$3"
  if [ "$actual" = "$expected" ]; then
    PASS=$((PASS + 1))
    echo "PASS: $label"
  else
    FAIL=$((FAIL + 1))
    echo "FAIL: $label"
    diff <(echo "$expected") <(echo "$actual") | sed 's/^/  /'
  fi
}

reset_workdir() {
  rm -f TODO.md
}

# --- t1: add to non-existent file creates section + appends bullet ---
reset_workdir
TODAY=$TODAY "$HELPER" add "Refactor the auth module"
assert_file_eq "t1: add creates file with section" "<!-- tasks-khemoo:start -->
## Quick tasks

_Auto-managed by the \`tasks-khemoo\` skill. Hand-curated content lives above this section; everything between the markers is touched by the skill._

- [ ] Refactor the auth module (added 2026-05-04)
<!-- tasks-khemoo:end -->"

# --- t2: second add appends inside markers ---
TODAY=$TODAY "$HELPER" add "Bump dep X to 2.0"
assert_file_eq "t2: second add appends inside markers" "<!-- tasks-khemoo:start -->
## Quick tasks

_Auto-managed by the \`tasks-khemoo\` skill. Hand-curated content lives above this section; everything between the markers is touched by the skill._

- [ ] Refactor the auth module (added 2026-05-04)
- [ ] Bump dep X to 2.0 (added 2026-05-04)
<!-- tasks-khemoo:end -->"

# --- t3: done flips and stamps ---
TODAY=$TODAY "$HELPER" done "Refactor the auth module"
assert_file_eq "t3: done flips [ ] to [x] and stamps" "<!-- tasks-khemoo:start -->
## Quick tasks

_Auto-managed by the \`tasks-khemoo\` skill. Hand-curated content lives above this section; everything between the markers is touched by the skill._

- [x] Refactor the auth module (added 2026-05-04, done 2026-05-04)
- [ ] Bump dep X to 2.0 (added 2026-05-04)
<!-- tasks-khemoo:end -->"

# --- t4: done twice is a no-op (idempotence) ---
EXPECTED_AFTER_DONE=$(cat TODO.md)
TODAY=$TODAY "$HELPER" done "Refactor the auth module"
assert_file_eq "t4: done twice is no-op" "$EXPECTED_AFTER_DONE"

# --- t5: cleanup removes [x] lines ---
TODAY=$TODAY "$HELPER" cleanup
assert_file_eq "t5: cleanup removes [x] lines" "<!-- tasks-khemoo:start -->
## Quick tasks

_Auto-managed by the \`tasks-khemoo\` skill. Hand-curated content lives above this section; everything between the markers is touched by the skill._

- [ ] Bump dep X to 2.0 (added 2026-05-04)
<!-- tasks-khemoo:end -->"

# --- t6: list outputs only the bullets ---
LIST_OUT=$("$HELPER" list)
assert_stdout_eq "t6: list outputs only bullets" "- [ ] Bump dep X to 2.0 (added 2026-05-04)" "$LIST_OUT"

# --- t7: remove drops the matching line ---
TODAY=$TODAY "$HELPER" remove "Bump dep X to 2.0"
assert_file_eq "t7: remove drops the line" "<!-- tasks-khemoo:start -->
## Quick tasks

_Auto-managed by the \`tasks-khemoo\` skill. Hand-curated content lives above this section; everything between the markers is touched by the skill._

<!-- tasks-khemoo:end -->"

# --- t8: ensure_section preserves hand-curated content above ---
reset_workdir
cat > TODO.md <<'EOF'
# Project TODO

## Roadmap

- Q3: ship feature A
- Q4: ship feature B
EOF
TODAY=$TODAY "$HELPER" add "Patch the parser"
assert_file_eq "t8: section appended below hand-curated content" "# Project TODO

## Roadmap

- Q3: ship feature A
- Q4: ship feature B

<!-- tasks-khemoo:start -->
## Quick tasks

_Auto-managed by the \`tasks-khemoo\` skill. Hand-curated content lives above this section; everything between the markers is touched by the skill._

- [ ] Patch the parser (added 2026-05-04)
<!-- tasks-khemoo:end -->"

# --- t9: cleanup on empty section is a no-op ---
reset_workdir
TODAY=$TODAY "$HELPER" cleanup
EXPECTED_EMPTY="<!-- tasks-khemoo:start -->
## Quick tasks

_Auto-managed by the \`tasks-khemoo\` skill. Hand-curated content lives above this section; everything between the markers is touched by the skill._

<!-- tasks-khemoo:end -->"
assert_file_eq "t9: cleanup on empty section is no-op" "$EXPECTED_EMPTY"

echo
echo "Result: $PASS passed, $FAIL failed."
[ $FAIL -eq 0 ]
