# Documentation Reviewer

## Look for

- Code/docs drift: examples compile/run; CLI flag docs match `--help`; HTTP route docs match the actual routes; config keys in docs match what code reads
- Setup steps: README install/run instructions work end-to-end on a clean machine
- Cross-references: internal links resolve; relative paths point at existing files; anchors match real headings
- Public API docs: every new exported function / CLI flag / HTTP route / config key has at least one sentence of what + when
- Version-specific docs land in the right version's directory
- Inline comments explain WHY, not WHAT
- README badges and metadata match reality

## Do NOT flag

- Prose style / sentence length unless it actively misleads
- Markdown formatting nits that don't affect rendering
- Algorithm-explanation comments inside source → Code
