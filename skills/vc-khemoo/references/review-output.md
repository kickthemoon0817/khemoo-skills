# Reviewer Report Format and Aggregation

Used by Stage 3 of the vc-khemoo pipeline. Defines the structured output every reviewer (core or specialist) returns, and how to aggregate verdicts to decide what happens next.

## Per-reviewer report format

```
## [Role] Review

### Issues Found
- **[severity: critical|major|minor]** <description> (file:line)

### Suggestions
- <improvement suggestion>

### Verdict: APPROVE | REQUEST_CHANGES | COMMENT
```

## Aggregate results (action depends on scope)

- Any `critical` issue → must fix before advancing
- Any `REQUEST_CHANGES` → must address before advancing
- All `APPROVE` with no `critical` / `major` → advance:
  - `pr` scope → proceed to Stage 4 (Resolve & Merge)
  - `branch` scope → proceed to Stage 2 (Create PR)
  - `uncommitted` scope → proceed to Stage 1 (Commit)
  - Standalone `/vc-khemoo review` → print the consolidated report and stop
