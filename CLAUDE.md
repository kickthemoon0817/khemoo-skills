# CLAUDE.md

Repo-specific context for Claude sessions. Project conventions live in [CONTRIBUTING.md](./CONTRIBUTING.md); this file holds the highest-value tactical reminders.

## Local verification

Run `./bin/test` for the full lint + regression sweep (matches CI). Skip steps with `--no-lint` or `--no-md` when Docker isn't available.

## Pinned linters

- `koalaman/shellcheck:v0.10.0` for shell
- `davidanson/markdownlint-cli2:v0.13.0` for markdown

Local results only match CI when using these pinned Docker images — a locally-installed shellcheck/markdownlint may surface different findings.

## Versioning is patch-by-default

Minor only for a substantial new top-level capability (new public skill). Pre-1.0 (`v0.x.y`), the bar for minor is *higher*, not lower. Full rule: `skills/vc-khemoo/references/bump-decision.md`. Release ceremony (CHANGELOG entry → 2 separate commits → push HEAD → tag → push tag): see CONTRIBUTING.md.

## Commits

Conventional Commits, **no parenthesized scope** (`feat:` not `feat(auth):`). One concern per commit. Use `git switch -c` (not `checkout -b`).

## Tests auto-discovered

CI and `./bin/test` find every `skills/*/scripts/test-*.sh` by glob. Add a test by dropping a file with that name + `chmod +x`. No workflow edit needed.

## Skill reference loading

`vc-khemoo` and `tasks-khemoo` use progressive disclosure. SKILL.md is always loaded; reference files load on demand per the directives in SKILL.md. Don't load defensively — `bump-decision.md` for example should NEVER load for a patch.

## macOS gotchas

- Default bash is 3.2 — `skills/<x>/scripts/` scripts must work there. CI runs ubuntu-latest with bash 5+ which is allowed `mapfile` etc.
- `cat -A` doesn't work on macOS; use `od -c` to inspect bytes.

## Heredoc backticks

`<<EOF` interprets backticks as command substitution — broke `todo-md.sh` until v0.1.49. Use `<<'EOF'` (single-quoted) when the body contains literal markdown like `` `text` ``.
