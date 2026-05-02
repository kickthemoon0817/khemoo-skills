# PR Title and Body Template

Used by Stage 2 of the vc-khemoo pipeline.

## Title

```
<Type>: <Subject>
```

Capitalize whatever type was used in the underlying commits — `Feat`, `Fix`, `Docker`, `Sim`, `Ros2`, `Auth`, etc. The same permissive type set as Stage 1 applies.

## Body — `gh pr create` invocation

```bash
gh pr create --title "<Type>: <Subject>" --body "$(cat <<'EOF'
## Summary

<what changed and why>

## Changes

-

## How to Test

-

## Release-Note

<one sentence an end user would care about, OR "none — internal change">

## Checklist

### Testing
- [ ] Tests added/updated (or N/A with reason)
- [ ] Verified manually

### Compatibility
- [ ] Breaking changes noted (if any)

### Documentation
- [ ] Docs/config updated (if needed)
EOF
)"
```

Fill from Stage 1 micro-commit messages and report the PR URL. The Release-Note line is consumed by Stage 5 — see `bump-decision.md`.
