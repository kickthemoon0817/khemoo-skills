# Bump Decision Rules

Used by Stage 5 when considering minor or major (vs the patch default).

## Bump table

| Markers in commits since last tag | Bump |
|-----------------------------------|------|
| `BREAKING CHANGE:` footer or `!` after the type | Major |
| Substantial new user-facing capability AND PR body has a non-empty `Release-Note` line — passes the **release-headline test**: one sentence an end user would care about | Minor |
| Anything else | Patch |

Type prefix does not determine bump level. Volume of commits does not justify a minor. Words like "add", "new", `feat:` alone do not justify a minor.

## Patch by default

These are **always** patches, even when they look additive or change observed behavior:

- Renames, internal helpers, doc/error/log tweaks, default adjustments, refactors that expose existing capability
- Small features: new flag, minor option, new small helper, single-line additive change
- Sophistication, hardening, tightening, or refinement — the user-facing surface didn't gain a new capability, it got better at what it already did
- `feat:`-prefixed commits whose body shows they were actually refactors or fixes

## 0.x phase

The bar is *higher*, not lower. Bump minor only for additions a downstream user upgrading from `v0.A.x` to `v0.A+1.0` would notice immediately — changes that warrant a blog post or top-line changelog entry.

## Confirmation gate

Before bumping minor or major, state the proposed bump + the justifying commit(s) and ask the user. Patches do not need confirmation. "Release it" / "ship it" is **not** confirmation of a bump level — autonomous modes (autopilot, ralph, ultrawork) must downgrade to patch or halt.

**Also ask** if any commit since the last tag contains `BREAKING CHANGE`, `!` after the type, or the literal word "breaking" — these may be major regardless of the table.

## Explicit Release override

The user can force `--github-release` on a patch or `--tag-only` on a minor/major. **"Explicit"** means the typed flag or the literal words "GitHub release" / "release page". Importance, security, urgency, or inferred intent do **not** qualify — escalate by asking, not by acting.
