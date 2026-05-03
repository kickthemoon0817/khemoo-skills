# TODO

Open work items for the `khemoo-skills` repo. Each task captures the user's original framing, the required behaviors, the open design questions, and a recommended kickoff.

---

## 1. Build `tasks-khemoo` skill — Claude Code task management discipline ✅

**Status:** completed (shipped in v0.1.25, 2026-05-04)
**Outcome:** `skills/tasks-khemoo/SKILL.md` + `scripts/{todo-md.sh,test-todo-md.sh,test-markers.sh}`. Queue-only `add`, bondable `TODO.md` via `<!-- tasks-khemoo:start/end -->` markers, normalized merge absorbing `[-_/.]` cosmetic drift. Sub-commands: `add` / `list` / `done` / `remove` / `cleanup` / `sync`. Validated through 5 eval iterations + 13 regression scenarios. See CHANGELOG entries v0.1.25 onward for the full evolution.

---

## 2. Build `setup-khemoo` skill — prompt-caching-friendly project setup

**Status:** pending
**Captured:** 2026-05-02
**Where to start next session:** invoke `superpowers:brainstorming` and walk the open questions below.

### Original user framing (verbatim)

> Also add the setup-khemoo skills at the tasks, which would be setup the prompt caching related one, which would include such as "You're right that this is a recurring AI-agent failure mode — when a doc changes, the temptation is to leave a paper trail of 'what was here before / why it changed' inside the doc itself. That belongs in the commit. The doc just says what to do now." and also the comments inside the codes and so on

### Why this matters

Prompt caching is a key cost lever for AI-collaborative projects: when stable artifacts (skills, docs, README, settings, conventional code) don't churn, the cache stays warm and per-session token cost drops sharply. The biggest cause of unnecessary churn is *self-explanatory edits*: doc paper trails, history parentheticals, WHAT-comments, "removed" markers, defensive validation, premature abstractions. Each of these triggers re-edits over time, busting the cache.

`setup-khemoo` codifies and (where possible) enforces a leanness regime that keeps stable artifacts stable — so the prompt cache compounds with the project.

### Required behaviors

1. **Project bootstrap** — initialize a new project (or audit an existing one) for AI-collaboration discipline. Could write template files, configure SDK-level prompt caching, install pre-commit hooks if relevant.
2. **Discipline enforcement** — define and surface the leanness rules (below) so the agent follows them when authoring or editing code/docs.
3. **Audit mode** — `/setup-khemoo audit` scans existing docs/code for the listed anti-patterns and reports violations.

### Disciplines the skill should encode (initial set)

1. **No history-in-docs.** Never leave `(preferred over X)` / `(replaces Y)` / `(introduced in version Z)` / `(was previously done via W)` parentheticals in live docs. The reasoning belongs in the commit message; `git blame` finds it for anyone curious. (See `~/.claude/projects/-Users-khemoo-ind-khemoo-skills/memory/feedback_no_history_in_docs.md`.)

2. **No WHAT-comments in code.** Comments only explain *why* (hidden constraint, subtle invariant, workaround), never *what* (well-named identifiers do that). Forbidden patterns: `// used by X`, `// added for the Y flow`, `// handles the case from issue #123` — those belong in PR descriptions and rot.

3. **No "removed" markers.** When removing code, delete it cleanly. Don't leave `// removed: ...` markers, dead exports, or backward-compat shims. Tag the removal commit instead.

4. **No defensive validation past system boundaries.** Only validate at user input / external API boundaries. Don't add guards for "scenarios that can't happen" inside trusted internal code.

5. **No premature abstraction / hypothetical futures.** Three similar lines beat a premature helper. No half-finished implementations or feature flags for code that isn't being shipped.

6. **No restated TL;DRs.** Avoid preambles that just restate the title or what's about to be detailed in the next line/section.

(All six mirror principles from the system prompt; the skill makes them discoverable to a project's own agents.)

### Open design questions to resolve before implementing

1. **Scope.** Three plausible shapes: (a) project-bootstrap only (writes templates, configures SDK caching), (b) ongoing-discipline-enforcer only (a skill the agent invokes during work), or (c) both. Recommend (c).

2. **SDK targets.** Which SDKs does the bootstrap mode set up for caching? Claude Agent SDK, Anthropic Python/TS SDK, or auto-detect from `package.json` / `pyproject.toml`?

3. **Enforcement mechanism.** Three layers possible:
   - **Soft:** SKILL.md the agent reads (always cheap, agent-dependent)
   - **Medium:** lint rules (markdownlint custom rules, eslint plugin) — only catches the lexical patterns, not the conceptual ones
   - **Hard:** pre-commit hook that runs the audit and blocks commits with violations

   Recommend starting with soft + a `/setup-khemoo audit` command; add hooks only if the user wants enforcement.

4. **Relation to existing skills.** vc-khemoo already has anti-rationalization rules in Stage 5 and a Red Flags section. Some overlap is unavoidable; the question is whether `setup-khemoo` should *cite* vc-khemoo's rules or *duplicate* them. Recommend cite (link from setup-khemoo to vc-khemoo's Red Flags), so vc-khemoo stays the single source of truth for the rules it enforces.

### Suggested kickoff

Brainstorm via `superpowers:brainstorming` to settle the four open questions, then draft the skill. Likely structure:

- `skills/setup-khemoo/SKILL.md` — the discipline rules, in-context for any agent working in the project.
- `skills/setup-khemoo/references/audit-checklist.md` — the audit-mode checklist (loaded only by `/setup-khemoo audit`).
- `skills/setup-khemoo/references/sdk-caching/` — per-SDK setup snippets (Anthropic Python, Anthropic TS, Claude Agent SDK), loaded only by the corresponding bootstrap path.

This skill will benefit from the same lightweight progressive-disclosure pattern that vc-khemoo iterated toward (v0.1.24).

---

<!-- tasks-khemoo:start -->
## Quick tasks

_Auto-managed by the `tasks-khemoo` skill. Hand-curated content lives above this section; everything between the markers is touched by the skill._

<!-- tasks-khemoo:end -->
