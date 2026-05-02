# Bump Decision Rules

Used by Stage 5 of the vc-khemoo pipeline. Loaded only when the agent is considering whether a release should be a minor or major bump (vs the patch default).

## Default bias: patch

Most changes are patches. Only bump minor/major when the evidence is unambiguous. **When in doubt, bump patch.**

## Bump table

| Commit content | Bump |
|----------------|------|
| `BREAKING CHANGE:` footer, or `!` after type (`feat!:`, `refactor!:`) | Major |
| A **substantial** new user-facing capability — large enough to be the headline of release notes (e.g., a new top-level command, a new full subsystem, a new public skill) AND the PR body has a non-empty `Release-Note` line written for end users | Minor |
| Everything else — fixes, docs, refactors, chores, tests, perf, dep bumps, internal helpers, small new options, narrow additive features. **Type prefix does not determine bump level** — only the headline test and `!` / `BREAKING CHANGE:` markers do | Patch |

## Release-headline test (hard rule)

If you cannot write a one-sentence release-note headline that an end user would care about, it is a **patch**. The `Release-Note` line in the PR body is the artifact of this test — if it says "none — internal change", it is a patch.

## Do NOT bump minor for

- Renaming an existing skill, command, function, or file (refactor → patch, even if user-visible)
- Adding an internal helper or private function
- Tightening or expanding a doc, error message, or log line
- Adjusting defaults for an existing option
- Refactors that happen to expose an existing capability more clearly
- A `feat:`-prefixed commit whose body shows it was actually a refactor or fix
- A small feature — a new flag on an existing command, a new minor option, a new small helper, a single-line additive change
- **Volume of commits.** Ten `fix:` commits is still a patch. Number of commits never justifies a minor.
- **The presence of the words "add", "new", or `feat:`.** None of these alone justify a minor.
- **Sophistication, hardening, tightening, or refinement of an existing skill, command, or feature** — even if it changes observed behavior. The user-facing surface did not gain a new capability; it got better at what it already did. Examples that are still patches: tighter validation, stricter defaults, new internal sections of a skill doc, anti-rationalization rules, additional edge-case handling, hardening against existing failure modes.

## 0.x phase rule

Bump minor only for additions a downstream user upgrading from `v0.A.x` to `v0.A+1.0` would notice immediately. Reserve minor for changes that would warrant a blog post or a top-line changelog entry.

## Confirmation gate (unconditional and synchronous)

Before bumping minor or major, state the proposed bump and the specific commit(s) that justify it, then ask the user to confirm. Patches do not need confirmation.

> Proposing **minor** bump `v0.1.1 → v0.2.0` based on:
> - `feat: add new top-level /vc-khemoo brainstorm pipeline (5 stages)` (new full subsystem)
>
> Confirm, or downgrade to patch?

A general "release it" / "ship it" / "do the release" instruction is **not** confirmation of a bump level. Autonomous modes (autopilot, ralph, ultrawork, etc.) must either downgrade to patch or halt at the gate; they may not self-confirm.

**Also ask before tagging if** any commit since the last tag contains `BREAKING CHANGE`, `!` after the type, or the literal word "breaking" (any case) anywhere in the message. These are signals that the bump may be major regardless of what the bump table says.

## Explicit user override

The user can override the default release-publication rule with explicit args: `--github-release` to force a Release on a patch, `--tag-only` to suppress a Release on a minor/major.

**"Explicit" means the user typed the flag or the literal words "GitHub release" / "release page".** Importance, security implications, urgency, or inferred intent (e.g. "make sure people see this") do **not** qualify — escalate by asking, not by acting.
