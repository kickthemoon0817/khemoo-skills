# Contributing

This repo is built around two skills (`vc-khemoo`, `tasks-khemoo`) that encode the conventions we follow. If you're contributing as a human (not via an AI agent), the same rules apply — they're listed here so you don't need to load the skills to know them.

## Commits

Use Conventional Commits format with **no parenthesized scope**:

```
<type>[!]: <short imperative description>

<optional body explaining why>

<optional footers, e.g. BREAKING CHANGE: ...>
```

- **Type**: short lowercase word. Standard set (`feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`) or domain-specific (`docker`, `sim`, `auth`, etc.).
- **No `(scope)` parens** — `feat(auth):` is forbidden; use `feat:` and put the scope in the description if needed.
- **Breaking change**: `feat!:` + a `BREAKING CHANGE:` footer.

**One concern per commit.** Splitting heuristic: separate commits for different features in different files, formatting/lint fixes, config changes, and anything that doesn't clearly fit. Test + implementation for the same feature → one commit.

## Branches

Don't commit directly to `main`. Branch name: `<type>/<2-4-word-slug>` (e.g. `feat/dry-run-flag`, `fix/empty-diff-handling`). Use `git switch -c <branch>` (not the older `git checkout -b`).

## Pull requests

PR title: `<Type>: <Subject>` with the type capitalized (`Feat: Add --dry-run flag`).

Body should follow the template at `skills/vc-khemoo/references/pr-body-template.md`. The `Release-Note` line decides the version bump — say `none — internal change` if the change isn't user-facing.

## Reviews

Every PR (no matter how small) goes through the 5 core reviewer lenses:

1. Code (logic, contracts, backwards compatibility)
2. Security (OWASP, injection, auth, BOLA)
3. Quality (naming, patterns, anti-patterns)
4. Performance (complexity, memory, latency)
5. Test Engineer (coverage, edge cases)

Plus any specialists triggered by the diff (UI/UX, Design, DevOps, Documentation, Observability, API/Contract, Systems Performance, Security Deep). See `skills/vc-khemoo/SKILL.md` for the trigger table.

## Versioning

Pre-1.0, the bar for minor is **higher**, not lower. Almost all changes are patches:

- **Major**: `BREAKING CHANGE:` footer, `!` after type, or the literal word "breaking" anywhere in commit messages.
- **Minor**: substantial new top-level capability (new top-level command, new full subsystem, new public skill) AND the PR's `Release-Note` would be a release-page headline an end user cares about.
- **Patch**: everything else.

Run `chore: bump to v<x.y.z>` in its own commit, push it before the tag (`git push origin HEAD`), then `git tag -a v<x.y.z>` and `git push origin v<x.y.z>`.

GitHub Releases for major/minor only; patches are tag-only.

## Testing

Skills with executable helpers ship a regression test suite under `skills/<skill>/scripts/test-*.sh`. Make scripts executable (`chmod +x`) and ensure they exit 0 on success.

CI runs:

1. `shellcheck` against every `skills/*/scripts/*.sh` (must pass cleanly — use `# shellcheck disable=SCxxxx` directives only for documented false positives).
2. Every `skills/*/scripts/test-*.sh` discovered via `find`.

Run them locally before pushing:

```bash
# Lint (requires shellcheck)
shellcheck skills/*/scripts/*.sh

# Tests
for t in skills/*/scripts/test-*.sh; do "$t"; done
```

## Tracking work

Quick tasks go in `TODO.md` — bonded to the in-session task list via the `<!-- tasks-khemoo:start -->` … `<!-- tasks-khemoo:end -->` markers. Use the `tasks-khemoo` skill (or the helper script `skills/tasks-khemoo/scripts/todo-md.sh`) to add/done/remove tasks so cosmetic drift doesn't accumulate.

Larger planning entries (multi-step initiatives, design notes) go above the bondable section in `TODO.md` as h2 sections — the bondable section is auto-managed and only touches its own bullets.

## Release history

`CHANGELOG.md` carries the per-version notes. Add an entry for any user-facing change (every patch and above gets one).
