# PR Title and Body Template

Used by Stage 2 of the vc-khemoo pipeline.

## Title

```
<Type>: <Subject>
```

Example: `Feat: Add New Button Component`.

Capitalize whatever type was used in the underlying commits (e.g. `Feat`, `Fix`, `Docker`, `Sim`, `Ros2`, `Auth`). The same permissive type set as Stage 1 applies.

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

## Notes

- Fill in Summary, Changes, How to Test, and Release-Note from the micro-commit messages produced in Stage 1.
- The **Release-Note** line is consumed by Stage 5 to decide patch vs minor — if it says `none — internal change`, Stage 5 treats the change as a patch regardless of `feat:` prefixes.
- Report the PR URL after creation.
