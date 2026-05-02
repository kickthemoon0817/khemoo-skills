# Release Commands

Used by Stage 5 of the vc-khemoo pipeline. Pick the block that matches the bump level.

Both blocks assume the version-bump commit has already been pushed (`git push origin HEAD`).

## Patch — tag only (no GitHub Release)

```bash
git tag -a v<version> -m "v<version>: <summary>"
git push origin v<version>
```

Do **not** call `gh release create` for a patch unless the user explicitly asked — see Stage 5's "explicit-ask" definition.

## Major / Minor — tag + GitHub Release

```bash
git tag -a v<version> -m "Release v<version>"
git push origin v<version>

gh release create v<version> --title "v<version>" --notes "$(cat <<'EOF'
## What's Changed
<grouped changes from commits since last tag>

**Full Changelog**: <compare URL>
EOF
)"
```

## Notes

- `<version>` is the numeric form (e.g. `0.2.0`); the tag adds the leading `v`.
- The `<grouped changes>` section in the release notes should group commits by Conventional Commits type: Features, Fixes, Refactors, Docs, Chores. Source from `git log $LAST_TAG..HEAD --oneline`.
- The `<compare URL>` is `https://github.com/<owner>/<repo>/compare/<previous-tag>...v<version>`.
