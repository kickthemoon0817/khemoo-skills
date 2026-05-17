#!/usr/bin/env bash
# setup-khemoo usage fetcher — refreshes the Anthropic OAuth usage cache.
#
# Reads OAuth credentials, refreshes the access token when expired, calls the
# usage API, and writes ~/.claude/usage-cache.json for statusline.sh to render.
# Dependency-free: bash + curl + date + grep/sed/awk + `security` — no
# jq/python/node. Designed to be spawned in the background by statusline.sh —
# silent on every failure so an absent network or missing credentials never
# disrupt the HUD.
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
  stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || echo 0
}
if ! mkdir "$LOCK" 2>/dev/null; then
  age=$(( $(date +%s) - $(file_mtime "$LOCK") ))
  [ "$age" -lt 30 ] && exit 0
  rmdir "$LOCK" 2>/dev/null || true
  mkdir "$LOCK" 2>/dev/null || exit 0
fi
trap 'rmdir "$LOCK" 2>/dev/null || true' EXIT

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
[ -z "$creds" ] && exit 0

access_token=$(json_str "$creds" accessToken)
refresh_token=$(json_str "$creds" refreshToken)
expires_at=$(json_num "$creds" expiresAt)

# === refresh the access token when expired ===
now_ms=$(( $(date +%s) * 1000 ))
if [ -n "$expires_at" ] && [ "$expires_at" -le "$now_ms" ] 2>/dev/null; then
  [ -z "$refresh_token" ] && exit 0
  refreshed=$(curl -fsS --max-time 10 -X POST \
    "https://platform.claude.com/v1/oauth/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "grant_type=refresh_token" \
    --data-urlencode "refresh_token=${refresh_token}" \
    --data-urlencode "client_id=${CLIENT_ID}" 2>/dev/null || true)
  new_token=$(json_str "$refreshed" access_token)
  [ -z "$new_token" ] && exit 0
  access_token="$new_token"
fi
[ -z "$access_token" ] && exit 0

# === fetch usage ===
usage=$(curl -fsS --max-time 10 \
  "https://api.anthropic.com/api/oauth/usage" \
  -H "Authorization: Bearer ${access_token}" \
  -H "anthropic-beta: oauth-2025-04-20" \
  -H "Content-Type: application/json" 2>/dev/null || true)
[ -z "$usage" ] && exit 0

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
[ -z "$five" ] && [ -z "$week" ] && exit 0

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
