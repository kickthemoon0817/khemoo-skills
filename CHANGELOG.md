# Changelog

All notable changes to this plugin. Versions follow strict semver `vMAJOR.MINOR.PATCH`. Pre-1.0, the bar for minor is intentionally high — see `skills/vc-khemoo/references/bump-decision.md`.

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
