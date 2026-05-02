# Deferred Finding Issue Template

Used by Stage 4 of the vc-khemoo pipeline. One GitHub issue per deferred finding (out-of-scope, architectural, or cross-cutting concerns surfaced by review but not fixed in the current PR).

## Invocation

```bash
gh issue create --title "[vc-khemoo review] <reviewer>: <short summary>" --body "$(cat <<'EOF'
**Source:** PR #<pr-number> (<reviewer> review pass)
**Severity:** major | minor
**Location:** <file>:<line>

## Finding

<description from the reviewer's report>

## Why deferred

<one sentence: out of scope for this PR / requires separate design discussion / cross-cutting refactor / etc.>

## Suggested fix

<the reviewer's suggestion, if any>
EOF
)"
```

## Notes

- Add labels if the project uses them: at minimum `vc-khemoo` and the reviewer's role (e.g. `security`, `perf`).
- Never defer a `critical` finding or any `REQUEST_CHANGES` verdict — those must be fixed in the PR.
- If more than 5 findings would be deferred from a single review pass, stop and ask the user before creating the issues — that volume signals the PR's scope is wrong.
