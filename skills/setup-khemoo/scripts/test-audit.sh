#!/usr/bin/env bash
# Regression test for ./audit.sh.
# Builds a temp project tree, drops in known-bad files, runs the audit, and
# asserts the expected pass/fail outcome.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUDIT="$SCRIPT_DIR/audit.sh"

PASS=0
FAIL=0

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# Each scenario gets a fresh subdir. ROOT env var tells audit.sh where to scan.
make_clean_repo() {
  local dir="$1"
  rm -rf "$dir"
  mkdir -p "$dir"
  cat > "$dir/README.md" <<'EOF'
# Project

A clean README. No history parens.
EOF
  cat > "$dir/lib.py" <<'EOF'
def add(a, b):
    # Why: tax calc rounds to 2 decimals upstream so we add raw here.
    return a + b
EOF
}

run_audit() {
  ROOT="$1" "$AUDIT" >/dev/null 2>&1
  echo $?
}

assert_eq() {
  local label="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    PASS=$((PASS + 1))
    echo "PASS: $label"
  else
    FAIL=$((FAIL + 1))
    echo "FAIL: $label (expected $expected, got $actual)"
  fi
}

# t1: clean repo passes
make_clean_repo "$WORK/t1"
assert_eq "t1: clean repo → exit 0" 0 "$(run_audit "$WORK/t1")"

# t2: history paren in markdown fails
make_clean_repo "$WORK/t2"
cat > "$WORK/t2/CONTRIBUTING.md" <<'EOF'
Run `git switch -c <branch>` (preferred over `git checkout -b`).
EOF
assert_eq "t2: history paren in .md → exit 1" 1 "$(run_audit "$WORK/t2")"

# t3: WHAT-comment in code fails
make_clean_repo "$WORK/t3"
cat > "$WORK/t3/util.ts" <<'EOF'
// used by login flow
export function hash(s: string) { return s; }
EOF
assert_eq "t3: WHAT-comment in code → exit 1" 1 "$(run_audit "$WORK/t3")"

# t4: removed marker in code fails
make_clean_repo "$WORK/t4"
cat > "$WORK/t4/old.py" <<'EOF'
# removed: legacy jwt verifier (prod 2024)
def hash(s):
    return s
EOF
assert_eq "t4: removed marker in code → exit 1" 1 "$(run_audit "$WORK/t4")"

# t5: legitimate prose with the trigger words but not the parenthetical pattern passes
make_clean_repo "$WORK/t5"
cat > "$WORK/t5/notes.md" <<'EOF'
# Notes

The auth flow was previously done via JWT — see issue #42 for context.
EOF
assert_eq "t5: trigger words outside the parenthetical pattern → exit 0" 0 "$(run_audit "$WORK/t5")"

# t6: WHAT-comment-shaped phrase in markdown is not flagged (code rule only)
make_clean_repo "$WORK/t6"
cat > "$WORK/t6/notes.md" <<'EOF'
# Notes

The auth helper is used by the login flow.
EOF
assert_eq "t6: WHAT-comment phrase in .md → exit 0" 0 "$(run_audit "$WORK/t6")"

# t7: explicit --project flag is accepted and behaves like default
make_clean_repo "$WORK/t7"
ROOT="$WORK/t7" "$AUDIT" --project >/dev/null 2>&1
assert_eq "t7: --project flag → exit 0 on clean repo" 0 "$?"

# t8: --user flag finds violations in user-authored content under $HOME/.claude
USER_HOME=$(mktemp -d)
mkdir -p "$USER_HOME/.claude"
cat > "$USER_HOME/.claude/CLAUDE.md" <<'EOF'
Use `git switch -c <branch>` (preferred over `git checkout -b`).
EOF
HOME="$USER_HOME" "$AUDIT" --user >/dev/null 2>&1
assert_eq "t8: --user flag flags violation in ~/.claude/" 1 "$?"
rm -rf "$USER_HOME"

# t9: --user flag with missing ~/.claude exits 2
USER_HOME=$(mktemp -d)
HOME="$USER_HOME" "$AUDIT" --user >/dev/null 2>&1
assert_eq "t9: --user with no ~/.claude → exit 2" 2 "$?"
rm -rf "$USER_HOME"

# t10: unknown argument exits 2
"$AUDIT" --bogus >/dev/null 2>&1
assert_eq "t10: unknown flag → exit 2" 2 "$?"

echo
echo "Result: $PASS passed, $FAIL failed."
[ $FAIL -eq 0 ]
