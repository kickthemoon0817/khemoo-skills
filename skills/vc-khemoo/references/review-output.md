# Reviewer Report Format and Aggregation

Used by Stage 3 of the vc-khemoo pipeline. Defines the per-reviewer report format and how to aggregate verdicts.

## Per-reviewer report format

```
## [Role] Review

### Issues Found
- **[severity: critical|major|minor]** <description> (file:line)

### Suggestions
- <improvement suggestion>

### Verdict: APPROVE | REQUEST_CHANGES | COMMENT
```

## Severity guide (general — applies to all reviewers)

- `critical` — data loss, security exposure, backwards-compat break, broken setup, unresolvable
- `major` — missed important path, hard-to-reverse architectural drift, undocumented public-API change
- `minor` — polish, naming, hardening suggestion, optimization opportunity

## Aggregate results (action depends on scope)

- Any `critical` issue → must fix before advancing
- Any `REQUEST_CHANGES` → must address before advancing
- Zero findings (no issues from any reviewer) → treat as all `APPROVE`
- All `APPROVE` with no `critical` / `major` → advance:
  - `pr` scope → proceed to Stage 4 (Resolve & Merge)
  - `branch` scope → proceed to Stage 2 (Create PR)
  - `uncommitted` scope → proceed to Stage 1 (Commit)
  - Standalone `/vc-khemoo review` → print the consolidated report and stop

## Deduplication

When two reviewers report the same finding (e.g., Code + API/Contract both flag a signature change), keep the most-specific report and note the other reviewer's agreement on its line. Do not double-count for severity gating.
