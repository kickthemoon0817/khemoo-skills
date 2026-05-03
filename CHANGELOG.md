# Changelog

All notable changes to this plugin. Versions follow strict semver `vMAJOR.MINOR.PATCH`. Pre-1.0, the bar for minor is intentionally high — see `skills/vc-khemoo/references/bump-decision.md`.

## [0.1.41] — 2026-05-04

- ci: pinned shellcheck via Docker (`koalaman/shellcheck:v0.10.0`) instead of the runner's default. Prevents future shellcheck rule additions from silently breaking the build when the ubuntu-latest image is updated.

## [0.1.40] — 2026-05-04

- README: cross-linked the new CONTRIBUTING.md and pointed the License section at the LICENSE file (was just bare "MIT").

## [0.1.39] — 2026-05-04

- Added `CONTRIBUTING.md` distilling the conventions baked into vc-khemoo + tasks-khemoo for human contributors who don't have the skills loaded — Conventional Commits with no parenthesized scope, branch-naming rule, PR template + 5-core-reviewers expectation, semver patch bias with explicit minor criteria, local lint/test commands, and how to use `TODO.md`'s bondable section.

## [0.1.38] — 2026-05-04

- Added `LICENSE` file. README has been claiming MIT since v0.1.0 (and `plugin.json` declares it), but the actual LICENSE file was missing — added the standard MIT text with copyright holder "khemoo".

## [0.1.37] — 2026-05-04

- ci: extended `.github/workflows/test.yml` with a shellcheck step that runs against every `skills/*/scripts/*.sh`. Hardened both CI loops to use `mapfile`/quoted arrays so paths with spaces won't break the discovery.
- tasks-khemoo: fixed two real shellcheck warnings in the test script (SC2164 `cd "$WORK"` without `|| exit`, SC1010 `"$HELPER" done` parsed as the `done` keyword); refactored the `ensure_section` helper to avoid SC2094's same-file read+write-in-one-pipeline pattern; added a top-level SC2016 suppression (false positive — awk programs are correctly single-quoted while variables flow through `awk -v`). Both scripts now pass shellcheck-stable cleanly via Docker.

## [0.1.36] — 2026-05-04

- tasks-khemoo: `todo-md.sh` now fails loudly (exit 2, stderr message) when `TODO.md` has a half-broken bondable section (only one of the two markers present). Previously this case was a silent no-op on `add`/`done`/etc., which was a real UX trap. Test suite extended from 9 → 13 cases (added: double-quote round-trip, Unicode round-trip, intra-script dedup behavior, half-broken-section behavior). All passing.

## [0.1.35] — 2026-05-04

- vc-khemoo: Stage 3 now says explicitly that the orchestrator must include the per-reviewer report format from `references/review-output.md` in each reviewer's subagent prompt. Reviewer briefs are scoped to look-for + do-not-flag; without this directive a subagent loading only its own brief wouldn't know what shape to return.

## [0.1.34] — 2026-05-04

- ci: added `.github/workflows/test.yml` that discovers and runs every `skills/*/scripts/test-*.sh` on push to main and on every PR. Catches regressions in the script-backed skills (currently `tasks-khemoo`'s `todo-md.sh`); future skills with similar layout get picked up automatically.

## [0.1.33] — 2026-05-04

- tasks-khemoo: added `scripts/test-todo-md.sh` — regression test suite for `todo-md.sh` covering 9 scenarios (add to non-existent file, append, done flip+stamp, done idempotence, cleanup, list, remove, ensure_section preserves hand-curated content, cleanup-on-empty no-op). All passing. Future sessions can `./scripts/test-todo-md.sh` to verify the helper still behaves correctly after edits.

## [0.1.32] — 2026-05-04

- tasks-khemoo: added `scripts/todo-md.sh` — bash + awk helper that performs `add` / `done` / `remove` / `cleanup` / `list` against the bondable section deterministically. Idempotent at the script level (e.g., `done` skips already-done lines, never appends `, done <today>` twice). SKILL.md now prefers the script over hand-rolled edits, with a fallback to direct edits when bash/awk are unavailable. 7 smoke-test scenarios passed including the previously-buggy `done` twice case.

## [0.1.31] — 2026-05-04

- tasks-khemoo: idempotence audit fixes — `done` now has an explicit guard against re-completing an already-done task (was silently appending `, done <today>` twice and corrupting the TODO.md line); display-ID map invalidation is named (re-run `list` after any mutating command before the next `done`/`remove`); `add` defaults to "do not add" in non-interactive contexts; `sync` collapses intra-set duplicates instead of mirroring them across stores.

## [0.1.30] — 2026-05-04

- tasks-khemoo: `cleanup` now explicitly names `TaskUpdate(status="deleted")` (was vague "Remove each from in-session"), matching the `remove` rule. Added a "Display IDs vs in-session task IDs" clarification to `list` so `done`/`remove` know to map the user-visible display number back to the underlying in-session task ID.

## [0.1.29] — 2026-05-04

- vc-khemoo: prefix all reviewer-roster `Brief` cells with the full `references/` path so SKILL.md is internally consistent with the prose convention used elsewhere (was: bare `cores.md` / `specialists/X.md` resolving relative to an implicit directory).

## [0.1.28] — 2026-05-04

- README.md refreshed: now covers both skills (vc-khemoo + tasks-khemoo) with current sub-command surface, accurate specialist count (8), and a link to CHANGELOG.

## [0.1.27] — 2026-05-04

- Added `CHANGELOG.md` with release history from `v0.1.0` through the current tag.

## [0.1.26] — 2026-05-04

- Tasks-khemoo: tightened `add` (duplicate-check + return task ID), `done` (explicit before/after example), `remove` (concrete `TaskUpdate(status="deleted")`), `sync` (structured Pulled/Pushed/Cosmetic-drift report).

## [0.1.25] — 2026-05-04

- Added `tasks-khemoo` skill: queue-only task management with `TODO.md` bonding via `<!-- tasks-khemoo:start/end -->` markers. Sub-commands `add`, `list`, `done`, `remove`, `cleanup`, `sync`. Validated through 3 iterations of test scenarios.
- Patch bump (autonomous-mode downgrade from minor candidate per the confirmation gate).

## [0.1.24] — 2026-05-03

- vc-khemoo: inlined patch-default rule in Stage 5 so `bump-decision.md` is loaded only for plausibly-minor decisions; marked `pr-body-template.md` as always required at Stage 2. Fixes the iter-5 over-prune regression where subagents invented their own PR template and lost confidence in patch defaults.

## [0.1.23] — 2026-05-03

- vc-khemoo: added explicit "do NOT load X unless Y" directives in Stage 4 (deferred-issue-template, resolved-findings-comment) and Stage 5 (bump-decision) to deter defensive loads. Surfaced two regressions later fixed in v0.1.24.

## [0.1.22] — 2026-05-03

- vc-khemoo: tightened Context Detection default-branch block, removed redundant Stage 4 bash, compacted Stage 5 prose. SKILL.md 184 → 161 lines.

## [0.1.21] — 2026-05-03

- vc-khemoo: tightened Stage 1 / Stage 3 / Stage 4 prose. SKILL.md 213 → 184 lines.

## [0.1.20] — 2026-05-03

- vc-khemoo: folded the 5 separate `cores/` files into a single `cores.md` (87 → 33 lines). One file load instead of five at Stage 3 dispatch.

## [0.1.19] — 2026-05-03

- vc-khemoo: lightweight pass — dropped `cores/README.md` and `specialists/README.md`; compacted each of 13 reviewer files (5 cores + 8 specialists) to ~17–21 lines each by stripping per-file headers, Focus prose, and Output severity boilerplate; moved the generic severity guide into `review-output.md`; added behavioral BOLA trigger for security-deep + api-contract.

## [0.1.18] — 2026-05-03

- vc-khemoo: split core reviewers into per-role files with focused checklists; compacted `pr-body-template.md`, `specialists/README.md`, `review-output.md`.

## [0.1.17] — 2026-05-03

- vc-khemoo: compacted `bump-decision.md` (55 → 36 lines).

## [0.1.16] — 2026-05-03

- vc-khemoo: extracted Stage 5 bump-decision rules to `references/bump-decision.md` (loaded only when considering minor/major).

## [0.1.15] — 2026-05-03

- vc-khemoo: added Stage 4 fix-or-defer triage with auto-published review summary on the PR and auto-created GitHub issues for deferred findings.

## [0.1.14] — 2026-05-03

- vc-khemoo: extracted reviewer report format and aggregation rules to `references/review-output.md`.

## [0.1.13] — 2026-05-03

- vc-khemoo: extracted core reviewer roster to `references/core-reviewers.md`.

## [0.1.12] — 2026-05-03

- vc-khemoo: loosened Stage 1 type and concern-naming rules — domain-specific commit types (`docker`, `sim`, `ros2`, etc.) are now valid alongside Conventional Commits standard set; "Type prefix does not determine bump level" added to the patch row; dropped Concern naming section (chore-as-whole-concern ban contradicted the established `chore: bump to v0.1.x` pattern).

## [0.1.11] — 2026-05-03

- vc-khemoo: consolidated `When NOT to Use` + `Common Mistakes` into Red Flags. Removed `references/common-mistakes.md`.

## [0.1.10] — 2026-05-03

- vc-khemoo: applied 14 leanness refinements per strict audit pass.

## [0.1.9] — 2026-05-03

- vc-khemoo: dropped redundant Overview preamble.

## [0.1.8] — 2026-05-03

- vc-khemoo: stripped history parenthetical from `git switch -c` recommendation; saved as feedback memory to deter the same anti-pattern in future sessions.

## [0.1.7] — 2026-05-03

- vc-khemoo: switched recommended branch creation from `git checkout -b` to `git switch -c`.

## [0.1.6] — 2026-05-03

- vc-khemoo: documentation reviewer model upgraded from haiku to sonnet; markdownlint MD032 fixes on three specialist files.

## [0.1.5] — 2026-05-03

- vc-khemoo: added 4 deeper specialist reviewers (observability, api-contract, systems-performance, security-deep). System specialists are deeper companions to core reviewers, not replacements.

## [0.1.4] — 2026-05-03

- vc-khemoo: split specialist reviewers into per-role reference files with focused checklists.

## [0.1.3] — 2026-05-03

- vc-khemoo: extracted reference material to `references/` directory (PR body template, release commands, common mistakes, specialist reviewers).

## [0.1.2] — 2026-05-03

- vc-khemoo: tightened bump rules and added prerequisites, anti-rationalization, 0.x phase, review scopes, branch defaulting, and Conventional Commits clauses per multi-agent review.

## [0.1.1] — 2026-05-03

- Renamed skill: `khemoo-vc` → `vc-khemoo`.
- Plugin works for the new identifier and the rename is reflected throughout SKILL.md and README.md.

## [0.1.0] — 2026-03-08

- Initial release: vc-khemoo skill for end-to-end version control workflow (commit, PR, multi-role review, merge, semver release).
