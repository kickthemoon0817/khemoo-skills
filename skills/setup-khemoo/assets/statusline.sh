#!/usr/bin/env bash
# setup-khemoo HUD — one-line status for Claude Code's statusLine.
# Reads the status JSON payload from stdin, prints a single line to stdout.
# Dependency-free: uses bash + grep + sed + date only.
#
# Renders (opportunistically, fields drop when their source is missing):
#   <model> · <project> NN% (1h30m/5h) NN% (3d/7d) · <session> · <X>k/<limit> context
#
# With $HUD_DETAIL set to a non-empty value, a second gray line follows with a
# transcript-event breakdown: messages, tool calls, hooks, attachments.
#
# Percentages glue onto the project segment with a single space so the budget
# state reads as part of "where am I working".
#
# - context comes from the transcript file: input_tokens +
#   cache_creation_input_tokens + cache_read_input_tokens from the last
#   assistant message's usage block. Limit is "1m" if the model display name
#   contains "1M" or "Opus", else "200k".
# - The two percentages are the 5h and weekly Anthropic OAuth usage caps.
#   Percentage is colored (green <50, yellow 50-80, red ≥80). The parens
#   show elapsed-of-window time.
# - The percentages come from a local JSON cache at ~/.claude/usage-cache.json,
#   refreshed by usage-fetch.sh (installed alongside this script). When the
#   cache is missing or older than 120s, this script spawns usage-fetch.sh in
#   the background — the current render is never blocked; the next one picks up
#   fresh data. Override the cache path via $USAGE_CACHE and the fetcher path
#   via $USAGE_FETCH (set $USAGE_FETCH empty to disable the spawn).

set -uo pipefail

input=$(cat)

# --- helpers ----------------------------------------------------------------

pull_str() {
  # Pull a top-level (or nested) string field from $input JSON.
  printf '%s' "$input" \
    | grep -oE "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" \
    | head -1 \
    | sed -E 's/.*:[[:space:]]*"([^"]*)"/\1/'
}

pull_num_from() {
  # $1 = file, $2 = key. Returns "" if missing.
  grep -oE "\"$2\"[[:space:]]*:[[:space:]]*[0-9]+" "$1" 2>/dev/null \
    | head -1 \
    | grep -oE '[0-9]+$'
}

pull_str_from() {
  # $1 = file, $2 = key. Returns "" if missing.
  grep -oE "\"$2\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$1" 2>/dev/null \
    | head -1 \
    | sed -E 's/.*:[[:space:]]*"([^"]*)"/\1/'
}

iso_to_epoch() {
  # Convert ISO 8601 (2026-05-14T18:20:00.844Z) to Unix epoch seconds.
  # Strips fractional seconds, then tries GNU date, then BSD date (macOS).
  local iso
  iso=$(printf '%s' "$1" | sed -E 's/\.[0-9]+Z?$//' | sed -E 's/Z$//')
  date -u -d "${iso}Z" +%s 2>/dev/null && return
  date -j -u -f '%Y-%m-%dT%H:%M:%S' "$iso" +%s 2>/dev/null
}

human_duration() {
  # $1 = seconds. Right-aligns to 5 chars — the common full width (5h00m,
  # 2d13h) — so full-width values sit flush after "(" while short ones (42m)
  # still left-pad to stay aligned. The rare 6-char form (e.g. 23h59m) prints
  # as-is.
  local s="$1"
  [ -z "$s" ] && return
  local val
  if [ "$s" -le 0 ] 2>/dev/null; then
    val="0m"
  else
    local h=$((s / 3600))
    local m=$(((s % 3600) / 60))
    local d=$((h / 24))
    if [ "$d" -gt 0 ]; then
      val=$(printf '%dd%02dh' "$d" "$((h % 24))")
    elif [ "$h" -gt 0 ]; then
      val=$(printf '%dh%02dm' "$h" "$m")
    else
      val=$(printf '%dm' "$m")
    fi
  fi
  printf '%5s' "$val"
}

RED=$'\033[31m'
YELLOW=$'\033[33m'
GREEN=$'\033[32m'
GRAY=$'\033[90m'
RESET=$'\033[0m'

# Major-segment separator — gray so the dividers recede and the colored
# content (model, usage, context) stands out.
SEP=" ${GRAY}·${RESET} "

# Placeholders for missing data — rendered in gray so they read as "no signal
# yet" rather than real values. Width matches the populated version so the
# HUD doesn't jitter when a source comes and goes. Using \033[90m (bright
# black) instead of \033[2m (dim) because dim renders invisible in many
# terminal themes.
PH_CONTEXT="${GRAY}???k/? context${RESET}"
PH_FIVE="${GRAY} ??% (  zzz/5h)${RESET}"
PH_WEEK="${GRAY} ??% (  zzz/7d)${RESET}"

color_for_pct() {
  # Return an ANSI escape based on threshold: green <50, yellow 50-80, red ≥80.
  local pct="$1"
  if [ "$pct" -ge 80 ] 2>/dev/null; then
    printf '%s' "$RED"
  elif [ "$pct" -ge 50 ] 2>/dev/null; then
    printf '%s' "$YELLOW"
  else
    printf '%s' "$GREEN"
  fi
}

format_limit() {
  # $1 = percent, $2 = ISO reset time, $3 = window seconds, $4 = window label.
  # Pads pct to 4 visible chars and elapsed to 6 chars so HUD width stays
  # stable across value changes.
  local pct="$1" reset_iso="$2" window_secs="$3" window_label="$4"
  [ -z "$pct" ] && return
  local color pct_str
  color=$(color_for_pct "$pct")
  pct_str=$(printf '%3d%%' "$pct")
  local out="${color}${pct_str}${RESET}"
  if [ -n "$reset_iso" ] && [ -n "$window_secs" ]; then
    local now reset elapsed
    now=$(date +%s)
    reset=$(iso_to_epoch "$reset_iso")
    if [ -n "$reset" ]; then
      elapsed=$((window_secs - (reset - now)))
      [ "$elapsed" -lt 0 ] && elapsed=0
      [ "$elapsed" -gt "$window_secs" ] && elapsed=$window_secs
      out="${out} ($(human_duration "$elapsed")/${window_label})"
    fi
  fi
  printf '%s' "$out"
}

# --- session fields ---------------------------------------------------------

model=$(pull_str display_name)
[ -z "$model" ] && model=$(pull_str id)

session_full=$(pull_str session_id)
session=${session_full:0:8}

cwd=$(pull_str current_dir)
[ -z "$cwd" ] && cwd=$(pull_str cwd)
project=$(basename "${cwd:-?}")

transcript=$(pull_str transcript_path)

# --- usage limits (opportunistic) ------------------------------------------

# If $USAGE_CACHE is unset, fall back to the default cache path. If it IS set
# (even to a nonexistent path), respect it verbatim — this makes the env var
# work as an explicit override for tests and alternative setups.
if [ -z "${USAGE_CACHE+x}" ]; then
  USAGE_CACHE="${HOME}/.claude/usage-cache.json"
fi

# Spawn a background refresh when the cache is missing or older than 120s, so
# the next render has fresh data. Fire-and-forget — never blocks this render.
if [ -z "${USAGE_FETCH+x}" ]; then
  sl_dir=$(cd "$(dirname "$0")" 2>/dev/null && pwd)
  USAGE_FETCH="${sl_dir}/usage-fetch.sh"
fi
if [ -n "$USAGE_FETCH" ] && [ -x "$USAGE_FETCH" ]; then
  stale=1
  if [ -f "$USAGE_CACHE" ]; then
    cache_mtime=$(stat -f %m "$USAGE_CACHE" 2>/dev/null || stat -c %Y "$USAGE_CACHE" 2>/dev/null || echo 0)
    [ "$(( $(date +%s) - cache_mtime ))" -lt 120 ] && stale=0
  fi
  [ "$stale" -eq 1 ] && ( USAGE_CACHE="$USAGE_CACHE" "$USAGE_FETCH" >/dev/null 2>&1 & )
fi

five_part=""
week_part=""
if [ -f "$USAGE_CACHE" ]; then
  five_pct=$(pull_num_from "$USAGE_CACHE" fiveHourPercent)
  five_reset=$(pull_str_from "$USAGE_CACHE" fiveHourResetsAt)
  week_pct=$(pull_num_from "$USAGE_CACHE" weeklyPercent)
  week_reset=$(pull_str_from "$USAGE_CACHE" weeklyResetsAt)
  five_part=$(format_limit "$five_pct" "$five_reset" 18000 "5h")
  week_part=$(format_limit "$week_pct" "$week_reset" 604800 "7d")
fi
[ -z "$five_part" ] && five_part="$PH_FIVE"
[ -z "$week_part" ] && week_part="$PH_WEEK"

# Glue the percentages onto the project segment with a single space.
project_segment="${project} ${five_part} ${week_part}"

parts="${model:-?}${SEP}${project_segment}${SEP}${session:-?}"

# Current context from the transcript, with a gray placeholder when missing.
context_part="$PH_CONTEXT"
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
  # Sum input + cache_creation + cache_read tokens from the last assistant
  # message's usage block.
  last_usage_lineno=$(grep -nE '"input_tokens"[[:space:]]*:' "$transcript" 2>/dev/null \
    | tail -1 \
    | cut -d: -f1)
  if [ -n "$last_usage_lineno" ]; then
    ctx_tokens=$(sed -n "${last_usage_lineno}p" "$transcript" \
      | grep -oE '"(input_tokens|cache_creation_input_tokens|cache_read_input_tokens)"[[:space:]]*:[[:space:]]*[0-9]+' \
      | grep -oE '[0-9]+$' \
      | awk '{s+=$1} END {print s+0}')
    if [ -n "$ctx_tokens" ] && [ "$ctx_tokens" -gt 0 ] 2>/dev/null; then
      ctx_human=$(awk -v n="$ctx_tokens" 'BEGIN {
        if (n >= 100000) printf "%dk", int(n/1000+0.5)
        else if (n >= 1000) printf "%.1fk", n/1000
        else printf "%d", n
      }')
      # Tier inference: Claude Code sometimes only sends a short display name
      # (e.g., "Opus 4.7") with no tier marker. Treat all Opus models as 1M
      # by default, and auto-promote any observed context above 200k.
      ctx_limit_label="200k"
      case "$model" in
        *"1M"*|*"1m"*|*"Opus"*|*"opus"*) ctx_limit_label="1m" ;;
      esac
      [ "$ctx_tokens" -gt 200000 ] 2>/dev/null && ctx_limit_label="1m"
      context_part="${ctx_human}/${ctx_limit_label} context"
    fi
  fi
fi
parts="${parts}${SEP}${context_part}"

# Optional detail line: a gray transcript-event breakdown. Tallies every
# "type":"..." occurrence — message/hook types sit at the record's top level,
# tool_use/attachment types are nested inside records, so all matches per line
# are counted. Emitted only when $HUD_DETAIL is non-empty.
if [ -n "${HUD_DETAIL:-}" ] && [ -n "$transcript" ] && [ -f "$transcript" ]; then
  detail=$(awk '
    {
      s = $0
      while (match(s, /"type":"[^"]*"/)) {
        t = substr(s, RSTART, RLENGTH)
        gsub(/"type":"|"/, "", t)
        c[t]++
        s = substr(s, RSTART + RLENGTH)
      }
    }
    END {
      msgs = c["user"] + c["assistant"]
      hooks = c["hook_success"] + c["hook_additional_context"]
      printf "%d msgs · %d tools · %d hooks · %d attach", msgs, c["tool_use"], hooks, c["attachment"]
    }' "$transcript" 2>/dev/null)
  [ -n "$detail" ] && parts="${parts}"$'\n'"${GRAY}${detail}${RESET}"
fi

printf '%s' "$parts"
