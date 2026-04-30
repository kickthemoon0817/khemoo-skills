# khemoo-skills

Claude Code plugin with version control workflow skills.

## Skills

### `/khemoo-vc` — Version Control Pipeline

End-to-end version control workflow:

1. **Micro-unit commits** — one concern per commit
2. **PR creation** — auto-generated from commits
3. **Multi-role review** — 5 core + 4 specialist subagent reviewers
4. **Resolve & merge** — fix-review loop until all approve
5. **Versioning** — GitHub Releases for major/minor, tags for patches

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
/khemoo-vc              # full pipeline from detected state
/khemoo-vc commit       # micro-unit commit only
/khemoo-vc release patch  # release/tag only
```

## License

MIT
