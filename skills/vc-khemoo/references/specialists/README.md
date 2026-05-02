# Specialist Reviewers — Index

Used by Stage 3 of the vc-khemoo pipeline. Specialists run **in parallel** alongside the 5 core reviewers when the diff matches their trigger globs. Multiple specialists may dispatch on the same diff.

## Trigger table

### Surface specialists

| Specialist | Reference file | Trigger globs / paths |
|------------|----------------|------------------------|
| UI/UX | `ui-ux.md` | `**/*.{tsx,jsx,vue,svelte}`, `**/components/**`, `**/templates/**` |
| Design | `design.md` | `**/*.{css,scss,sass,less}`, `**/styles/**`, design tokens |
| DevOps | `devops.md` | `Dockerfile*`, `.github/workflows/**`, `*.tf`, `k8s/**`, `deploy/**`, `Makefile`, `.gitlab-ci.yml`, `bitbucket-pipelines.yml` |
| Documentation | `documentation.md` | `**/*.md`, `docs/**`, public-API surface changes |

### System specialists

| Specialist | Reference file | Trigger globs / paths |
|------------|----------------|------------------------|
| Observability | `observability.md` | `**/logger*`, `**/metrics/**`, `**/tracing/**`, OpenTelemetry / Sentry / Prometheus SDK calls, any diff that adds/removes log or metric emissions |
| API / Contract | `api-contract.md` | `**/openapi.{yaml,json}`, `*.proto`, `*.graphql`, `**/routes/**`, `**/controllers/**`, `**/handlers/**`, public type exports |
| Systems Performance | `systems-performance.md` | `*.{c,cpp,rs,zig,go}`, `unsafe` blocks, lock primitives, atomics, hot-path code (parsers, codecs, math kernels), `bench/**`, `// perf-critical` markers |
| Security Deep | `security-deep.md` | `**/crypto/**`, `**/auth/**`, `**/sessions/**`, `**/oauth/**`, JWT / OAuth / signature-verification code, secret managers, sandbox / isolation code, supply-chain surface (postinstall, build-time exec) |

## How to dispatch

For each specialist whose globs match any path in the diff:

1. Load the specialist's reference file (e.g. `references/specialists/ui-ux.md`)
2. Use the agent + model named in that file
3. Pass the diff and the specialist's checklist as the prompt
4. Collect the structured report (same format as core reviewers — see Stage 3 in SKILL.md)

Specialists are scoped narrowly on purpose. If two specialists could plausibly cover the same finding, both should run; deduplication happens at aggregation time, not dispatch time.

## Relation to core reviewers

When a system specialist dispatches, the matching core reviewer still runs — the specialist adds depth, not replacement.
