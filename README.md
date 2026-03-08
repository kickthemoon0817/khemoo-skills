# khemoo-skills

Claude Code plugin with version control workflow skills.

## Skills

### `/khemoo-vc` — Version Control Pipeline

End-to-end version control workflow:

1. **Micro-unit commits** — one concern per commit
2. **PR creation** — auto-generated from commits
3. **Multi-role review** — 4 parallel subagent reviewers (code, security, quality, test)
4. **Resolve & merge** — fix-review loop until all approve
5. **Versioning** — GitHub Releases for major/minor, tags for patches

## Installation

```bash
claude plugin add kickthemoon0817/khemoo-skills
```

## License

MIT
