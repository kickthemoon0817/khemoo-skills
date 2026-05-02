# Specialist Reviewers — Index

Used by Stage 3 of the vc-khemoo pipeline. Specialists run **in parallel** alongside the 5 core reviewers when the diff matches their trigger globs (see each specialist file for exact globs). Multiple specialists may dispatch on the same diff; deduplication happens at aggregation time, not dispatch time.

## Roster

**Surface specialists** (cover lenses the core 5 do not):

- `ui-ux.md` — usability, accessibility, responsive states
- `design.md` — visual consistency, design tokens, spacing
- `devops.md` — Dockerfiles, CI / CD, infra config
- `documentation.md` — docs accuracy, README, public-API surface

**System specialists** (deeper companions to core reviewers):

- `observability.md` — log structure, metrics cardinality, trace propagation
- `api-contract.md` — REST / GraphQL / gRPC contract changes, breaking-vs-additive
- `systems-performance.md` — cache locality, lock contention, syscalls (deeper than core Performance)
- `security-deep.md` — crypto, auth flows, supply-chain (deeper than core Security)

## Dispatch

For each specialist whose globs match any path in the diff:

1. Load the specialist's file
2. Use the agent + model named in that file
3. Pass the diff and the file's checklist
4. Collect the structured report (`../review-output.md`)

When a system specialist dispatches, the matching core reviewer still runs — the specialist adds depth, not replacement.
