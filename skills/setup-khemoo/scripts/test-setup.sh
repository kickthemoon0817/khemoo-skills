#!/usr/bin/env bash
# Regression test for ./setup.sh. Builds a temp project tree, runs setup,
# asserts the expected files appear (and that idempotent re-run doesn't
# overwrite).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP="$SCRIPT_DIR/setup.sh"

# Neutralize ambient HUD env so every statusline.sh run below is hermetic
# regardless of the caller's environment:
#  - USAGE_FETCH="" disables the background usage-fetch spawn (no network);
#    usage-fetch.sh is exercised directly in its own cases.
#  - HUD_DETAIL="" keeps the optional detail line off unless a case opts in.
export USAGE_FETCH=""
export HUD_DETAIL=""

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
assert_file_exists "t1: AGENTS.md written" "$PROJ/AGENTS.md"
assert_file_exists "t1: CLAUDE.md written" "$PROJ/CLAUDE.md"
assert_file_exists "t1: .claude/settings.json written" "$PROJ/.claude/settings.json"
assert_file_exists "t1: .editorconfig written" "$PROJ/.editorconfig"
assert_file_exists "t1: .markdownlint.json written" "$PROJ/.markdownlint.json"

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

# --- t1b2: usage-fetch.sh is installed alongside statusline.sh, executable ---
assert_file_exists "t1b2: usage-fetch.sh written" "$PROJ/.claude/scripts/usage-fetch.sh"
if [ -x "$PROJ/.claude/scripts/usage-fetch.sh" ]; then
  PASS=$((PASS + 1)); echo "PASS: t1b2: usage-fetch.sh is executable"
else
  FAIL=$((FAIL + 1)); echo "FAIL: t1b2: usage-fetch.sh is not executable"
fi

# --- t1c: statusline.sh produces a non-empty line on a minimal stub payload ---
HUD_OUT=$(echo '{"model":{"display_name":"Sonnet"},"session_id":"abcdef1234","workspace":{"current_dir":"/tmp/demo"}}' | USAGE_CACHE=/nonexistent "$PROJ/.claude/scripts/statusline.sh")
if [ -n "$HUD_OUT" ]; then
  PASS=$((PASS + 1)); echo "PASS: t1c: statusline.sh renders a line ($HUD_OUT)"
else
  FAIL=$((FAIL + 1)); echo "FAIL: t1c: statusline.sh produced empty output"
fi

# --- t1d: ctx token count from transcript usage block ---
TRANSCRIPT="$WORK/transcript.jsonl"
cat > "$TRANSCRIPT" <<'JSONL'
{"role":"user","content":"hi"}
{"role":"assistant","content":"x","usage":{"input_tokens":15500,"cache_creation_input_tokens":0,"cache_read_input_tokens":102000,"output_tokens":340}}
JSONL
# 15500 + 102000 = 117500 tokens used → "118k/200k context" for the default tier.
HUD_OUT=$(printf '{"model":{"display_name":"Sonnet"},"session_id":"abc","workspace":{"current_dir":"/tmp/demo"},"transcript_path":"%s"}' "$TRANSCRIPT" | USAGE_CACHE=/nonexistent "$PROJ/.claude/scripts/statusline.sh")
if echo "$HUD_OUT" | grep -qE '118k/200k context([^[:alnum:]]|$)'; then
  PASS=$((PASS + 1)); echo "PASS: t1d: used/limit context for 200k tier ($HUD_OUT)"
else
  FAIL=$((FAIL + 1)); echo "FAIL: t1d: expected '118k/200k context', got: $HUD_OUT"
fi

# 1M tier: same 117500 tokens used → "118k/1m context".
HUD_OUT=$(printf '{"model":{"display_name":"Claude Opus 4.7 (1M context)"},"session_id":"abc","workspace":{"current_dir":"/tmp/demo"},"transcript_path":"%s"}' "$TRANSCRIPT" | USAGE_CACHE=/nonexistent "$PROJ/.claude/scripts/statusline.sh")
if echo "$HUD_OUT" | grep -qE '118k/1m context([^[:alnum:]]|$)'; then
  PASS=$((PASS + 1)); echo "PASS: t1d2: 1M tier label ($HUD_OUT)"
else
  FAIL=$((FAIL + 1)); echo "FAIL: t1d2: expected '118k/1m context', got: $HUD_OUT"
fi

# --- t1e: usage cache file is read and percentages rendered ---
CACHE="$WORK/usage-cache.json"
cat > "$CACHE" <<'JSON'
{"data":{"fiveHourPercent":42,"fiveHourResetsAt":"2030-01-01T00:00:00.000Z","weeklyPercent":75,"weeklyResetsAt":"2030-01-08T00:00:00.000Z"}}
JSON
HUD_OUT=$(echo '{"model":{"display_name":"Sonnet"},"session_id":"abc","workspace":{"current_dir":"/tmp/demo"}}' | USAGE_CACHE="$CACHE" "$PROJ/.claude/scripts/statusline.sh")
# After update: percentages are bare (no "5h:"/"w:" prefix), with elapsed/window in parens.
if echo "$HUD_OUT" | grep -qE '42%.*\(.*/5h\)' && echo "$HUD_OUT" | grep -qE '75%.*\(.*/7d\)'; then
  PASS=$((PASS + 1)); echo "PASS: t1e: 5h and weekly limits rendered with elapsed/window"
else
  FAIL=$((FAIL + 1)); echo "FAIL: t1e: expected '42% (.../5h)' and '75% (.../7d)', got: $HUD_OUT"
fi

# --- t1e2: color codes embedded around percentage values ---
if echo "$HUD_OUT" | grep -qE $'\033\\[3[123]m'; then
  PASS=$((PASS + 1)); echo "PASS: t1e2: ANSI color codes present in usage section"
else
  FAIL=$((FAIL + 1)); echo "FAIL: t1e2: no ANSI color escapes found in: $HUD_OUT"
fi

# --- t1f: no usage cache → dim "??%" placeholders rendered (not omitted) ---
HUD_OUT=$(echo '{"model":{"display_name":"Sonnet"},"session_id":"abc","workspace":{"current_dir":"/tmp/demo"}}' | USAGE_CACHE=/nonexistent "$PROJ/.claude/scripts/statusline.sh")
if echo "$HUD_OUT" | grep -qE '\?\?%.*5h' && echo "$HUD_OUT" | grep -qE '\?\?%.*7d'; then
  PASS=$((PASS + 1)); echo "PASS: t1f: placeholder usage rendered when cache absent"
else
  FAIL=$((FAIL + 1)); echo "FAIL: t1f: expected '??% ... 5h' and '??% ... 7d' placeholders, got: $HUD_OUT"
fi

# --- t1g: no transcript → gray "???k/? context" placeholder ---
HUD_OUT=$(echo '{"model":{"display_name":"Sonnet"},"session_id":"abc","workspace":{"current_dir":"/tmp/demo"}}' | USAGE_CACHE=/nonexistent "$PROJ/.claude/scripts/statusline.sh")
if echo "$HUD_OUT" | grep -q '???k/? context'; then
  PASS=$((PASS + 1)); echo "PASS: t1g: placeholder context rendered when transcript absent"
else
  FAIL=$((FAIL + 1)); echo "FAIL: t1g: expected '???k/? context', got: $HUD_OUT"
fi

# --- t1j: HUD_DETAIL on → optional second line with the event breakdown ---
DTRANSCRIPT="$WORK/detail.jsonl"
cat > "$DTRANSCRIPT" <<'JSONL'
{"type":"user","message":{"role":"user"}}
{"type":"assistant","message":{"role":"assistant"}}
{"type":"tool_use"}
{"type":"hook_success"}
{"type":"attachment"}
JSONL
HUD_OUT=$(printf '{"model":{"display_name":"Sonnet"},"session_id":"abc","workspace":{"current_dir":"/tmp/demo"},"transcript_path":"%s"}' "$DTRANSCRIPT" | USAGE_CACHE=/nonexistent HUD_DETAIL=1 "$PROJ/.claude/scripts/statusline.sh")
if printf '%s' "$HUD_OUT" | grep -q '2 msgs' && printf '%s' "$HUD_OUT" | grep -q '1 tools'; then
  PASS=$((PASS + 1)); echo "PASS: t1j: HUD_DETAIL renders the event-breakdown line"
else
  FAIL=$((FAIL + 1)); echo "FAIL: t1j: expected '2 msgs' + '1 tools' detail line, got: $HUD_OUT"
fi

# --- t1k: HUD_DETAIL unset → no detail line ---
HUD_OUT=$(printf '{"model":{"display_name":"Sonnet"},"session_id":"abc","workspace":{"current_dir":"/tmp/demo"},"transcript_path":"%s"}' "$DTRANSCRIPT" | USAGE_CACHE=/nonexistent "$PROJ/.claude/scripts/statusline.sh")
if printf '%s' "$HUD_OUT" | grep -q 'msgs'; then
  FAIL=$((FAIL + 1)); echo "FAIL: t1k: detail line should be absent without HUD_DETAIL, got: $HUD_OUT"
else
  PASS=$((PASS + 1)); echo "PASS: t1k: no detail line when HUD_DETAIL unset"
fi

# --- t1h: usage-fetch.sh with no credentials exits 0 and writes no cache ---
FETCH="$PROJ/.claude/scripts/usage-fetch.sh"
FCACHE="$WORK/fetch-cache.json"
USAGE_CACHE="$FCACHE" USAGE_CREDENTIALS_FILE=/nonexistent "$FETCH"
EXIT=$?
if [ "$EXIT" -eq 0 ] && [ ! -f "$FCACHE" ]; then
  PASS=$((PASS + 1)); echo "PASS: t1h: usage-fetch.sh exits clean and writes nothing without credentials"
else
  FAIL=$((FAIL + 1)); echo "FAIL: t1h: expected exit 0 + no cache, got exit $EXIT"
fi

# --- t1i: usage-fetch.sh skips when another fetch holds the lock ---
mkdir "${FCACHE}.lock"
USAGE_CACHE="$FCACHE" USAGE_CREDENTIALS_FILE=/nonexistent "$FETCH"
EXIT=$?
rmdir "${FCACHE}.lock" 2>/dev/null
if [ "$EXIT" -eq 0 ] && [ ! -f "$FCACHE" ]; then
  PASS=$((PASS + 1)); echo "PASS: t1i: usage-fetch.sh defers to a held lock"
else
  FAIL=$((FAIL + 1)); echo "FAIL: t1i: expected exit 0 + no cache with lock held, got exit $EXIT"
fi

# --- t2: idempotent re-run does not overwrite ---
echo "custom-content" > "$PROJ/.editorconfig"
ROOT="$PROJ" "$SETUP" >/dev/null 2>&1
got=$(cat "$PROJ/.editorconfig")
assert_eq "t2: existing file is not overwritten" "custom-content" "$got"

# --- t3: --user setup writes inside fake $HOME/.claude ---
USER_HOME="$WORK/home"
mkdir -p "$USER_HOME"
HOME="$USER_HOME" "$SETUP" --user >/dev/null 2>&1
EXIT=$?
assert_eq "t3: --user setup exits 0" 0 "$EXIT"
assert_file_exists "t3: ~/.claude/AGENTS.md written" "$USER_HOME/.claude/AGENTS.md"
assert_file_exists "t3: ~/.claude/CLAUDE.md written" "$USER_HOME/.claude/CLAUDE.md"
assert_file_exists "t3: ~/.claude/settings.json written" "$USER_HOME/.claude/settings.json"

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
