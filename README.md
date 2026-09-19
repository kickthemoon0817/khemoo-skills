# khemoo-skills

[![test](https://github.com/kickthemoon0817/khemoo-skills/actions/workflows/test.yml/badge.svg)](https://github.com/kickthemoon0817/khemoo-skills/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)

Shared workflow skills for Claude Code and Codex: version control, task management, project setup, and autonomous GitHub issue work.

> **Status:** pre-1.0 (`v0.x.y`). The skills are stable in shape but the surface may still shift on minor bumps. See [CHANGELOG.md](./CHANGELOG.md) for what's changed lately.

## Skills

Claude Code uses `/skill-name`; Codex uses `$skill-name`. The same `SKILL.md` files power both clients. Client-specific integrations are noted below.

### `/vc-khemoo` — Version Control Pipeline

End-to-end version control workflow:

1. **Micro-unit commits** — one concern per commit (Conventional Commits, no parenthesized scope)
2. **PR creation** — auto-generated from commits with a `Release-Note` line that drives Stage 5
3. **Multi-role review** — 5 core reviewers + up to 8 specialists (UI/UX, Design, DevOps, Documentation, Observability, API/Contract, Systems Performance, Security Deep) dispatched in parallel by file-glob and behavioral triggers
4. **Resolve & merge** — fix-or-defer triage; each fix is a new micro-commit, each deferral becomes a GitHub issue; one published summary comment on the PR
5. **Versioning** — strict semver with patch-by-default discipline; `bump-decision.md` only loaded when minor/major is plausibly on the table

### `/tasks-khemoo` — Task Management with TODO.md Bonding

Queue-only task management. Adding a task does not implement it — the skill records and stops.

- `/tasks-khemoo` — show the merged task list (in-session + `TODO.md` quick tasks)
- `/tasks-khemoo add <description>` — queue a new task (duplicate-checks against existing pending/in-progress)
- `/tasks-khemoo done <id>` / `remove <id>` / `cleanup` — move tasks through their lifecycle in both places
- `/tasks-khemoo sync` — reconcile in-session list with `TODO.md` after external edits

`TODO.md` is bonded via `<!-- tasks-khemoo:start -->` … `<!-- tasks-khemoo:end -->` markers, so tasks survive across sessions and hand-curated content above the markers is preserved untouched.

Claude Code mirrors tasks into its native task list when available. Codex uses the persistent `TODO.md` queue without requiring Claude's task tools.

### `setup-khemoo` — Project and User Setup

Prepare shared `AGENTS.md` instructions and select client-specific files with `--cli claude`, `--cli codex`, or `--cli both`. The script retains `claude` as its default for existing callers. Codex user instructions respect `CODEX_HOME`; the HUD and its usage fetcher are Claude-only.

```bash
./skills/setup-khemoo/scripts/setup.sh --project --cli both
./skills/setup-khemoo/scripts/setup.sh --user --cli codex
```

### `/harness-khemoo` — GitHub Issue Harness

Set up and operate [harness-khemoo](https://github.com/kickthemoon0817/harness-khemoo) through a thin skill wrapper. The engine is a pinned Git submodule at `skills/harness-khemoo/upstream`; engine development and issue tracking stay in its own repository.

- `setup` prepares a separate runtime with project-specific configuration and prompts.
- `run` fires the usage-aware launcher once; `start` schedules recurring firings.
- `status` inspects the queue and runtime; `stop` removes only that runtime's schedule.

Both clients can operate the harness skill. The upstream worker runtime currently runs Claude Code and requires Linux utilities (`flock`, `setsid`), Bash 4+, and authenticated `claude` and `gh`; it does not yet provide a Codex worker backend. Configuration and state live outside the plugin checkout. Setup does not start workers.

## Repo layout

```text
.
├── skills/
│   ├── vc-khemoo/        end-to-end VC pipeline (commit → PR → review → merge → release)
│   │   ├── SKILL.md
│   │   └── references/   per-stage reference material; loaded only when needed
│   │       ├── cores.md, specialists/{8 reviewer briefs}, review-output.md
│   │       ├── pr-body-template.md, release-commands.md
│   │       ├── bump-decision.md (loaded only for minor/major decisions)
│   │       └── resolved-findings-comment.md, deferred-issue-template.md
│   ├── tasks-khemoo/     queue-only task management bonded to TODO.md
│   │   ├── SKILL.md
│   │   └── scripts/
│   │       ├── todo-md.sh         deterministic file-edit primitives
│   │       ├── test-todo-md.sh    13 regression scenarios
│   │       └── test-markers.sh    bondable-section integrity check
│   ├── setup-khemoo/     project and user configuration bootstrap
│   └── harness-khemoo/   integration wrapper for the autonomous issue harness
│       ├── SKILL.md
│       └── upstream/     Git submodule: harness-khemoo
├── bin/test              one-command lint + regression runner (mirrors CI)
├── .github/workflows/    CI: shellcheck + markdownlint + skill regression tests
├── TODO.md               quick tasks bonded via `<!-- tasks-khemoo:start/end -->`
├── CHANGELOG.md, CONTRIBUTING.md, LICENSE
└── .claude-plugin/plugin.json
```

The skills can be invoked separately. `tasks-khemoo` records work, `vc-khemoo` ships it, and `harness-khemoo` operates a labeled GitHub issue queue.

## Installation

### Claude Code

khemoo-skills ships through the `khemoo` Claude Code marketplace at <https://github.com/kickthemoon0817/khemoo-claude-plugins>:

```text
/plugin marketplace add kickthemoon0817/khemoo-claude-plugins
/plugin install khemoo-skills@khemoo
```

For local development (working in this repo directly):

```bash
claude --plugin-dir /path/to/khemoo-skills
```

The harness requires the pinned submodule contents. For a new checkout:

```bash
git clone --recurse-submodules https://github.com/kickthemoon0817/khemoo-skills.git
```

For an existing checkout, run `git submodule update --init --recursive` from the plugin root. If a marketplace installation omits submodules, use the recursive checkout with `claude --plugin-dir` above. The other skills do not require the harness submodule.

### Codex

Clone recursively as above, then link the shared skills from that checkout into Codex's user skill directory. Run this from the khemoo-skills root; existing destinations are preserved:

```bash
mkdir -p "$HOME/.agents/skills"
for skill in vc-khemoo tasks-khemoo setup-khemoo harness-khemoo; do
  target="$HOME/.agents/skills/$skill"
  if [ -e "$target" ] || [ -L "$target" ]; then
    echo "skip: $target (exists)"
  else
    ln -s "$PWD/skills/$skill" "$target"
  fi
done
```

For project-only discovery, use `<project>/.agents/skills` instead. Keep the source checkout available because the links use its scripts, references, and submodule. Codex supports symlinked skill folders and `$skill-name` invocation; see the [official skill documentation](https://learn.chatgpt.com/docs/build-skills). Restart Codex if a newly installed skill does not appear.

## Usage

Inside a Claude Code session:

```
/vc-khemoo                     # full pipeline from detected state
/vc-khemoo commit              # Stage 1 only
/vc-khemoo review [scope]      # Stage 3 only (uncommitted | branch | pr)
/vc-khemoo release patch       # Stage 5 only

/tasks-khemoo                  # list merged in-session + TODO.md tasks
/tasks-khemoo add "<desc>"     # queue a task without implementing
/tasks-khemoo cleanup          # remove all completed tasks
/tasks-khemoo sync             # reconcile after external TODO.md edits

/harness-khemoo setup          # prepare configuration and runbook
/harness-khemoo run            # one launcher firing (may spawn multiple workers)
/harness-khemoo status         # inspect this runtime and its queue
/harness-khemoo stop           # stop future firings; current workers drain
```

In Codex, use the same subcommands with `$` invocation:

```text
$vc-khemoo review branch
$tasks-khemoo add "Investigate the flaky build"
$setup-khemoo --project --cli both
$harness-khemoo status
```

## Release history

See [CHANGELOG.md](./CHANGELOG.md).

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for the conventions (Conventional Commits without parens, branch naming, PR review expectations, semver bump rules, local lint/test commands).

## License

MIT — see [LICENSE](./LICENSE).
