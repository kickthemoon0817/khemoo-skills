---
name: tasks-khemoo
description: Use whenever the user wants to add, remove, list, complete, or clean up tasks / TODOs / follow-ups during a Claude Code session. Triggers on phrases like "add a task", "remind me to", "queue this for later", "remove that task", "clean up completed", "what's on my TODO", "/tasks-khemoo …". Enforces queue-only semantics (adding ≠ implementing) and bonds the in-session task list with the project's `TODO.md` so tasks survive across sessions. Invoke this even when the user phrases the request as "remember to do X later", "we should add a TODO for that", or "track this for later" without naming the skill.
---

# Task Management with TODO.md Bonding

## Core principle

**Adding a task is queueing it, not doing it.** When the user says "add a task to ..." or "remind me to ...", record the task and stop. Do not investigate, do not read the codebase, do not edit unrelated files. The user invokes the work later, separately.

## Why bond with TODO.md

The native task tools (`TaskCreate` / `TaskUpdate` / `TaskList`) only persist for the current session. `TODO.md` at the project root persists across sessions and survives in git. Bonding the two means: tasks the user adds now show up next session; tasks the user types into `TODO.md` directly are picked up next time the skill runs.

## Sub-commands

- `/tasks-khemoo` — show the merged task list (in-session + `TODO.md` quick tasks)
- `/tasks-khemoo add <description>` — queue a new task. Records to both places. **Does not start work.**
- `/tasks-khemoo done <id>` — mark a task completed in both
- `/tasks-khemoo remove <id>` — delete a task from both, regardless of its state
- `/tasks-khemoo cleanup` — remove all completed tasks from both
- `/tasks-khemoo sync` — reconcile: pull external `TODO.md` edits into the in-session list and push in-session tasks to `TODO.md`

## TODO.md bondable section

The skill only touches the section of `TODO.md` between these HTML-comment markers. Everything outside the markers (including rich hand-curated h2-per-task planning sections) is preserved untouched.

```markdown
<!-- tasks-khemoo:start -->
## Quick tasks

_Auto-managed by the `tasks-khemoo` skill. Hand-curated content lives above this section; everything between the markers is touched by the skill._

- [ ] task description (added YYYY-MM-DD)
- [x] completed task (added YYYY-MM-DD, done YYYY-MM-DD)
<!-- tasks-khemoo:end -->
```

**What's mutable inside the markers:** only the `- [ ]` / `- [x]` bullet lines. The `## Quick tasks` heading and the italic auto-managed paragraph are part of the bondable structure — preserve them on every write.

If the markers are missing, append the full section template above at the end of `TODO.md` (preserving everything above).

If `TODO.md` does not exist at the project root, create it containing only the bondable section.

## Dates

Use `date +%Y-%m-%d` (or the system date provided in the conversation context) for `(added YYYY-MM-DD)` and `done YYYY-MM-DD` stamps. Do not invent dates from prompt text unless the user explicitly supplies one.

## Operational rules

### `add <description>`

1. **Duplicate check.** Normalize the new description (same rule as `list`); if it matches an existing pending or in-progress task, surface the match and ask `Already queued as #<id>: "<existing>". Add anyway?` Do not add until the user answers.
2. Call `TaskCreate(subject=<short>, description=<full>)` — leaves status `pending`. Capture the returned task id.
3. Append `- [ ] <description> (added <today>)` inside the bondable section of `TODO.md` (create the section if missing).
4. Confirm to the user briefly: `Queued #<id>: <description>.`
5. **Stop.** Do not start implementation. If the description sounds like a single direct command the user wants done now ("rename foo to bar"), pause before step 1 and ask: "Do you want me to do this now, or just queue it?"

### `/tasks-khemoo` (default `list`)

1. `TaskList` for the in-session set.
2. Parse the bondable section of `TODO.md` for the persistent set.
3. **Merge** by normalized description: lowercase + replace each `-`, `_`, `/`, `.` with a single space + collapse runs of whitespace + trim + strip the `(added …)` / `, done …` parentheticals. Tasks whose normalized form matches in both sets are shown once. Tasks only in `TODO.md` are tagged `(TODO.md only)`. Tasks only in-session are tagged `(in-session only)`. If the normalized descriptions match but the raw text differs (cosmetic drift), prefer the `TODO.md` text and note the divergence in the report. For descriptions that almost match but not under this rule (e.g., one has an extra word), do not auto-merge — keep both and flag the near-duplicate so the user can resolve it.
4. Display grouped by status: `pending` → `in_progress` → `completed`. Number rows for use as `<id>` in subsequent commands.

### `done <id>`

1. Resolve `<id>` against the most recently displayed merged list.
2. `TaskUpdate(taskId=<id>, status="completed")` for the in-session task.
3. In `TODO.md`, rewrite the matching line:

   ```
   - [ ] foo (added 2026-05-04)
   ```

   becomes

   ```
   - [x] foo (added 2026-05-04, done 2026-05-04)
   ```

   Insert `, done <today>` immediately before the closing `)`.

### `remove <id>`

1. Resolve `<id>` against the merged list.
2. `TaskUpdate(taskId=<id>, status="deleted")` to remove from the in-session list (`deleted` is a terminal status that drops the task entirely).
3. Delete the matching line from the bondable section of `TODO.md`.
4. Confirm: `Removed: <description>.`

### `cleanup`

1. `TaskList` to find every completed in-session task.
2. Remove each from in-session.
3. Strip every `- [x] ` line from the bondable section of `TODO.md`.
4. Report: `Cleaned up N completed tasks.`

### `sync`

1. Parse the bondable section of `TODO.md` (canonical list).
2. `TaskList` for the in-session set.
3. For each `TODO.md` task not in-session → `TaskCreate` with that description.
4. For each in-session task not in `TODO.md` → append to the bondable section.
5. Report what changed in this exact shape:

   ```
   Synced. Pulled N from TODO.md, pushed M to TODO.md.
   - Pulled: "<description>", "<description>", ...
   - Pushed: "<description>", "<description>", ...
   - Cosmetic drift: <only if any normalized-equal pairs differ in raw text>
   ```

   Omit any line whose list is empty.

## When NOT to use

- The user asks Claude to **do** something right now (`fix this bug`, `write this function`). That's a work request, not a task-add. If ambiguous, ask: "Now or later?"
- The user is mid-flow on an active task — don't interrupt to log it as a new task.
- The user explicitly says "don't track this" — respect it.

## Red flags

- **Never implement a task on `add`.** If you find yourself reading the codebase to "understand" the task before queueing it, stop. The user said add, not do.
- **Never silently merge differences on `sync`.** Always report what was pulled and pushed so the user can spot drift.
- **Never edit outside the markers.** Hand-curated content above or below the bondable section is the user's; it stays untouched.
- **Never delete tasks the user didn't ask to delete.** `cleanup` only removes completed. `remove` requires an explicit `<id>`.
