#!/usr/bin/env bash
# setup-khemoo audit — lexical scan for the 3 lexically-detectable disciplines.
# Disciplines 4-6 require semantic review and are not scanned here.
#
# Run from the project root: ./skills/setup-khemoo/scripts/audit.sh
# Exit 0 = clean. Exit 1 = violations found.

set -uo pipefail

ROOT="${ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$ROOT" || exit 2

# Build path-exclusion args for find. Anything under .git, node_modules, or
# *-workspace is out of scope (eval artifacts, vendor, history).
# Prune:
#  - .git, node_modules, *-workspace (vendor / history / eval artifacts)
#  - skills/setup-khemoo (this skill names the forbidden patterns by definition)
#  - test-*.sh (test fixtures intentionally contain the patterns)
prune_args=(
  -path './.git' -prune -o
  -path './node_modules' -prune -o
  -path './*-workspace' -prune -o
  -path './skills/setup-khemoo' -prune -o
  -name 'test-*.sh' -prune -o
)

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
    find . "${prune_args[@]}" -type f \( "${globs[@]}" \) -print
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
