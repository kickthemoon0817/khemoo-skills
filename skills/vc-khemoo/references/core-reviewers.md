# Core Reviewers

Used by Stage 3 of the vc-khemoo pipeline. All 5 are dispatched on every review pass, in parallel, as 5 distinct sessions. There is no "too small to review" exemption.

| Reviewer | Focus | Agent | Model |
|----------|-------|-------|-------|
| Code Reviewer | Logic, architecture, API contracts, backwards compatibility | `code-reviewer` | opus |
| Security Reviewer | Vulnerabilities, auth, injection, trust boundaries | `security-reviewer` | sonnet |
| Quality Reviewer | Naming, patterns, maintainability, anti-patterns | `quality-reviewer` | sonnet |
| Performance Reviewer | Bottlenecks, memory, latency, algorithmic complexity | `quality-reviewer` | opus |
| Test Engineer | Coverage gaps, missing edge cases, test quality | `test-engineer` | sonnet |

`quality-reviewer` is dispatched twice intentionally — once at sonnet for breadth (quality lens) and once at opus for depth (performance lens). Run them as two separate sessions; do not merge.

Each reviewer returns the structured report defined in Stage 3 of SKILL.md.
