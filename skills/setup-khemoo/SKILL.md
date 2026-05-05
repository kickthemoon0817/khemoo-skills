---
name: setup-khemoo
description: Use whenever editing or authoring docs, code, or comments in this project — enforces a leanness regime that keeps stable artifacts stable so the prompt cache compounds across sessions. Triggers on writing/editing markdown, adding code comments, refactoring, removing code, project bootstrap. Also use when the user says "audit my repo for AI-slop patterns", "set up project for AI collaboration", or "/setup-khemoo audit". Invoke this BEFORE editing live docs and BEFORE adding inline comments — it tells you what NOT to do.
---

# Project leanness for cache-friendly AI collaboration

## Why this matters

Prompt caching cuts per-session cost dramatically — but only when stable artifacts (skills, README, settings, conventional code) genuinely don't churn between sessions. The biggest cause of unnecessary churn is *self-explanatory edits*: paper trails, WHAT-comments, "removed" markers, defensive validation, premature abstractions, restated TL;DRs. Each rewrite busts the cache. The 6 disciplines below keep stable artifacts stable.

## Sub-commands

- `/setup-khemoo` — show what the skill enforces (this file)
- `/setup-khemoo audit` — run `scripts/audit.sh`; reports lexical violations of disciplines 1–3 and flags 4–6 for semantic review
- `/setup-khemoo bootstrap` — initialize a starter `CLAUDE.md` at the project root surfacing these disciplines for the project's own agents (no overwrite)

## The 6 disciplines

### 1. No history-in-docs

Live docs describe the present. Drop `(preferred over X)` / `(replaces Y)` / `(introduced in version Z)` / `(was previously done via W)` / `(deprecated in favor of ...)` parentheticals. The reasoning belongs in the commit message; `git blame` finds it for anyone curious.

### 2. No WHAT-comments in code

Comments explain *why* (hidden constraint, subtle invariant, workaround), never *what* (well-named identifiers do that). Forbidden: `// used by X`, `// added for the Y flow`, `// handles the case from issue #123`. Those belong in PR descriptions and rot as the codebase evolves.

### 3. No "removed" markers

When removing code, delete cleanly. No `// removed: ...` markers, no dead exports, no backward-compat shims for code nothing uses. The removal lives in the commit; the file is not a graveyard.

### 4. No defensive validation past trust boundaries

Validate at user input and external-API boundaries only. Don't add guards for "scenarios that can't happen" inside trusted internal code. They are noise that distracts from real validation.

### 5. No premature abstraction

Three similar lines beat a premature helper. No half-finished implementations, no feature flags for code that isn't being shipped. Generalize after the third occurrence, not the first.

### 6. No restated TL;DRs

If a section's first sentence restates the heading, drop it. If a heading restates what the prose under it already says, drop the heading. Restatements are filler that busts the cache when someone "improves" them later.

## Relation to vc-khemoo

`vc-khemoo`'s Red Flags section enforces some of these at commit time (especially around commit-message hygiene). Where the rules overlap, vc-khemoo is the source of truth and `setup-khemoo` cites it. The two skills are complementary, not redundant.

## Audit limitations

The audit script (`scripts/audit.sh`) catches lexical patterns for disciplines 1–3 with high precision. Disciplines 4–6 are conceptual — the script reports them as "needs human/agent semantic review" without trying to detect them by regex. Run a code-review pass (or invoke vc-khemoo's review stage) to catch them.

## Bootstrap

`/setup-khemoo bootstrap` writes a compact `CLAUDE.md` at the project root if none exists. Surfaces the 6 disciplines for any agent working in the project. Idempotent — never overwrites an existing `CLAUDE.md`.
