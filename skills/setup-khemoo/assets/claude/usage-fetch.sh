#!/usr/bin/env bash
# setup-khemoo usage fetcher — refreshes the Anthropic OAuth usage cache.
#
# Reads OAuth credentials, refreshes the access token when expired, calls the
# usage API, and writes ~/.claude/usage-cache.json for statusline.sh to render.
# Dependency-free: bash + curl + date + grep/sed/awk + `security` — no
# jq/python/node. Designed to be spawned in the background by statusline.sh —
# silent on every failure so an absent network or missing credentials never
# disrupt the HUD; failed runs back off (see backoff) instead of letting
# statusline.sh spawn a fresh fetch on every render.
#
# Credentials are read from the macOS Keychain ("Claude Code-credentials"),
# then ~/.claude/.credentials.json. Set $USAGE_CREDENTIALS_FILE to read from a
# specific file instead (skips the Keychain). Override the cache path with
# $USAGE_CACHE.

set -uo pipefail

CACHE="${USAGE_CACHE:-${HOME}/.claude/usage-cache.json}"
CLIENT_ID="${CLAUDE_CODE_OAUTH_CLIENT_ID:-9d1c250a-e61b-44d9-88ed-5944d1962f5e}"
LOCK="${CACHE}.lock"

mkdir -p "$(dirname "$CACHE")" 2>/dev/null || true

# === single-flight lock ===
# mkdir is atomic; if the dir exists a fetch is already in flight. Reclaim a
# lock older than 30s in case a prior run was killed before its cleanup.
file_mtime() {
  # GNU stat first — BSD stat fails -c with clean stdout, but GNU stat -f
  # prints a multi-line filesystem dump that poisons arithmetic callers.
  stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null || echo 0
}
if ! mkdir "$LOCK" 2>/dev/null; then
  age=$(( $(date +%s) - $(file_mtime "$LOCK") ))
  [ "$age" -lt 30 ] && exit 0
  rmdir "$LOCK" 2>/dev/null || true
  mkdir "$LOCK" 2>/dev/null || exit 0
fi
# The rm reaps header/tmp orphans a killed prior run may have left; the
# single-flight lock guarantees no live run owns them.
trap 'rm -f "$CACHE".hdrs.* "$CACHE".tmp.* 2>/dev/null; rmdir "$LOCK" 2>/dev/null || true' EXIT

# === failure backoff ===
backoff() {
  # Advance the cache mtime on every failure so statusline.sh waits a full
  # refresh interval before spawning the next fetch — a bare exit leaves the
  # cache stale, and one transient API failure becomes a retry-per-render
  # storm that keeps the usage endpoint rate limited.
  #
  # $1 (optional): seconds until the next attempt, from the server's
  # Retry-After — the default interval would probe a still-hot limiter
  # several times per penalty window and can re-arm it. A future mtime reads
  # as fresh to statusline.sh's now-minus-mtime check, so the longer wait
  # needs no statusline change. Capped: the header is external input.
  local delay="${1:-0}" target stamp
  case "$delay" in ''|*[!0-9]*) delay=0 ;; esac
  [ "$delay" -gt 3600 ] && delay=3600
  if [ "$delay" -gt 0 ]; then
    target=$(( $(date +%s) + delay ))
    stamp=$(date -d "@${target}" +%Y%m%d%H%M.%S 2>/dev/null \
      || date -r "$target" +%Y%m%d%H%M.%S 2>/dev/null)
    [ -n "$stamp" ] && touch -t "$stamp" "$CACHE" 2>/dev/null && exit 0
  fi
  touch "$CACHE" 2>/dev/null || true
  exit 0
}

# === JSON field readers (flat objects only) ===
json_str() {
  printf '%s' "$1" | grep -oE "\"$2\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" \
    | head -1 | sed -E 's/.*:[[:space:]]*"([^"]*)"/\1/'
}
json_num() {
  printf '%s' "$1" | grep -oE "\"$2\"[[:space:]]*:[[:space:]]*[0-9]+" \
    | head -1 | grep -oE '[0-9]+$'
}

# === read OAuth credentials ===
creds=""
if [ -n "${USAGE_CREDENTIALS_FILE+x}" ]; then
  [ -f "$USAGE_CREDENTIALS_FILE" ] && creds=$(cat "$USAGE_CREDENTIALS_FILE" 2>/dev/null || true)
else
  if [ "$(uname -s)" = "Darwin" ]; then
    creds=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null || true)
  fi
  if [ -z "$creds" ] && [ -f "${HOME}/.claude/.credentials.json" ]; then
    creds=$(cat "${HOME}/.claude/.credentials.json" 2>/dev/null || true)
  fi
fi
[ -z "$creds" ] && backoff

access_token=$(json_str "$creds" accessToken)
refresh_token=$(json_str "$creds" refreshToken)
expires_at=$(json_num "$creds" expiresAt)

# === refresh the access token when expired ===
now_ms=$(( $(date +%s) * 1000 ))
if [ -n "$expires_at" ] && [ "$expires_at" -le "$now_ms" ] 2>/dev/null; then
  [ -z "$refresh_token" ] && backoff
  refreshed=$(curl -fsS --max-time 10 -X POST \
    "https://platform.claude.com/v1/oauth/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "grant_type=refresh_token" \
    --data-urlencode "refresh_token=${refresh_token}" \
    --data-urlencode "client_id=${CLIENT_ID}" 2>/dev/null || true)
  new_token=$(json_str "$refreshed" access_token)
  [ -z "$new_token" ] && backoff
  access_token="$new_token"
fi
[ -z "$access_token" ] && backoff

# === fetch usage ===
hdrs="${CACHE}.hdrs.$$"
usage=$(curl -fsS --max-time 10 -D "$hdrs" \
  "https://api.anthropic.com/api/oauth/usage" \
  -H "Authorization: Bearer ${access_token}" \
  -H "anthropic-beta: oauth-2025-04-20" \
  -H "Content-Type: application/json" 2>/dev/null || true)
if [ -z "$usage" ]; then
  retry_after=$(grep -iE '^retry-after:' "$hdrs" 2>/dev/null | head -1 \
    | grep -oE '[0-9]+' | head -1)
  rm -f "$hdrs"
  backoff "${retry_after:-0}"
fi
rm -f "$hdrs"

# === parse ===
# Each window is a flat object: {"utilization":N,"resets_at":"..."}.
obj_for() {
  printf '%s' "$1" | grep -oE "\"$2\"[[:space:]]*:[[:space:]]*\{[^}]*\}" | head -1
}
util_pct() {
  # utilization is a 0-100 float; round to the nearest integer.
  printf '%s' "$1" | grep -oE '"utilization"[[:space:]]*:[[:space:]]*[0-9.]+' \
    | head -1 | grep -oE '[0-9.]+$' | awk '{printf "%d", $1 + 0.5}'
}
norm_iso() {
  # The API returns e.g. 2026-05-16T09:00:00.576859+00:00 — drop the fractional
  # seconds and normalize the UTC marker to a trailing Z.
  printf '%s' "$1" | sed -E 's/\.[0-9]+//' | sed -E 's/(\+00:00|Z)?$/Z/'
}
iso_of() {
  local raw
  raw=$(printf '%s' "$1" | grep -oE '"resets_at"[[:space:]]*:[[:space:]]*"[^"]*"' \
    | head -1 | sed -E 's/.*:[[:space:]]*"([^"]*)"/\1/')
  [ -z "$raw" ] && return
  norm_iso "$raw"
}

five=$(obj_for "$usage" five_hour)
week=$(obj_for "$usage" seven_day)
[ -z "$five" ] && [ -z "$week" ] && backoff

five_pct=$(util_pct "$five")
five_reset=$(iso_of "$five")
week_pct=$(util_pct "$week")
week_reset=$(iso_of "$week")

# === write cache atomically ===
tmp="${CACHE}.tmp.$$"
cat > "$tmp" <<EOF
{
  "timestamp": ${now_ms},
  "data": {
    "fiveHourPercent": ${five_pct:-0},
    "fiveHourResetsAt": "${five_reset}",
    "weeklyPercent": ${week_pct:-0},
    "weeklyResetsAt": "${week_reset}"
  }
}
EOF
mv "$tmp" "$CACHE"
