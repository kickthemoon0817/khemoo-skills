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

**Working on the default branch:** if `HEAD` is on `main`/`master` with uncommitted changes, **auto-create a feature branch** named `<type>/<slug>` from the dominant change type (`feat`, `fix`, `docs`, `refactor`, `chore`, `test`, etc.) where `<slug>` is a 2–4 word summary (e.g. `fix/empty-diff-handling`). Run `git switch -c <branch>`, announce, continue. Stop and ask only if (a) the user said to commit on the default branch this session, or (b) branch creation fails. Never silently commit to the default branch.

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

**Splitting heuristic** — separate commits for: different features in different files; formatting/lint fixes; config changes; anything that doesn't clearly fit. Test + implementation for the same feature → one commit.

**Commit message format:**
```
<type>[!]: <short imperative description>

<optional body explaining why>

<optional footers, e.g. BREAKING CHANGE: ...>
```

**Type:** short lowercase word — standard categories (`feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`) or domain-specific (`docker`, `sim`, `auth`, `api`, etc.). **No parenthesized scope** (`feat(auth):` etc.) — type alone. Use `!` for breaking changes (`feat!:`); `BREAKING CHANGE:` footer describes the break.

**Red flags — stop and re-split:** 5+ unrelated files; message needs "and"; mix of feature code and unrelated cleanup.

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

Dispatch parallel review subagents. **No "too small to review" exemption** — diff size, language, and triviality do not exempt a change.

**Review scopes:**

| Scope | Diff source |
|-------|-------------|
| `uncommitted` | `git diff HEAD` plus `git diff --cached` |
| `branch` | `git diff <base>...HEAD` (`<base>` = `main` or `master`) |
| `pr` | `gh pr diff <pr-number>` |

**Auto-detect:** in the full pipeline, scope follows the entry stage. Standalone `/vc-khemoo review` picks the most specific present (PR > branch > uncommitted), or stops if none.

**Fix per scope:** `uncommitted` → fold into working tree; `branch` → new micro-unit commits; `pr` → new commits pushed to PR branch + re-run Stage 3 (the Stage 4 loop).

**Reviewer roster** (cores always dispatched; specialists when their trigger matches):

| Reviewer | Agent | Model | Trigger / Focus | Brief |
|----------|-------|-------|-----------------|-------|
| Code | `code-reviewer` | opus | always · logic, architecture, contracts | `cores.md` |
| Security | `security-reviewer` | sonnet | always · OWASP, injection, auth, BOLA | `cores.md` |
| Quality | `quality-reviewer` | sonnet | always · naming, patterns, anti-patterns | `cores.md` |
| Performance | `quality-reviewer` | opus | always · complexity, memory, latency | `cores.md` |
| Test Engineer | `test-engineer` | sonnet | always · coverage, edge cases | `cores.md` |
| UI/UX | `designer` | sonnet | `**/*.{tsx,jsx,vue,svelte}`, components | `specialists/ui-ux.md` |
| Design | `designer` | sonnet | `**/*.{css,scss,sass,less}`, styles, design tokens | `specialists/design.md` |
| DevOps | `build-fixer` | sonnet | `Dockerfile*`, `.github/workflows/**`, `*.tf`, `k8s/**`, `deploy/**` | `specialists/devops.md` |
| Documentation | `writer` | sonnet | `**/*.md`, `docs/**`, public-API surface | `specialists/documentation.md` |
| Observability | `code-reviewer` | sonnet | log / metric / trace SDK calls, observability libs | `specialists/observability.md` |
| API/Contract | `code-reviewer` | opus | `**/api/**`, OpenAPI / GraphQL / proto, exported public types, **new endpoint accepting user-controlled identifiers** | `specialists/api-contract.md` |
| Systems Performance | `code-reviewer` | opus | native code, locks, atomics, hot paths, `bench/**` | `specialists/systems-performance.md` |
| Security Deep | `security-reviewer` | opus | crypto, auth flows, supply-chain, sandboxing, **new endpoint accepting user-controlled identifiers (BOLA surface)** | `specialists/security-deep.md` |

`quality-reviewer` is dispatched twice intentionally (sonnet for Quality, opus for Performance). When a system specialist dispatches, the matching core reviewer still runs — specialist adds depth, not replacement.

**Load only the brief files for reviewers you actually dispatch.** Multiple specialists may dispatch on the same diff; deduplication happens at aggregation time.

**Report format and aggregation:** see `references/review-output.md`.

## Stage 4: Resolve & Merge

1. **Collect findings** — Stage 3 reports plus pre-existing PR comments via `gh pr view <pr> --json comments,reviews`.
2. **Triage** each finding:
   - **Fix now (mandatory):** every `critical` / `REQUEST_CHANGES` / in-scope finding. Each fix is a new micro-unit commit (Stage 1 rules) pushed to the PR branch. Record `(finding, fix-commit-sha)`.
   - **Defer to issue:** out-of-scope, architectural, or cross-cutting only — never `critical` or `REQUEST_CHANGES`. Load `references/deferred-issue-template.md` *only when actually deferring*. Record `(finding, issue-number)`. If from a human comment, reply on the PR linking the issue.
3. **Loop** — push fixes, re-run Stage 3, repeat until all findings are resolved or deferred.
4. **Publish summary** *(only if there are findings to summarize)* — single PR comment via `references/resolved-findings-comment.md`. Reply to every human comment with `fixed in <sha>` or `deferred to #<issue>`. Skip both this step and loading the template if zero findings.
5. **Merge** — `gh pr merge <pr-number> --merge --delete-branch`. Use `--squash` only if the user explicitly says "squash" for this PR.

## Stage 5: Version & Release

Versions follow strict semver `vMAJOR.MINOR.PATCH`. **Default:** major/minor → tag + GitHub Release; patch → tag only. **Default bump is patch — patches need no confirmation, do NOT load `bump-decision.md`.** Load `references/bump-decision.md` *only* when considering a minor or major bump.

**Last tag and commits since:**
```bash
LAST_TAG=$(git tag --sort=-v:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | head -1)
git log ${LAST_TAG:+${LAST_TAG}..}HEAD --oneline
```

**Bump:** strip leading `v` from `LAST_TAG` (start at `0.1.0` if empty). Major: `X.Y.Z → X+1.0.0`. Minor: `X.Y.Z → X.Y+1.0`. Patch: `X.Y.Z → X.Y.Z+1`.

**Version files** (`.claude-plugin/plugin.json`, `package.json`, `pyproject.toml`, `Cargo.toml`, etc.) — bump them, commit `chore: bump to v<version>`, then `git push origin HEAD` BEFORE tagging.

**Release commands:** see `references/release-commands.md`. Do **not** `gh release create` for a patch unless the user explicitly asked.

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
