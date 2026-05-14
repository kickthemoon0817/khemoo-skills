# CLAUDE.md

Tactical reminders for Claude sessions in this project.

## Leanness disciplines (cache-friendly AI collaboration)

1. **No history-in-docs.** Live docs describe the present. Drop `(preferred over X)` / `(replaces Y)` / `(introduced in version Z)` parentheticals — the reasoning belongs in the commit.
2. **No WHAT-comments in code.** Comments explain *why* (constraint, invariant, workaround), never *what*. Forbidden: `// used by X`, `// added for the Y flow`, `// handles the case from issue #123`.
3. **No "removed" markers.** Delete cleanly. No `// removed: ...`, no dead exports, no backward-compat shims for code nothing uses.
4. **No defensive validation past trust boundaries.** Validate at user input / external-API boundaries only. No guards for "scenarios that can't happen" inside trusted internal code.
5. **No premature abstraction.** Three similar lines beat a premature helper. Generalize after the third occurrence, not the first.
6. **No restated TL;DRs.** If a section's first sentence restates the heading, drop it.

## Commits

Conventional Commits, **no parenthesized scope** (`feat:` not `feat(auth):`). One concern per commit.
