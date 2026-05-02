# Common Mistakes

Recurring failure modes the vc-khemoo pipeline is designed to prevent. Each entry is a problem/fix pair.

## Omnibus commits

- **Problem:** One commit with 10 unrelated changes.
- **Fix:** Split by concern. If the message needs "and", split it. (Stage 1 splitting heuristic.)

## Skipping review

- **Problem:** Merge without multi-role review.
- **Fix:** Always run all 5 core reviewers. Dispatch specialists when changes warrant them. There is no "too small to review" exemption.

## Wrong version bump

- **Problem:** Tagging a breaking change as patch.
- **Fix:** Before tagging, scan commits for `BREAKING CHANGE`, `!` after the type, or the literal word "breaking" — if any match, ask before tagging.

## Premature minor

- **Problem:** Bumping `v0.1.1 → v0.2.0` for a small additive change.
- **Fix:** Apply the release-headline test. If you cannot write a one-sentence headline a user would care about, it is a patch. While in `0.x.y`, the bar is even higher.

## Tag points at missing commit

- **Problem:** Tagging the local version-bump commit before pushing it, so the remote tag references a SHA the remote does not have.
- **Fix:** `git push origin HEAD` before `git push origin v<version>`.

## Merging with unresolved issues

- **Problem:** Critical issues ignored.
- **Fix:** Fix-and-review loop until all reviewers return `APPROVE`.

## Self-confirming a minor or major in autonomous mode

- **Problem:** An autopilot/ralph/ultrawork loop interprets "release it" as approval to bump minor.
- **Fix:** Autonomous modes must downgrade to patch or halt at the confirmation gate. A general "release" instruction is never approval of a specific bump level.
