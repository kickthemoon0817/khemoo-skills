#!/usr/bin/env bash
# setup-khemoo audit — lexical scan for the 3 lexically-detectable disciplines.
# Disciplines 4-6 require semantic review and are not scanned here.
#
# Run from anywhere:
#   ./audit.sh              # --project (default): scan the current project
#   ./audit.sh --project    # explicit project scope
#   ./audit.sh --user       # scan user-authored ~/.claude/ content
# Exit 0 = clean. Exit 1 = violations found. Exit 2 = bad usage.

set -uo pipefail

SCOPE="project"
for arg in "$@"; do
  case "$arg" in
    --project) SCOPE="project" ;;
    --user)    SCOPE="user" ;;
    -h|--help)
      sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      echo "Use --project (default) or --user." >&2
      exit 2
      ;;
  esac
done

if [ "$SCOPE" = "user" ]; then
  ROOT="${HOME}/.claude"
  if [ ! -d "$ROOT" ]; then
    echo "User-scope audit needs $ROOT but the directory does not exist." >&2
    exit 2
  fi
  # User-scope prune: third-party plugins, session logs, caches — those
  # aren't the user's own authorship.
  prune_args=(
    -path "$ROOT/.git" -prune -o
    -path "$ROOT/plugins" -prune -o
    -path "$ROOT/projects" -prune -o
    -path "$ROOT/sessions" -prune -o
    -path "$ROOT/shell-snapshots" -prune -o
    -path "$ROOT/local-cache" -prune -o
    -path "$ROOT/todos" -prune -o
  )
else
  ROOT="${ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
  # Project-scope prune: vendor / history / eval artifacts, this skill (names
  # the forbidden patterns by definition), and test-*.sh (fixtures).
  prune_args=(
    -path "$ROOT/.git" -prune -o
    -path "$ROOT/node_modules" -prune -o
    -path "$ROOT/*-workspace" -prune -o
    -path "$ROOT/skills/setup-khemoo" -prune -o
    -name 'test-*.sh' -prune -o
  )
fi

cd "$ROOT" || exit 2
echo "Scope: $SCOPE ($ROOT)"
echo

# Patterns for the 3 lexical disciplines.
HISTORY_DOC_RE='\((preferred over|replaces|introduced in version|was previously done via|deprecated in favor of) '
WHAT_COMMENT_RE='(\/\/|#|--) (used by|added for the|handles the case from) '
REMOVED_MARKER_RE='(\/\/|#|--) (removed: |removed in )'

violations=0

scan() {
  local label="$1" pattern="$2"
  shift 2
  local globs=("$@")

  echo "=== ${label} ==="
  local hits=0
  while IFS= read -r f; do
    if grep -nE "$pattern" "$f" 2>/dev/null | sed "s|^|${f}:|"; then
      hits=$((hits + 1))
    fi
  done < <(
    find "$ROOT" "${prune_args[@]}" -type f \( "${globs[@]}" \) -print
  )
  if [ "$hits" -eq 0 ]; then
    echo "  clean"
  else
    violations=$((violations + hits))
  fi
  echo
}

# Markdown files only for history-in-docs.
scan "Discipline 1: history-in-docs (Markdown only)" \
  "$HISTORY_DOC_RE" \
  -name '*.md'

# Common code file types for WHAT-comments and removed markers.
code_globs=(
  -name '*.ts' -o
  -name '*.tsx' -o
  -name '*.js' -o
  -name '*.jsx' -o
  -name '*.py' -o
  -name '*.rb' -o
  -name '*.go' -o
  -name '*.rs' -o
  -name '*.sh' -o
  -name '*.zsh' -o
  -name '*.lua' -o
  -name '*.sql'
)

scan "Discipline 2: WHAT-comments (code files)" \
  "$WHAT_COMMENT_RE" \
  "${code_globs[@]}"

scan "Discipline 3: removed markers (code files)" \
  "$REMOVED_MARKER_RE" \
  "${code_globs[@]}"

echo "=== Disciplines 4-6 (defensive validation, premature abstraction, restated TL;DRs) ==="
echo "  Lexical detection isn't reliable for these — run a code review pass"
echo "  (e.g., vc-khemoo review stage) to catch them."
echo

if [ "$violations" -gt 0 ]; then
  echo "Audit FAILED: ${violations} lexical violation(s) found."
  exit 1
fi
echo "Audit PASSED: no lexical violations of disciplines 1-3."
