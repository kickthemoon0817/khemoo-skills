# khemoo-skills

[![test](https://github.com/kickthemoon0817/khemoo-skills/actions/workflows/test.yml/badge.svg)](https://github.com/kickthemoon0817/khemoo-skills/actions/workflows/test.yml)

Claude Code plugin with focused workflow skills for version control and task management.

> **Status:** pre-1.0 (`v0.x.y`). The skills are stable in shape but the surface may still shift on minor bumps. See [CHANGELOG.md](./CHANGELOG.md) for what's changed lately.

## Skills

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
│   └── tasks-khemoo/     queue-only task management bonded to TODO.md
│       ├── SKILL.md
│       └── scripts/
│           ├── todo-md.sh         deterministic file-edit primitives
│           ├── test-todo-md.sh    13 regression scenarios
│           └── test-markers.sh    bondable-section integrity check
├── bin/test              one-command lint + regression runner (mirrors CI)
├── .github/workflows/    CI: shellcheck + markdownlint + skill regression tests
├── TODO.md               quick tasks bonded via `<!-- tasks-khemoo:start/end -->`
├── CHANGELOG.md, CONTRIBUTING.md, LICENSE
└── .claude-plugin/plugin.json
```

The two skills are independent and can be invoked separately. `tasks-khemoo` is helpful while drafting work; `vc-khemoo` ships it.

## Installation

khemoo-skills ships through the `khemoo` Claude Code marketplace at <https://github.com/kickthemoon0817/khemoo-claude-plugins>:

```text
/plugin marketplace add kickthemoon0817/khemoo-claude-plugins
/plugin install khemoo-skills@khemoo
```

For local development (working in this repo directly):

```bash
claude --plugin-dir /path/to/khemoo-skills
```

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
```

## Release history

See [CHANGELOG.md](./CHANGELOG.md).

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for the conventions (Conventional Commits without parens, branch naming, PR review expectations, semver bump rules, local lint/test commands).

## License

MIT — see [LICENSE](./LICENSE).
