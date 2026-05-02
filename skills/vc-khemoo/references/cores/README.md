# Core Reviewers — Index

Used by Stage 3 of the vc-khemoo pipeline. All 5 are dispatched in parallel on every review pass, as 5 distinct sessions. There are no triggers — every diff goes through every core reviewer. There is no "too small to review" exemption.

| Reviewer | Reference file | Agent | Model |
|----------|----------------|-------|-------|
| Code Reviewer | `code-reviewer.md` | `code-reviewer` | opus |
| Security Reviewer | `security-reviewer.md` | `security-reviewer` | sonnet |
| Quality Reviewer | `quality-reviewer.md` | `quality-reviewer` | sonnet |
| Performance Reviewer | `performance-reviewer.md` | `quality-reviewer` | opus |
| Test Engineer | `test-engineer.md` | `test-engineer` | sonnet |

`quality-reviewer` is dispatched twice intentionally — once at sonnet for breadth (Quality lens) and once at opus for depth (Performance lens). Run them as two separate sessions; do not merge.

Report format and aggregation rules: see `../review-output.md`.
