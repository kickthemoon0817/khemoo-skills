# TODO

Open work items for the `khemoo-skills` repo. Each task captures the user's original framing, the required behaviors, the open design questions, and a recommended kickoff.

---

## 1. Build `tasks-khemoo` skill — Claude Code task management discipline ✅

**Status:** completed (shipped in v0.1.25, 2026-05-04)
**Outcome:** `skills/tasks-khemoo/SKILL.md` + `scripts/{todo-md.sh,test-todo-md.sh,test-markers.sh}`. Queue-only `add`, bondable `TODO.md` via `<!-- tasks-khemoo:start/end -->` markers, normalized merge absorbing `[-_/.]` cosmetic drift. Sub-commands: `add` / `list` / `done` / `remove` / `cleanup` / `sync`. Validated through 5 eval iterations + 13 regression scenarios. See CHANGELOG entries v0.1.25 onward for the full evolution.

---

## 2. Build `setup-khemoo` skill — prompt-caching-friendly project setup ✅

**Status:** completed (shipped in v0.1.62, 2026-05-06)
**Outcome:** `skills/setup-khemoo/SKILL.md` + `scripts/{audit.sh,test-audit.sh}`. Defines 6 disciplines (no history-in-docs, no WHAT-comments, no "removed" markers, no defensive validation past boundaries, no premature abstraction, no restated TL;DRs) and ships a lexical audit for disciplines 1–3. Sub-commands: `audit` / `bootstrap`. SDK-level caching setup deferred to a future iteration.

---

<!-- tasks-khemoo:start -->
## Quick tasks

_Auto-managed by the `tasks-khemoo` skill. Hand-curated content lives above this section; everything between the markers is touched by the skill._

<!-- tasks-khemoo:end -->
