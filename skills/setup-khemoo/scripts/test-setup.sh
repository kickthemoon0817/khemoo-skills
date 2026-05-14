#!/usr/bin/env bash
# Regression test for ./setup.sh. Builds a temp project tree, runs setup,
# asserts the expected files appear (and that idempotent re-run doesn't
# overwrite).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP="$SCRIPT_DIR/setup.sh"

PASS=0
FAIL=0

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

assert_file_exists() {
  local label="$1" path="$2"
  if [ -f "$path" ]; then
    PASS=$((PASS + 1))
    echo "PASS: $label"
  else
    FAIL=$((FAIL + 1))
    echo "FAIL: $label (expected $path to exist)"
  fi
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

# --- t1: project setup on an empty dir writes all expected files ---
PROJ="$WORK/proj"
mkdir -p "$PROJ"
ROOT="$PROJ" "$SETUP" >/dev/null 2>&1
EXIT=$?
assert_eq "t1: project setup exits 0" 0 "$EXIT"
assert_file_exists "t1: CLAUDE.md written" "$PROJ/CLAUDE.md"
assert_file_exists "t1: .claude/settings.json written" "$PROJ/.claude/settings.json"
assert_file_exists "t1: .editorconfig written" "$PROJ/.editorconfig"
assert_file_exists "t1: .markdownlint.json written" "$PROJ/.markdownlint.json"
assert_file_exists "t1: code-reviewer agent written" "$PROJ/.claude/agents/code-reviewer.md"
assert_file_exists "t1: writer agent written" "$PROJ/.claude/agents/writer.md"

# --- t1b: HUD statusline.sh is written, executable, and absolute path is baked into settings.json ---
assert_file_exists "t1b: statusline.sh written" "$PROJ/.claude/scripts/statusline.sh"
if [ -x "$PROJ/.claude/scripts/statusline.sh" ]; then
  PASS=$((PASS + 1)); echo "PASS: t1b: statusline.sh is executable"
else
  FAIL=$((FAIL + 1)); echo "FAIL: t1b: statusline.sh is not executable"
fi
if grep -q "$PROJ/.claude/scripts/statusline.sh" "$PROJ/.claude/settings.json"; then
  PASS=$((PASS + 1)); echo "PASS: t1b: settings.json statusLine points at the installed script"
else
  FAIL=$((FAIL + 1)); echo "FAIL: t1b: settings.json statusLine path was not substituted"
fi

# --- t1c: statusline.sh produces a non-empty line on a minimal stub payload ---
HUD_OUT=$(echo '{"model":{"display_name":"Sonnet"},"session_id":"abcdef1234","workspace":{"current_dir":"/tmp/demo"}}' | "$PROJ/.claude/scripts/statusline.sh")
if [ -n "$HUD_OUT" ]; then
  PASS=$((PASS + 1)); echo "PASS: t1c: statusline.sh renders a line ($HUD_OUT)"
else
  FAIL=$((FAIL + 1)); echo "FAIL: t1c: statusline.sh produced empty output"
fi

# --- t2: idempotent re-run does not overwrite ---
echo "custom-content" > "$PROJ/CLAUDE.md"
ROOT="$PROJ" "$SETUP" >/dev/null 2>&1
got=$(cat "$PROJ/CLAUDE.md")
assert_eq "t2: existing CLAUDE.md is not overwritten" "custom-content" "$got"

# --- t3: --user setup writes inside fake $HOME/.claude ---
USER_HOME="$WORK/home"
mkdir -p "$USER_HOME"
HOME="$USER_HOME" "$SETUP" --user >/dev/null 2>&1
EXIT=$?
assert_eq "t3: --user setup exits 0" 0 "$EXIT"
assert_file_exists "t3: ~/.claude/CLAUDE.md written" "$USER_HOME/.claude/CLAUDE.md"
assert_file_exists "t3: ~/.claude/settings.json written" "$USER_HOME/.claude/settings.json"
assert_file_exists "t3: ~/.claude/agents/code-reviewer.md written" "$USER_HOME/.claude/agents/code-reviewer.md"

# --- t4: --user scope does NOT write project-only files ---
if [ -f "$USER_HOME/.claude/.editorconfig" ]; then
  FAIL=$((FAIL + 1)); echo "FAIL: t4: --user scope should not write .editorconfig"
else
  PASS=$((PASS + 1)); echo "PASS: t4: --user scope does not write .editorconfig"
fi

# --- t5: unknown flag exits 2 ---
"$SETUP" --bogus >/dev/null 2>&1
assert_eq "t5: unknown flag → exit 2" 2 "$?"

echo
echo "Result: $PASS passed, $FAIL failed."
[ $FAIL -eq 0 ]
