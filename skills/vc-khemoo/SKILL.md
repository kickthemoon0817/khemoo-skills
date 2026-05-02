---
name: vc-khemoo
description: Use when there are uncommitted changes in the working tree, an unmerged branch with no PR, an open PR awaiting review or with unresolved comments, or merged commits since the last semver tag.
---

# Version Control Pipeline

## Overview

End-to-end version control workflow: micro-unit commits, PR creation, multi-role review with subagents, merge, and semver-based releases/tags.

**Core principle:** Every change flows through commit → PR → review → merge → release. Context detection picks up from wherever you are.

**Announce at start:** "Using vc-khemoo to run the version control pipeline."

## When NOT to Use

- Hotfix branches that bypass review by policy — use the team's hotfix process.
- Submodule or vendored-dependency version bumps that don't change project source — handle manually.
- Force-push, history rewrite, or rebase operations — out of scope; they need explicit user approval anyway.
- Repos without `git` initialized or without a working `gh` (the skill assumes both).

## Context Detection

Before running, detect the current state and start at the **first** stage below whose condition is true. If none match, there is nothing to do.

| Detected state | Start at |
|----------------|----------|
| Uncommitted changes in working tree | Stage 1: Commit |
| Branch ahead of base, no open PR | Stage 2: PR |
| Open PR with no review activity | Stage 3: Review |
| Open PR with unresolved review comments (human or subagent) | Stage 4: Resolve & Merge |
| PR review issues all resolved, not merged | Stage 4: Merge |
| Merged commits since last semver tag | Stage 5: Release |

**Working on the default branch:** If `HEAD` is on `main`/`master` with uncommitted changes, **default to creating a new feature branch automatically** and proceed. Derive the branch name from the dominant change type:

- `feat/<short-slug>` for new features
- `fix/<short-slug>` for bug fixes
- `docs/<short-slug>` for docs-only changes
- `refactor/<short-slug>`, `chore/<short-slug>`, `test/<short-slug>`, etc. for the matching Conventional Commits type

The slug is a 2–4 word summary of the change (e.g. `fix/empty-diff-handling`, `docs/vc-khemoo-bump-rules`). Run `git switch -c <branch>`, announce the branch name, then continue with Stage 1.

Only stop and ask if (a) the user has explicitly said to commit on the default branch for this session, or (b) branch creation fails (e.g., repo policy or permissions). Never silently commit to the default branch.

**Sub-command overrides:**
- `/vc-khemoo` — full pipeline from detected state
- `/vc-khemoo commit` — Stage 1 only
- `/vc-khemoo review [uncommitted|branch|pr]` — Stage 3 only, on the chosen scope (auto-detect if no arg). Standalone: produces the consolidated review report and stops; does not auto-progress to Stage 4.
- `/vc-khemoo release major|minor|patch [--github-release|--tag-only]` — Stage 5 only

## Stage 1: Micro-Unit Commit

**Rule: One concern per commit. No omnibus commits.**

1. Run `git status` and `git diff` to see all changes
2. Analyze changes and group by logical concern (single feature, single fix, single refactor)
3. For each micro-unit:
   - Stage only the files belonging to that concern
   - Write a Conventional Commits message (format below)
   - Commit

**Splitting heuristic:**
- Different files touching different features → separate commits
- Test + implementation for same feature → one commit
- Formatting/lint fixes → separate commit from logic changes
- Config changes → separate from code changes
- **If a change does not fit a listed heuristic, default to splitting.**

**Concern naming:**
- Name the concern by the specific behavior it changes, not by its size or category.
- **Banned generic names:** `cleanup`, `misc`, `polish`, `fixes` (plural), `various`, `wip`, `chore` (when used as the whole concern). Reaching for one of these means the unit is too large — split.

**Commit message format (Conventional Commits, required for Stage 5 bump detection):**
```
<type>[!]: <short imperative description>

<optional body explaining why>

<optional footers, e.g. BREAKING CHANGE: ...>
```

**Type:** one of `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`. **Do not use the parenthesized scope form** (`feat(auth):`, `fix(api):`, etc.) — type alone is enough. If the concern needs more context, put it in the description or the body. Use `!` after the type to mark a breaking change (`feat!:`, `refactor!:`). Use the `BREAKING CHANGE:` footer to describe the break.

**Red flags — stop and re-split:**
- Commit touches 5+ unrelated files
- Message needs "and" to describe the change
- Mix of feature code and unrelated cleanup

## Stage 2: Create PR

1. Determine base branch (`main` or `master`)
2. Verify prerequisites:
   - `HEAD` is on a named branch, not detached. If detached, stop and ask.
   - A remote named `origin` exists (`git remote get-url origin`). If not, stop and ask.
   - `gh auth status` succeeds. If not, instruct the user to run `gh auth login` and stop.
3. Push branch: `git push -u origin <branch>`. If push fails, surface the error verbatim and stop — do not retry blindly.
4. Generate PR body from micro-commit messages
5. Create PR

**PR title and body template** — see `references/pr-body-template.md` for the full title format, capitalized type list, and `gh pr create` invocation. Title is `<Type>: <Subject>`. Body has Summary, Changes, How to Test, **Release-Note** (consumed by Stage 5 for patch-vs-minor), and Checklist. Fill from micro-commit messages and report the PR URL.

## Stage 3: Multi-Role Review

Dispatch **parallel** review subagents. Each reviews a single diff independently. **There is no "too small to review" exemption** — diff size, language, and apparent triviality do not exempt a change from review. Re-runs after fixes also dispatch all core reviewers.

**Review scopes (pick one):**

| Scope | Diff source | Use when |
|-------|-------------|----------|
| `uncommitted` | `git diff HEAD` plus `git diff --cached` | Reviewing pre-commit work; reviewing the working tree before Stage 1 |
| `branch` | `git diff <base>...HEAD` where `<base>` is `main` or `master` | Reviewing a feature branch before opening a PR (Stage 2 not yet done) |
| `pr` | `gh pr diff <pr-number>` | Reviewing an open PR (Stage 2 done) |

**Auto-detect scope** when none is specified:
- In the full pipeline, scope follows whichever stage you arrived at (uncommitted at Stage 1 entry, branch at Stage 2 entry, PR at Stage 3 entry).
- Standalone (`/vc-khemoo review`), pick the most specific scope present: open PR > branch ahead of base > uncommitted changes. If none exist, report "nothing to review" and stop.

**What "fix" means per scope** (when issues are found):
- `uncommitted`: report findings; the user (or Stage 1 on the next pass) folds fixes into the working tree before committing.
- `branch`: fixes become new micro-unit commits on the branch (Stage 1 rules apply); the next pipeline run picks up at Stage 2.
- `pr`: fixes become new micro-unit commits pushed to the PR branch; re-run Stage 3 on the new diff (this is the existing Stage 4 loop).

The reviewer dispatch below is identical regardless of scope — only the diff input changes.

**Core reviewers (always dispatched, 5 distinct sessions):**

| Reviewer | Focus | Agent | Model |
|----------|-------|-------|-------|
| Code Reviewer | Logic, architecture, API contracts, backwards compatibility | `code-reviewer` | opus |
| Security Reviewer | Vulnerabilities, auth, injection, trust boundaries | `security-reviewer` | sonnet |
| Quality Reviewer | Naming, patterns, maintainability, anti-patterns | `quality-reviewer` | sonnet |
| Performance Reviewer | Bottlenecks, memory, latency, algorithmic complexity | `quality-reviewer` | opus |
| Test Engineer | Coverage gaps, missing edge cases, test quality | `test-engineer` | sonnet |

`quality-reviewer` is dispatched twice intentionally — once at sonnet for breadth (quality lens) and once at opus for depth (performance lens). Run them as two separate sessions; do not merge.

**Specialist reviewers** (dispatched when matching files appear in the diff): see `references/specialists/README.md` for the trigger table. Each specialist has its own focused reference file with role-specific checklist and anti-noise guidance — load the matching file when dispatching.

*Surface specialists* (cover lenses the core 5 do not):
- UI/UX → `references/specialists/ui-ux.md`
- Design → `references/specialists/design.md`
- DevOps → `references/specialists/devops.md`
- Documentation → `references/specialists/documentation.md`

*System specialists* (deeper companions to the core reviewers):
- Observability → `references/specialists/observability.md`
- API / Contract → `references/specialists/api-contract.md`
- Systems Performance → `references/specialists/systems-performance.md` (deeper than the core Performance Reviewer)
- Security Deep → `references/specialists/security-deep.md` (deeper than the core Security Reviewer)

Specialists run in parallel alongside the core 5. When a system specialist dispatches, the matching core reviewer still runs — the specialist adds depth, not replacement.

Each reviewer produces a structured report:

```
## [Role] Review

### Issues Found
- **[severity: critical|major|minor]** <description> (file:line)

### Suggestions
- <improvement suggestion>

### Verdict: APPROVE | REQUEST_CHANGES | COMMENT
```

**Aggregate results** (action depends on scope):
- Any `critical` issue → must fix before advancing
- Any `REQUEST_CHANGES` → must address before advancing
- All `APPROVE` with no critical/major → advance:
  - `pr` scope → proceed to Stage 4 (Resolve & Merge)
  - `branch` scope → proceed to Stage 2 (Create PR)
  - `uncommitted` scope → proceed to Stage 1 (Commit)
  - Standalone `/vc-khemoo review` → print the consolidated report and stop

## Stage 4: Resolve & Merge

1. Collect all review findings from Stage 3 **and** any pre-existing comments on the PR. Fetch existing GitHub comments with `gh pr view <pr> --json comments,reviews` and parse them as additional findings.
2. For each issue flagged (subagent or human):
   - Fix the issue as a new micro-unit commit (Stage 1 rules apply)
   - Push fixes to the PR branch
3. If any fixes were made, re-run Stage 3 on the new diff
4. Repeat until all reviewers return `APPROVE` and all human comments are addressed/replied
5. Merge the PR. **Use merge commit (preserves micro-unit history) unless the user explicitly says "squash" for this PR.** "Squash by default" or "team prefers squash" do not count as explicit unless re-stated for this PR.

```bash
# Default — merge commit
gh pr merge <pr-number> --merge --delete-branch

# Only when user explicitly says "squash" for this PR
gh pr merge <pr-number> --squash --delete-branch
```

## Stage 5: Version & Release

Versions follow strict semver `vMAJOR.MINOR.PATCH` (e.g. `v0.1.1`, `v1.0.0`).

**Default rule (no user override):**
- **Major / Minor bump → git tag + GitHub Release**
- **Patch bump → git tag only, no GitHub Release**

The user can override with explicit args: `--github-release` to force a Release, `--tag-only` to suppress one. **"Explicit" means the user typed the flag or the literal words "GitHub release" / "release page".** Importance, security implications, urgency, or inferred intent (e.g. "make sure people see this") do **not** qualify — escalate by asking, not by acting.

**Bump detection (from commits since last semver tag):**

**Default bias: patch.** Most changes are patches. Only bump minor/major when the evidence is unambiguous.

Find the last semver tag and enumerate commits since then:
```bash
LAST_TAG=$(git tag --sort=-v:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | head -1)
git log ${LAST_TAG:+${LAST_TAG}..}HEAD --oneline
```
If `LAST_TAG` is empty (no semver tags exist), the command lists all commits — that is expected for the first release. Use the same `LAST_TAG` everywhere in this stage.

If commits mix levels, take the highest **after** applying the rules below.

| Commit content | Bump |
|----------------|------|
| `BREAKING CHANGE:` footer, or `!` after type (`feat!:`, `refactor!:`) | Major |
| A **substantial** new user-facing capability — large enough to be the headline of release notes (e.g., a new top-level command, a new full subsystem, a new public skill) AND the PR body has a non-empty `Release-Note` line written for end users | Minor |
| Everything else, **including small `feat:` commits** — fixes, docs, refactors, chores, tests, perf, dep bumps, internal helpers, small new options, small new helpers, narrow additive features | Patch |

**The release-headline test (hard rule):** If you cannot write a one-sentence release-note headline that an end user would care about, it is a **patch**. The `Release-Note` line in the PR body is the artifact of this test — if it says "none — internal change", it is a patch.

**Do NOT bump minor for:**
- Renaming an existing skill, command, function, or file (refactor → patch, even if user-visible)
- Adding an internal helper or private function
- Tightening or expanding a doc, error message, or log line
- Adjusting defaults for an existing option
- Refactors that happen to expose an existing capability more clearly
- A `feat:`-prefixed commit whose body shows it was actually a refactor or fix
- A small feature — a new flag on an existing command, a new minor option, a new small helper, a single-line additive change
- **Volume of commits.** Ten `fix:` commits is still a patch. Number of commits never justifies a minor.
- **The presence of the words "add", "new", or `feat:`.** None of these alone justify a minor.
- **Sophistication, hardening, tightening, or refinement of an existing skill, command, or feature** — even if it changes observed behavior. The user-facing surface did not gain a new capability; it got better at what it already did. Examples that are still patches: tighter validation, stricter defaults, new internal sections of a skill doc, anti-rationalization rules, additional edge-case handling, hardening against existing failure modes. None of these are headline-worthy from an end user's perspective.

**0.x phase rule:** While the project version is `v0.x.y`, the bar for minor is *higher*, not lower. Pre-1.0, the surface is still being shaped, so semver is not yet a hard contract — but the discipline matters more, not less. Bump minor only for additions large enough that a downstream user upgrading from `v0.A.x` to `v0.A+1.0` would notice them immediately. Internal sophistication, rule tightening, and discipline improvements are patches. Reserve minor bumps for the kind of change that would warrant a blog post or a top-line changelog entry.

**Confirmation gate (unconditional and synchronous):** Before bumping minor or major, state the proposed bump and the specific commit(s) that justify it, then ask the user to confirm. Patches do not need confirmation.

> Proposing **minor** bump `v0.1.1 → v0.2.0` based on:
> - `feat: add new top-level /vc-khemoo brainstorm pipeline (5 stages)` (new full subsystem)
>
> Confirm, or downgrade to patch?

A general "release it" / "ship it" / "do the release" instruction is **not** confirmation of a bump level. Autonomous modes (autopilot, ralph, ultrawork, etc.) must either downgrade to patch or halt at the gate; they may not self-confirm.

**Also ask before tagging if** any commit since the last tag contains `BREAKING CHANGE`, `!` after the type, or the literal word "breaking" (any case) anywhere in the message. These are signals that the bump may be major regardless of what the bump table says.

When in doubt, bump patch. It is cheap to release another patch later; it is awkward to walk back a premature minor.

**Bump the version:**
1. Read `LAST_TAG` from above. Strip the leading `v` for the numeric version. If empty, start at `0.1.0`.
2. Apply the bump:
   - Major: `X.Y.Z` → `X+1.0.0`
   - Minor: `X.Y.Z` → `X.Y+1.0`
   - Patch: `X.Y.Z` → `X.Y.Z+1`
3. If the project has version files (e.g. `.claude-plugin/plugin.json`, `package.json`, `pyproject.toml`, `Cargo.toml`), update them and commit as `chore: bump to v<version>`. **Push that commit to the remote before tagging:**

```bash
git push origin HEAD
```

Otherwise the tag will reference a commit the remote does not have.

**Run the release commands** — see `references/release-commands.md` for the exact `git tag` / `git push` / `gh release create` invocations. Patch is tag-only; major / minor adds the GitHub Release. Do **not** call `gh release create` for a patch unless the user explicitly asked (per the explicit-ask definition above).

## Common Mistakes

See `references/common-mistakes.md` for problem/fix pairs covering: omnibus commits, skipping review, wrong version bump, premature minor, tag points at missing commit, merging with unresolved issues, and self-confirming a minor in autonomous mode.

## Red Flags

**Never:**
- Commit unrelated changes together
- Commit silently to the default branch
- Merge with `REQUEST_CHANGES` unresolved
- Skip security review
- Force-push without explicit user request
- Squash-merge unless the user explicitly said "squash" for this PR
- Create a release without checking version history
- Self-confirm a minor or major bump in autonomous mode
- Call `gh release create` for a patch without explicit user request

**Always:**
- One concern per commit, named by behavior (not by category)
- Conventional Commits format on every commit
- All 5 core reviewers for every PR, specialists when relevant
- Fix critical issues before merge
- Filter to semver tags (`^v\d+\.\d+\.\d+$`) when reading version history
- Push the version-bump commit before pushing the tag
