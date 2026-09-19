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

assert_absent() {
  local label="$1" path="$2"
  if [ ! -e "$path" ] && [ ! -L "$path" ]; then
    PASS=$((PASS + 1))
    echo "PASS: $label"
  else
    FAIL=$((FAIL + 1))
    echo "FAIL: $label (expected $path to be absent)"
  fi
}

cache_mtime() {
  # GNU stat first — BSD stat fails -c with clean stdout.
  stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null
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

# --- t1f2: empty cache file (a backoff marker) → placeholders still render ---
ECACHE="$WORK/empty-cache.json"
: > "$ECACHE"
HUD_OUT=$(echo '{"model":{"display_name":"Sonnet"},"session_id":"abc","workspace":{"current_dir":"/tmp/demo"}}' | USAGE_CACHE="$ECACHE" "$PROJ/.claude/scripts/statusline.sh")
if echo "$HUD_OUT" | grep -qE '\?\?%.*5h' && echo "$HUD_OUT" | grep -qE '\?\?%.*7d'; then
  PASS=$((PASS + 1)); echo "PASS: t1f2: placeholders rendered from an empty cache file"
else
  FAIL=$((FAIL + 1)); echo "FAIL: t1f2: expected placeholders from an empty cache file, got: $HUD_OUT"
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

# --- t1h: no credentials → exits 0 and creates the empty backoff marker ---
FETCH="$PROJ/.claude/scripts/usage-fetch.sh"
FCACHE="$WORK/fetch-cache.json"
USAGE_CACHE="$FCACHE" USAGE_CREDENTIALS_FILE=/nonexistent "$FETCH"
EXIT=$?
if [ "$EXIT" -eq 0 ] && [ -f "$FCACHE" ] && [ ! -s "$FCACHE" ]; then
  PASS=$((PASS + 1)); echo "PASS: t1h: missing credentials back off via an empty cache marker"
else
  FAIL=$((FAIL + 1)); echo "FAIL: t1h: expected exit 0 + empty cache marker, got exit $EXIT"
fi

# --- t1i: usage-fetch.sh skips when another fetch holds the lock ---
# No backoff touch here: the in-flight fetch owns the cache update.
rm -f "$FCACHE"
mkdir "${FCACHE}.lock"
USAGE_CACHE="$FCACHE" USAGE_CREDENTIALS_FILE=/nonexistent "$FETCH"
EXIT=$?
rmdir "${FCACHE}.lock" 2>/dev/null
if [ "$EXIT" -eq 0 ] && [ ! -f "$FCACHE" ]; then
  PASS=$((PASS + 1)); echo "PASS: t1i: usage-fetch.sh defers to a held lock"
else
  FAIL=$((FAIL + 1)); echo "FAIL: t1i: expected exit 0 + no cache with lock held, got exit $EXIT"
fi

# --- t1l: failed API fetch advances the cache mtime (retry backoff) ---
# A curl stub forces the usage call to fail; valid-shaped unexpired creds get
# the script past the credential stage. The advanced mtime is the backoff
# signal that stops statusline.sh from spawning the fetcher every render.
STUB="$WORK/stub-bin"
mkdir -p "$STUB"
printf '#!/bin/sh\nexit 22\n' > "$STUB/curl"
chmod +x "$STUB/curl"
FCREDS="$WORK/fetch-creds.json"
printf '{"accessToken":"stub","refreshToken":"stub","expiresAt":9999999999999}' > "$FCREDS"
touch -t 202001010000 "$FCACHE"
before=$(cache_mtime "$FCACHE")
PATH="$STUB:$PATH" USAGE_CACHE="$FCACHE" USAGE_CREDENTIALS_FILE="$FCREDS" "$FETCH"
EXIT=$?
after=$(cache_mtime "$FCACHE")
if [ "$EXIT" -eq 0 ] && [ "$after" -gt "$before" ]; then
  PASS=$((PASS + 1)); echo "PASS: t1l: failed fetch advances cache mtime for backoff"
else
  FAIL=$((FAIL + 1)); echo "FAIL: t1l: expected exit 0 + advanced mtime, got exit $EXIT (before=$before, after=$after)"
fi

# --- t1l2: failed token refresh also backs off ---
# Reuses t1l's failing curl stub.
printf '{"accessToken":"stub","refreshToken":"stub","expiresAt":1}' > "$FCREDS"
touch -t 202001010000 "$FCACHE"
before=$(cache_mtime "$FCACHE")
PATH="$STUB:$PATH" USAGE_CACHE="$FCACHE" USAGE_CREDENTIALS_FILE="$FCREDS" "$FETCH"
EXIT=$?
after=$(cache_mtime "$FCACHE")
if [ "$EXIT" -eq 0 ] && [ "$after" -gt "$before" ]; then
  PASS=$((PASS + 1)); echo "PASS: t1l2: failed token refresh advances cache mtime"
else
  FAIL=$((FAIL + 1)); echo "FAIL: t1l2: expected exit 0 + advanced mtime, got exit $EXIT (before=$before, after=$after)"
fi

# --- t1l3: usage response that parses to neither window also backs off ---
cat > "$STUB/curl" <<'EOF'
#!/bin/sh
echo '{"unexpected":true}'
EOF
printf '{"accessToken":"stub","refreshToken":"stub","expiresAt":9999999999999}' > "$FCREDS"
touch -t 202001010000 "$FCACHE"
before=$(cache_mtime "$FCACHE")
PATH="$STUB:$PATH" USAGE_CACHE="$FCACHE" USAGE_CREDENTIALS_FILE="$FCREDS" "$FETCH"
EXIT=$?
after=$(cache_mtime "$FCACHE")
if [ "$EXIT" -eq 0 ] && [ "$after" -gt "$before" ]; then
  PASS=$((PASS + 1)); echo "PASS: t1l3: unparseable usage response advances cache mtime"
else
  FAIL=$((FAIL + 1)); echo "FAIL: t1l3: expected exit 0 + advanced mtime, got exit $EXIT (before=$before, after=$after)"
fi

# --- t1l4: Retry-After pushes the next attempt into the future ---
# Reuses t1l3's unexpired credentials file.
cat > "$STUB/curl" <<'EOF'
#!/bin/sh
while [ $# -gt 0 ]; do
  if [ "$1" = "-D" ]; then printf 'HTTP/2 429\r\nretry-after: 300\r\n\r\n' > "$2"; shift; fi
  shift
done
exit 22
EOF
touch -t 202001010000 "$FCACHE"
NOW=$(date +%s)
PATH="$STUB:$PATH" USAGE_CACHE="$FCACHE" USAGE_CREDENTIALS_FILE="$FCREDS" "$FETCH"
EXIT=$?
after=$(cache_mtime "$FCACHE")
hdrs_left=0
for f in "$FCACHE".hdrs.*; do [ -e "$f" ] && hdrs_left=$((hdrs_left + 1)); done
if [ "$EXIT" -eq 0 ] && [ "$after" -gt "$((NOW + 100))" ] && [ "$hdrs_left" -eq 0 ]; then
  PASS=$((PASS + 1)); echo "PASS: t1l4: Retry-After sets a future cache mtime, no header dump left"
else
  FAIL=$((FAIL + 1)); echo "FAIL: t1l4: expected future mtime + no hdrs file, got exit $EXIT (now=$NOW, after=$after, hdrs=$hdrs_left)"
fi

# --- t1l5: an oversized Retry-After clamps to the 1h cap ---
cat > "$STUB/curl" <<'EOF'
#!/bin/sh
while [ $# -gt 0 ]; do
  if [ "$1" = "-D" ]; then printf 'HTTP/2 429\r\nretry-after: 999999\r\n\r\n' > "$2"; shift; fi
  shift
done
exit 22
EOF
printf '{"accessToken":"stub","refreshToken":"stub","expiresAt":9999999999999}' > "$FCREDS"
touch -t 202001010000 "$FCACHE"
NOW=$(date +%s)
PATH="$STUB:$PATH" USAGE_CACHE="$FCACHE" USAGE_CREDENTIALS_FILE="$FCREDS" "$FETCH"
EXIT=$?
after=$(cache_mtime "$FCACHE")
if [ "$EXIT" -eq 0 ] && [ "$after" -ge "$((NOW + 3400))" ] && [ "$after" -le "$((NOW + 3700))" ]; then
  PASS=$((PASS + 1)); echo "PASS: t1l5: oversized Retry-After clamps to one hour"
else
  FAIL=$((FAIL + 1)); echo "FAIL: t1l5: expected mtime ~now+3600, got exit $EXIT (now=$NOW, after=$after)"
fi

# --- t1l6: expired token with no refresh token also backs off ---
printf '{"accessToken":"stub","expiresAt":1}' > "$FCREDS"
touch -t 202001010000 "$FCACHE"
before=$(cache_mtime "$FCACHE")
PATH="$STUB:$PATH" USAGE_CACHE="$FCACHE" USAGE_CREDENTIALS_FILE="$FCREDS" "$FETCH"
EXIT=$?
after=$(cache_mtime "$FCACHE")
if [ "$EXIT" -eq 0 ] && [ "$after" -gt "$before" ]; then
  PASS=$((PASS + 1)); echo "PASS: t1l6: missing refresh token advances cache mtime"
else
  FAIL=$((FAIL + 1)); echo "FAIL: t1l6: expected exit 0 + advanced mtime, got exit $EXIT (before=$before, after=$after)"
fi

# --- t1l7: an HTTP-date Retry-After is rejected, default backoff applies ---
cat > "$STUB/curl" <<'EOF'
#!/bin/sh
while [ $# -gt 0 ]; do
  if [ "$1" = "-D" ]; then printf 'HTTP/2 429\r\nretry-after: Wed, 21 Oct 2026 07:28:00 GMT\r\n\r\n' > "$2"; shift; fi
  shift
done
exit 22
EOF
printf '{"accessToken":"stub","refreshToken":"stub","expiresAt":9999999999999}' > "$FCREDS"
touch -t 202001010000 "$FCACHE"
NOW=$(date +%s)
PATH="$STUB:$PATH" USAGE_CACHE="$FCACHE" USAGE_CREDENTIALS_FILE="$FCREDS" "$FETCH"
EXIT=$?
after=$(cache_mtime "$FCACHE")
if [ "$EXIT" -eq 0 ] && [ "$after" -ge "$NOW" ] && [ "$after" -le "$((NOW + 10))" ]; then
  PASS=$((PASS + 1)); echo "PASS: t1l7: HTTP-date Retry-After falls through to the default backoff"
else
  FAIL=$((FAIL + 1)); echo "FAIL: t1l7: expected mtime ~now (date form rejected), got exit $EXIT (now=$NOW, after=$after)"
fi

# --- t1l8: a leading-zero Retry-After parses as base-10, not octal ---
# Reuses t1l7's unexpired credentials file.
cat > "$STUB/curl" <<'EOF'
#!/bin/sh
while [ $# -gt 0 ]; do
  if [ "$1" = "-D" ]; then printf 'HTTP/2 429\r\nretry-after: 08\r\n\r\n' > "$2"; shift; fi
  shift
done
exit 22
EOF
touch -t 202001010000 "$FCACHE"
NOW=$(date +%s)
PATH="$STUB:$PATH" USAGE_CACHE="$FCACHE" USAGE_CREDENTIALS_FILE="$FCREDS" "$FETCH"
EXIT=$?
after=$(cache_mtime "$FCACHE")
if [ "$EXIT" -eq 0 ] && [ "$after" -ge "$((NOW + 5))" ] && [ "$after" -le "$((NOW + 60))" ]; then
  PASS=$((PASS + 1)); echo "PASS: t1l8: leading-zero Retry-After applies its base-10 delay"
else
  FAIL=$((FAIL + 1)); echo "FAIL: t1l8: expected mtime ~now+8 (base-10), got exit $EXIT (now=$NOW, after=$after)"
fi

# --- t1m: a future-mtime backoff marker suppresses the fetch spawn ---
SPY="$WORK/spy-fetch.sh"
SPYLOG="$WORK/spy-fetch.log"
cat > "$SPY" <<EOF
#!/bin/sh
echo ran >> "$SPYLOG"
EOF
chmod +x "$SPY"
FUT="$WORK/future-cache.json"
: > "$FUT"
tgt=$(( $(date +%s) + 300 ))
fstamp=$(date -d "@${tgt}" +%Y%m%d%H%M.%S 2>/dev/null || date -r "$tgt" +%Y%m%d%H%M.%S 2>/dev/null)
touch -t "$fstamp" "$FUT"
echo '{"model":{"display_name":"Sonnet"},"session_id":"abc","workspace":{"current_dir":"/tmp/demo"}}' | USAGE_CACHE="$FUT" USAGE_FETCH="$SPY" "$PROJ/.claude/scripts/statusline.sh" >/dev/null
# 0.5s suffices for the negative: the spawn decision is synchronous, so a
# correct statusline forks nothing at all — only an already-broken one
# could log late.
sleep 0.5
if [ ! -f "$SPYLOG" ]; then
  PASS=$((PASS + 1)); echo "PASS: t1m: future-mtime marker reads as fresh, no fetch spawned"
else
  FAIL=$((FAIL + 1)); echo "FAIL: t1m: fetch was spawned despite a future-mtime marker"
fi

# --- t1m2: a stale marker spawns the fetch ---
touch -t 202001010000 "$FUT"
echo '{"model":{"display_name":"Sonnet"},"session_id":"abc","workspace":{"current_dir":"/tmp/demo"}}' | USAGE_CACHE="$FUT" USAGE_FETCH="$SPY" "$PROJ/.claude/scripts/statusline.sh" >/dev/null
tries=0
while [ ! -f "$SPYLOG" ] && [ "$tries" -lt 50 ]; do sleep 0.1; tries=$((tries + 1)); done
if [ -f "$SPYLOG" ]; then
  PASS=$((PASS + 1)); echo "PASS: t1m2: stale marker spawns the fetch"
else
  FAIL=$((FAIL + 1)); echo "FAIL: t1m2: fetch was not spawned for a stale marker"
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

# --- t6: Codex project writes shared files without Claude configuration ---
CODEX_PROJ="$WORK/codex-project"
ROOT="$CODEX_PROJ" "$SETUP" --project --cli codex >/dev/null 2>&1
assert_eq "t6: Codex project exits 0" 0 "$?"
assert_file_exists "t6: Codex project AGENTS.md" "$CODEX_PROJ/AGENTS.md"
assert_file_exists "t6: Codex project .editorconfig" "$CODEX_PROJ/.editorconfig"
assert_file_exists "t6: Codex project .markdownlint.json" "$CODEX_PROJ/.markdownlint.json"
assert_absent "t6: Codex project has no CLAUDE.md" "$CODEX_PROJ/CLAUDE.md"
assert_absent "t6: Codex project has no .claude" "$CODEX_PROJ/.claude"
assert_absent "t6: Codex project has no .codex" "$CODEX_PROJ/.codex"
echo "custom Codex instructions" > "$CODEX_PROJ/AGENTS.md"
OUT=$(ROOT="$CODEX_PROJ" "$SETUP" --cli codex)
assert_eq "t6: Codex rerun preserves instructions" "custom Codex instructions" "$(cat "$CODEX_PROJ/AGENTS.md")"
assert_eq "t6: Codex rerun skips every file" "Setup complete: 0 written, 3 skipped." "$(printf '%s\n' "$OUT" | tail -n 1)"

# --- t7: both clients share project instructions; can upgrade Codex setup ---
ROOT="$CODEX_PROJ" "$SETUP" --cli both >/dev/null 2>&1
assert_eq "t7: both project exits 0" 0 "$?"
assert_eq "t7: both preserves existing shared instructions" "custom Codex instructions" "$(cat "$CODEX_PROJ/AGENTS.md")"
assert_file_exists "t7: both project CLAUDE.md" "$CODEX_PROJ/CLAUDE.md"
assert_file_exists "t7: both project Claude settings" "$CODEX_PROJ/.claude/settings.json"
assert_file_exists "t7: both project Claude HUD" "$CODEX_PROJ/.claude/scripts/statusline.sh"
assert_absent "t7: both project has no duplicate .codex instructions" "$CODEX_PROJ/.codex"
OUT=$(ROOT="$CODEX_PROJ" "$SETUP" --cli both)
assert_eq "t7: both rerun skips every file" "Setup complete: 0 written, 7 skipped." "$(printf '%s\n' "$OUT" | tail -n 1)"

# --- t8: Codex global instructions use default or custom CODEX_HOME ---
CODEX_USER="$WORK/codex-home"
HOME="$CODEX_USER" CODEX_HOME="" "$SETUP" --user --cli codex >/dev/null 2>&1
assert_eq "t8: Codex user exits 0" 0 "$?"
assert_file_exists "t8: default Codex global AGENTS.md" "$CODEX_USER/.codex/AGENTS.md"
assert_absent "t8: Codex user has no Claude configuration" "$CODEX_USER/.claude"
assert_absent "t8: Codex user has no editor config" "$CODEX_USER/.codex/.editorconfig"
assert_absent "t8: Codex user has no model/sandbox config" "$CODEX_USER/.codex/config.toml"
CUSTOM_USER="$WORK/custom-home"
CUSTOM_CODEX="$WORK/custom codex"
HOME="$CUSTOM_USER" CODEX_HOME="$CUSTOM_CODEX" "$SETUP" --user --cli codex >/dev/null 2>&1
assert_eq "t8: custom Codex user exits 0" 0 "$?"
assert_file_exists "t8: custom Codex global AGENTS.md" "$CUSTOM_CODEX/AGENTS.md"
assert_absent "t8: custom Codex user has no default .codex" "$CUSTOM_USER/.codex"
assert_absent "t8: custom Codex user has no Claude configuration" "$CUSTOM_USER/.claude"
echo "custom global instructions" > "$CUSTOM_CODEX/AGENTS.md"
OUT=$(HOME="$CUSTOM_USER" CODEX_HOME="$CUSTOM_CODEX" "$SETUP" --user --cli codex)
assert_eq "t8: Codex user rerun preserves instructions" "custom global instructions" "$(cat "$CUSTOM_CODEX/AGENTS.md")"
assert_eq "t8: Codex user rerun skips instructions" "Setup complete: 0 written, 1 skipped." "$(printf '%s\n' "$OUT" | tail -n 1)"

# --- t9: both global sets remain in their client-specific directories ---
HOME="$CUSTOM_USER" CODEX_HOME="$CUSTOM_CODEX" "$SETUP" --user --cli both >/dev/null 2>&1
assert_eq "t9: both global exits 0" 0 "$?"
assert_file_exists "t9: both Claude AGENTS.md" "$CUSTOM_USER/.claude/AGENTS.md"
assert_file_exists "t9: both Claude CLAUDE.md" "$CUSTOM_USER/.claude/CLAUDE.md"
assert_file_exists "t9: both Claude HUD settings" "$CUSTOM_USER/.claude/settings.json"
assert_eq "t9: both preserves Codex instructions" "custom global instructions" "$(cat "$CUSTOM_CODEX/AGENTS.md")"
assert_absent "t9: no Claude wrapper in Codex directory" "$CUSTOM_CODEX/CLAUDE.md"
assert_absent "t9: no Claude HUD in Codex directory" "$CUSTOM_CODEX/scripts"
OUT=$(HOME="$CUSTOM_USER" CODEX_HOME="$CUSTOM_CODEX" "$SETUP" --user --cli both)
assert_eq "t9: both global rerun skips all files" "Setup complete: 0 written, 6 skipped." "$(printf '%s\n' "$OUT" | tail -n 1)"
assert_absent "t9: default Claude user setup did not create Codex files" "$USER_HOME/.codex"
CLAUDE_USER="$WORK/explicit-claude"
CLAUDE_UNUSED_CODEX="$WORK/unused-codex"
HOME="$CLAUDE_USER" CODEX_HOME="$CLAUDE_UNUSED_CODEX" "$SETUP" --user --cli claude >/dev/null 2>&1
assert_eq "t9: explicit Claude mode exits 0" 0 "$?"
assert_absent "t9: explicit Claude mode ignores CODEX_HOME" "$CLAUDE_UNUSED_CODEX"

# --- t10: invalid client arguments fail before creating directories ---
INVALID_PROJ="$WORK/invalid-project"
for invalid_cli in invalid CODEX --project ''; do
  ROOT="$INVALID_PROJ" "$SETUP" --cli "$invalid_cli" >/dev/null 2>&1
  assert_eq "t10: invalid CLI '$invalid_cli' exits 2" 2 "$?"
done
ROOT="$INVALID_PROJ" "$SETUP" --cli >/dev/null 2>&1
assert_eq "t10: missing CLI exits 2" 2 "$?"
ROOT="$INVALID_PROJ" "$SETUP" --cli codex --bogus >/dev/null 2>&1
assert_eq "t10: later unknown flag exits 2" 2 "$?"
assert_absent "t10: rejected arguments produce no project files" "$INVALID_PROJ"
HOME="$WORK/invalid-user" "$SETUP" --user --cli invalid >/dev/null 2>&1
assert_eq "t10: invalid global CLI exits 2" 2 "$?"
assert_absent "t10: rejected arguments produce no global files" "$WORK/invalid-user"

# --- t11: preserve dangling symlinks and existing HUD file permissions ---
SYMLINK_PROJ="$WORK/symlink-project"
mkdir -p "$SYMLINK_PROJ/.claude/scripts"
ln -s "$WORK/missing-agents" "$SYMLINK_PROJ/AGENTS.md"
printf 'existing editor configuration\n' > "$WORK/existing-editorconfig"
ln -s "$WORK/existing-editorconfig" "$SYMLINK_PROJ/.editorconfig"
ln -s "$WORK/missing-settings" "$SYMLINK_PROJ/.claude/settings.json"
printf 'existing statusline\n' > "$SYMLINK_PROJ/.claude/scripts/statusline.sh"
chmod 644 "$SYMLINK_PROJ/.claude/scripts/statusline.sh"
ln -s "$WORK/missing-fetch" "$SYMLINK_PROJ/.claude/scripts/usage-fetch.sh"
ROOT="$SYMLINK_PROJ" "$SETUP" --cli both >/dev/null 2>&1
assert_eq "t11: setup preserving symlinks exits 0" 0 "$?"
assert_eq "t11: AGENTS symlink preserved" "$WORK/missing-agents" "$(readlink "$SYMLINK_PROJ/AGENTS.md")"
assert_absent "t11: AGENTS symlink target untouched" "$WORK/missing-agents"
assert_eq "t11: valid editorconfig symlink preserved" "$WORK/existing-editorconfig" "$(readlink "$SYMLINK_PROJ/.editorconfig")"
assert_eq "t11: valid editorconfig target preserved" "existing editor configuration" "$(cat "$WORK/existing-editorconfig")"
assert_absent "t11: settings symlink target untouched" "$WORK/missing-settings"
assert_absent "t11: HUD symlink target untouched" "$WORK/missing-fetch"
assert_eq "t11: existing HUD content preserved" "existing statusline" "$(cat "$SYMLINK_PROJ/.claude/scripts/statusline.sh")"
if [ -x "$SYMLINK_PROJ/.claude/scripts/statusline.sh" ]; then
  FAIL=$((FAIL + 1)); echo "FAIL: t11: existing HUD permissions changed"
else
  PASS=$((PASS + 1)); echo "PASS: t11: existing HUD permissions preserved"
fi

echo
echo "Result: $PASS passed, $FAIL failed."
[ $FAIL -eq 0 ]
