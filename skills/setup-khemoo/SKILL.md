---
name: setup-khemoo
description: Bootstrap project or user instructions for Claude Code, Codex, or both. Creates AGENTS.md, optional Claude imports and HUD settings, and project editor/lint configuration without overwriting existing files. Use for setup-khemoo, bootstrap AGENTS.md, or making a project ready for either CLI.
---

# Project + user-config bootstrap for AI collaboration

## Scope and client selection

- `--project` (default): use the git toplevel, or `$PWD` outside a repository.
- `--user`: use each selected client's global instruction directory.
- `--cli claude|codex|both`: select the client; the script defaults to `claude` for compatibility.

When invoked as a skill, honor the user's selected client. Otherwise use the current client (`codex` in Codex, `claude` in Claude Code); use `both` when the user requests both. Pass the client explicitly to the script. Claude Code invokes the skill as `/setup-khemoo`; Codex invokes it as `$setup-khemoo`.

Idempotent — preserves existing files and symlinks. Reports which files were written or skipped.

## What gets written

### Project scope

| File | `claude` | `codex` | `both` |
|---|---|---|---|
| `AGENTS.md` (canonical agent instructions) | Yes | Yes | Shared |
| `CLAUDE.md` (imports `AGENTS.md` via `@AGENTS.md`) | Yes | — | Yes |
| `.claude/settings.json` with HUD `statusLine` | Yes | — | Yes |
| `.claude/scripts/statusline.sh` and `usage-fetch.sh` | Yes | — | Yes |
| `.editorconfig` and `.markdownlint.json` | Yes | Yes | Yes |

Codex reads the project `AGENTS.md` directly. Claude Code's `CLAUDE.md` imports that same file.

### User scope

| Client | Files |
|---|---|
| Claude Code | `~/.claude/AGENTS.md`, `CLAUDE.md`, `settings.json`, and both HUD scripts under `scripts/` |
| Codex | `${CODEX_HOME:-$HOME/.codex}/AGENTS.md` |
| Both | Both sets above, each in its respective directory |

Global instructions are separate files because the clients discover different directories. Updates to one global file do not synchronize the other. Project editor/lint files are project-only. Setup does not install skills or configure Codex models, sandbox settings, or a Claude HUD in Codex.

The Claude HUD uses `statusLine`. `statusline.sh` renders the line; `usage-fetch.sh` refreshes the Anthropic usage caps it displays (5h + weekly), reading OAuth credentials from the macOS Keychain or `~/.claude/.credentials.json`. Both scripts are dependency-free Bash, with internals documented inline. The installed statusline path is written into `settings.json`.

## Running setup

Resolve the script relative to this skill's directory, including when installed through a skill symlink. Run `scripts/setup.sh` with the selected scope and client. Unknown arguments or invalid/missing `--cli` values exit 2 before writing files.

From a checkout of this repository:

```bash
./skills/setup-khemoo/scripts/setup.sh --cli codex        # Codex project
./skills/setup-khemoo/scripts/setup.sh --cli both         # shared project
./skills/setup-khemoo/scripts/setup.sh --user --cli both  # both global directories
```

For every destination, write only when no file or symlink exists. Print `wrote: <path>` or `skip: <path> (exists)`, then the total written/skipped. Preserve existing permissions as well as contents; make only newly installed HUD scripts executable.
