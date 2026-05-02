---
name: vc-khemoo
description: Use when there are uncommitted changes in the working tree, an unmerged branch with no PR, an open PR awaiting review or with unresolved comments, or merged commits since the last semver tag.
---

# Version Control Pipeline

## Overview

**Core principle:** Every change flows through commit → PR → review → merge → release. Context detection picks up from wherever you are.

**Announce at start:** "Using vc-khemoo to run the version control pipeline."

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

**Rule: One concern per commit.**

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

**Commit message format (Conventional Commits, required for Stage 5 bump detection):**
```
<type>[!]: <short imperative description>

<optional body explaining why>

<optional footers, e.g. BREAKING CHANGE: ...>
```

**Type:** A short lowercase word naming the domain or category of the change. Standard categories work (`feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`); domain-specific types are also fine when they explain the change better (`docker`, `sim`, `ros2`, `auth`, `api`, `db`, etc.). One word, lowercase, no punctuation. **Do not use the parenthesized scope form** (`feat(auth):`, `fix(api):`, etc.) — the type alone is enough. Use `!` after the type to mark a breaking change (`feat!:`, `docker!:`). Use the `BREAKING CHANGE:` footer to describe the break.

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

**PR title and body template** — see `references/pr-body-template.md`. The Release-Note line is consumed by Stage 5 for patch-vs-minor. Fill from micro-commit messages and report the PR URL.

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

**Reviewer roster:**

- **Core reviewers (5, always dispatched):** see `references/cores/README.md` for the roster; each reviewer has its own focused file under `references/cores/` with checklist and anti-noise guidance.
- **Specialist reviewers (dispatched when matching files appear in the diff):** see `references/specialists/README.md`.

When a specialist dispatches, the matching core reviewer still runs — the specialist adds depth, not replacement.

**Reviewer report format and aggregation rules:** see `references/review-output.md`.

## Stage 4: Resolve & Merge

1. Collect all review findings from Stage 3 **and** any pre-existing PR comments. Fetch existing GitHub comments with `gh pr view <pr> --json comments,reviews` and parse them as additional findings.

2. **Triage each finding** as fix-now or defer-to-issue:
   - **Fix now (mandatory):** every `critical` issue, every `REQUEST_CHANGES` verdict, every finding inside this PR's stated scope.
   - **Defer to issue:** out-of-scope findings, architectural concerns that need separate design, cross-cutting refactors that would balloon this PR. Major/minor only — never defer `critical` or `REQUEST_CHANGES`.

3. **For each fix-now finding:**
   - Fix as a new micro-unit commit (Stage 1 rules apply)
   - Push fixes to the PR branch
   - Record the (finding, fix-commit-sha) pair for the resolution comment

4. **For each defer-to-issue finding:**
   - Create a GitHub issue using `references/deferred-issue-template.md`
   - Record the (finding, issue-number) pair
   - If the finding came from a human PR comment, reply on the PR explaining the deferral and linking the issue

5. If any fixes were pushed, re-run Stage 3 on the new diff and loop back to step 1.

6. Once all findings are either fixed or deferred, post a single resolution comment on the PR using `references/resolved-findings-comment.md`. List every fixed finding with its fix-commit SHA and every deferred finding with its issue number. Every human PR comment must be replied to (either "fixed in `<sha>`" or "deferred to #`<issue>`").

7. Merge the PR. **Use merge commit (preserves micro-unit history) unless the user explicitly says "squash" for this PR.** "Squash by default" or "team prefers squash" do not count as explicit unless re-stated for this PR.

```bash
gh pr merge <pr-number> --merge --delete-branch
gh pr merge <pr-number> --squash --delete-branch
```

## Stage 5: Version & Release

Versions follow strict semver `vMAJOR.MINOR.PATCH` (e.g. `v0.1.1`).

**Default:** major / minor → git tag + GitHub Release. Patch → git tag only.

**Default bump bias is patch.** For minor/major decisions, the bump table, anti-rationalization rules, the confirmation gate, and the explicit-override definition, see `references/bump-decision.md`. Patches do not need confirmation.

**Find the last semver tag and enumerate commits since then:**
```bash
LAST_TAG=$(git tag --sort=-v:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | head -1)
git log ${LAST_TAG:+${LAST_TAG}..}HEAD --oneline
```

**Apply the bump:**
- Strip the leading `v` from `LAST_TAG` for the numeric version. If empty, start at `0.1.0`.
- Major: `X.Y.Z` → `X+1.0.0`. Minor: `X.Y.Z` → `X.Y+1.0`. Patch: `X.Y.Z` → `X.Y.Z+1`.

**Update version files** (e.g. `.claude-plugin/plugin.json`, `package.json`, `pyproject.toml`, `Cargo.toml`) and commit as `chore: bump to v<version>`. Push the bump commit before tagging so the tag references a SHA the remote has:
```bash
git push origin HEAD
```

**Run the release commands** — see `references/release-commands.md`. Patch is tag-only; major / minor adds the GitHub Release. Do **not** call `gh release create` for a patch unless the user explicitly asked.

## Red Flags

**Never:**
- Commit unrelated changes together
- Commit silently to the default branch
- Merge with `REQUEST_CHANGES` unresolved
- Skip security review
- Force-push without explicit user request
- Squash-merge unless the user explicitly said "squash" for this PR
- Create a release without checking version history
- Bump minor or major for sophistication, hardening, or refinement of an existing feature
- Self-confirm a minor or major bump in autonomous mode
- Call `gh release create` for a patch without explicit user request

**Always:**
- One concern per commit
- Conventional Commits format on every commit
- All 5 core reviewers for every PR, specialists when relevant
- Fix critical issues before merge
- Filter to semver tags (`^v\d+\.\d+\.\d+$`) when reading version history
- Scan commits for `BREAKING CHANGE`, `!`, or "breaking" before tagging — ask before bumping if any match
- Push the version-bump commit before pushing the tag
