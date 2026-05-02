# Specialist Reviewers

Dispatched in addition to the 5 core reviewers when matching files appear in the diff. Run in parallel with the core set.

| Reviewer | Focus | Agent | Trigger (file globs / paths) |
|----------|-------|-------|------------------------------|
| UI/UX Reviewer | Usability, interaction flow, accessibility, responsiveness | `designer` (sonnet) | `**/*.{tsx,jsx,vue,svelte}`, `**/components/**`, `**/templates/**` |
| Design Reviewer | Visual consistency, design system adherence, spacing, color | `designer` (sonnet) | `**/*.{css,scss,sass,less}`, `**/styles/**`, design tokens |
| DevOps Reviewer | CI/CD impact, Dockerfile, deployment, infra config | `build-fixer` (sonnet) | `Dockerfile*`, `.github/workflows/**`, `*.tf`, `k8s/**`, `deploy/**` |
| Documentation Reviewer | Docs clarity, API docs, inline comments, README | `writer` (haiku) | `**/*.md`, `docs/**`, public-API surface changes |

## Trigger evaluation

For each specialist, check the diff's changed file paths against the glob set. Dispatch the specialist if any path matches. Multiple specialists may dispatch on the same diff (e.g., a PR that changes both `*.tsx` and `Dockerfile` triggers UI/UX and DevOps).

The specialist uses the same report structure and verdict format as the core reviewers (see Stage 3 in SKILL.md).
