# Specialist Reviewers — Index

Used by Stage 3 of the vc-khemoo pipeline. Specialists run **in parallel** alongside the 5 core reviewers when the diff matches their trigger globs. Multiple specialists may dispatch on the same diff.

## Trigger table

| Specialist | Reference file | Trigger globs / paths |
|------------|----------------|------------------------|
| UI/UX | `ui-ux.md` | `**/*.{tsx,jsx,vue,svelte}`, `**/components/**`, `**/templates/**` |
| Design | `design.md` | `**/*.{css,scss,sass,less}`, `**/styles/**`, design tokens |
| DevOps | `devops.md` | `Dockerfile*`, `.github/workflows/**`, `*.tf`, `k8s/**`, `deploy/**` |
| Documentation | `documentation.md` | `**/*.md`, `docs/**`, public-API surface changes |

## How to dispatch

For each specialist whose globs match any path in the diff:

1. Load the specialist's reference file (e.g. `references/specialists/ui-ux.md`)
2. Use the agent + model named in that file
3. Pass the diff and the specialist's checklist as the prompt
4. Collect the structured report (same format as core reviewers — see Stage 3 in SKILL.md)

Specialists are scoped narrowly on purpose. If two specialists could plausibly cover the same finding, both should run; deduplication happens at aggregation time, not dispatch time.
