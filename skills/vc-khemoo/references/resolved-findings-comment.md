# Resolved Findings PR Comment Template

Used by Stage 4 of the vc-khemoo pipeline. Posted as a single comment on the PR after all findings have been fixed or deferred to follow-up issues.

## Invocation

```bash
gh pr comment <pr-number> --body "$(cat <<'EOF'
## Review pipeline summary

### Fixed in this PR
- **[Reviewer] severity** — <description> (file:line)
  - Fix: <commit-sha> <commit-subject>
- ...

### Deferred to follow-up issues
- **[Reviewer] severity** — <description> (file:line)
  - Tracked in: #<issue-number>
- ...
EOF
)"
```

## Notes

- If either section (Fixed / Deferred) is empty, omit it entirely.
- One comment per PR, posted at the end of the resolve loop — not per finding.
- The fix-commit SHA is the short SHA (`git rev-parse --short HEAD` after the fix push).
- The issue number is the one returned by `gh issue create` when the finding was deferred.
