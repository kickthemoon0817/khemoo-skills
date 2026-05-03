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

### Release ceremony

For every release (patch through major), in order:

1. Add an entry at the top of `CHANGELOG.md` under a new `## [<x.y.z>] — YYYY-MM-DD` heading describing what's in the release.
2. Bump the `version` field in `.claude-plugin/plugin.json` to `<x.y.z>`.
3. Commit the CHANGELOG and the bump as **separate** commits:
   ```bash
   git add CHANGELOG.md
   git commit -m "docs: add v<x.y.z> entry to CHANGELOG"
   git add .claude-plugin/plugin.json
   git commit -m "chore: bump to v<x.y.z>"
   ```
4. Push the bump commit *before* tagging so the tag references a SHA the remote has:
   ```bash
   git push origin HEAD
   ```
5. Tag and push the tag:
   ```bash
   git tag -a v<x.y.z> -m "v<x.y.z>: <one-line summary>"
   git push origin v<x.y.z>
   ```
6. **Major / minor only:** create a GitHub Release using `gh release create v<x.y.z> --title "v<x.y.z>" --notes "<changelog body>"`. Patches are tag-only.

If `gh release create` is invoked for a patch by mistake, delete the Release (the tag stays). Patches don't get Release pages by default — that's a deliberate noise-reduction choice (see `skills/vc-khemoo/references/bump-decision.md`).

## Testing

Skills with executable helpers ship a regression test suite under `skills/<skill>/scripts/test-*.sh`. Make scripts executable (`chmod +x`) and ensure they exit 0 on success.

CI runs:

1. `shellcheck` against every `skills/*/scripts/*.sh` (must pass cleanly — use `# shellcheck disable=SCxxxx` directives only for documented false positives).
2. Every `skills/*/scripts/test-*.sh` discovered via `find`.

Run them locally before pushing. CI pins shellcheck via Docker so local results match what CI sees. The one-command path:

```bash
./bin/test
```

This runs the same shellcheck + markdownlint (both pinned via Docker) and the same regression suites that CI does, in the same order. Skip individually with `--no-lint` (shellcheck) or `--no-md` (markdownlint) when Docker isn't available — CI still runs both.

Equivalent manual invocations (path-safe — match what CI does):

```bash
# Lint — uses the same pinned shellcheck version as CI
mapfile -t scripts < <(find skills -type f -path '*/scripts/*.sh' | sort)
docker run --rm -v "$PWD:/repo" -w /repo koalaman/shellcheck:v0.10.0 "${scripts[@]}"

# Tests
mapfile -t tests < <(find skills -type f -path '*/scripts/test-*.sh' -perm -u+x | sort)
for t in "${tests[@]}"; do "$t"; done
```

## Tracking work

Quick tasks go in `TODO.md` — bonded to the in-session task list via the `<!-- tasks-khemoo:start -->` … `<!-- tasks-khemoo:end -->` markers. Use the `tasks-khemoo` skill (or the helper script `skills/tasks-khemoo/scripts/todo-md.sh`) to add/done/remove tasks so cosmetic drift doesn't accumulate.

Larger planning entries (multi-step initiatives, design notes) go above the bondable section in `TODO.md` as h2 sections — the bondable section is auto-managed and only touches its own bullets.

## Release history

`CHANGELOG.md` carries the per-version notes. Add an entry for any user-facing change (every patch and above gets one).
