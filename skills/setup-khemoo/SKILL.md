---
name: setup-khemoo
description: Use whenever editing or authoring docs, code, or comments in this project — enforces a leanness regime that keeps stable artifacts stable so the prompt cache compounds across sessions. Triggers on writing/editing markdown, adding code comments, refactoring, removing code, project bootstrap. Also use when the user says "audit my repo for AI-slop patterns", "set up project for AI collaboration", or "/setup-khemoo audit". Invoke this BEFORE editing live docs and BEFORE adding inline comments — it tells you what NOT to do.
---

# Project leanness for cache-friendly AI collaboration

## Sub-commands

- `/setup-khemoo` — show what the skill enforces (this file)
- `/setup-khemoo audit [--project|--user]` — run `scripts/audit.sh`; reports lexical violations of disciplines 1–3 and flags 4–6 for semantic review
- `/setup-khemoo bootstrap [--project|--user]` — initialize a starter `CLAUDE.md` surfacing these disciplines (no overwrite)

### Scope flags

- `--project` (default): scan/write inside the current project. Resolves to the git toplevel or `$PWD`. Prunes `.git`, `node_modules`, `*-workspace`, this skill itself, and `test-*.sh` fixtures.
- `--user`: scan/write inside `~/.claude/` (user-authored CLAUDE.md, custom skills, custom commands). Prunes third-party plugins, session logs, and caches — those aren't the user's authorship.

Scope only changes *where* the disciplines apply; the discipline rules themselves are the same.

## The 6 disciplines

### 1. No history-in-docs

Live docs describe the present. Drop `(preferred over X)` / `(replaces Y)` / `(introduced in version Z)` / `(was previously done via W)` / `(deprecated in favor of ...)` parentheticals.

### 2. No WHAT-comments in code

Comments explain *why* (hidden constraint, subtle invariant, workaround), never *what* (well-named identifiers do that). Forbidden: `// used by X`, `// added for the Y flow`, `// handles the case from issue #123`.

### 3. No "removed" markers

When removing code, delete cleanly. No `// removed: ...` markers, no dead exports, no backward-compat shims for code nothing uses.

### 4. No defensive validation past trust boundaries

Validate at user input and external-API boundaries only. Don't add guards for "scenarios that can't happen" inside trusted internal code.

### 5. No premature abstraction

Three similar lines beat a premature helper. No half-finished implementations, no feature flags for code that isn't being shipped. Generalize after the third occurrence, not the first.

### 6. No restated TL;DRs

If a section's first sentence restates the heading, drop it. If a heading restates what the prose under it already says, drop the heading.

## Bootstrap

`/setup-khemoo bootstrap` writes a compact `CLAUDE.md` at the project root if none exists. Surfaces the 6 disciplines for any agent working in the project. Idempotent — never overwrites an existing `CLAUDE.md`.
