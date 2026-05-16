---
name: setup-khemoo
description: Use whenever the user wants to bootstrap a project (or their user-global Claude config) for AI collaboration — sets up `CLAUDE.md`, `.claude/settings.json`, `.editorconfig`, `.markdownlint.json`, and a curated agent stack at `.claude/agents/`. Triggers on "set up this project for Claude", "bootstrap CLAUDE.md", "install the agent stack", "/setup-khemoo", or when the user starts a new project that needs the standard scaffolding. Invoke even when the user phrases the ask casually ("get this repo Claude-ready", "drop in the usual configs").
---

# Project + user-config bootstrap for AI collaboration

## Sub-commands

- `/setup-khemoo` — full setup at project scope (default)
- `/setup-khemoo --project` — explicit project scope (same as default)
- `/setup-khemoo --user` — full setup at user scope (`~/.claude/`)

Idempotent — never overwrites existing files. Reports which files were written vs skipped because they already exist.

## What gets written

### Workspace files

| File | `--project` (default) | `--user` |
|---|---|---|
| `CLAUDE.md` (tactical reminders + leanness disciplines) | `<root>/CLAUDE.md` | `~/.claude/CLAUDE.md` |
| Claude Code settings (with HUD `statusLine` wired up) | `<root>/.claude/settings.json` | `~/.claude/settings.json` |
| HUD statusline script | `<root>/.claude/scripts/statusline.sh` | `~/.claude/scripts/statusline.sh` |
| HUD usage fetcher | `<root>/.claude/scripts/usage-fetch.sh` | `~/.claude/scripts/usage-fetch.sh` |
| `.editorconfig` | `<root>/.editorconfig` | — (project-only) |
| `.markdownlint.json` | `<root>/.markdownlint.json` | — (project-only) |

`<root>` is the git toplevel, or `$PWD` if not inside a git repo.

The HUD is wired up via Claude Code's `statusLine` setting. `statusline.sh` renders the line; `usage-fetch.sh` refreshes the Anthropic usage caps it displays (5h + weekly), reading OAuth credentials from the macOS Keychain or `~/.claude/.credentials.json`. Both are dependency-free bash; the statusline path is baked into `settings.json` at install time so it resolves regardless of cwd. Internals documented inline in each script.

### Agent stack

A curated set of subagent configs that match `vc-khemoo`'s Stage 3 reviewer roster. Written to:

- `<root>/.claude/agents/<name>.md` for `--project`
- `~/.claude/agents/<name>.md` for `--user`

Agents installed:

- `code-reviewer` — logic, architecture, API contracts, backwards compatibility
- `security-reviewer` — OWASP-Top-10 surface
- `quality-reviewer` — naming, patterns, anti-patterns
- `test-engineer` — coverage, edge cases, test quality
- `designer` — UI/UX + visual design
- `build-fixer` — CI/CD, Dockerfiles, infra
- `writer` — docs clarity, API docs

The agent files are minimal identity stubs; role-specific briefs for each reviewer live in `vc-khemoo`'s reference files and are loaded at dispatch time.

## Operational rules

1. Resolve scope (`--project` default, `--user` if flag passed). Reject unknown args with exit 2.
2. Resolve target root (`$HOME/.claude` for user, git toplevel or `$PWD` for project).
3. For each file in the scope-appropriate set: write only if the destination does not exist. Print `wrote: <path>` or `skip: <path> (exists)`.
4. Report total written / skipped at the end.

The script implementation lives at `scripts/setup.sh`. Run it directly:

```bash
./skills/setup-khemoo/scripts/setup.sh           # project scope
./skills/setup-khemoo/scripts/setup.sh --user    # user scope
```
