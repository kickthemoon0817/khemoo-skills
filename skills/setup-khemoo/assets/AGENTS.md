# AGENTS.md

The standard for how AI agents collaborate in this project.

## Major premise

Any substantial task is divided by **domain of expertise**, and each domain is handed to the agent that owns it. The main agent orchestrates: it handles trivial work directly, delegates substantial or specialized work to the domain's owner, and **never approves its own output**.

Operation is supervised, not fire-and-forget. While an agent works, the orchestrator watches its direction and keeps intervention open — redirect mid-course when the work drifts off-goal, rather than waiting for a finished result to reject. Review is dispatched selectively — at the checkpoints and on the parts that warrant it — and always to an agent that did not produce the work; authoring and review never share a context.

Each agent is **dual-purpose**: it *operates* in its domain (does the work) and *reviews* in its domain (judges another agent's work).

## The agent stack

Delegate to the agent whose domain the task falls in:

- **code-reviewer** — logic correctness, architecture, API contracts, backwards compatibility
- **security-reviewer** — the OWASP Top 10: injection, auth, secrets, trust boundaries
- **quality-reviewer** — naming, patterns, anti-patterns, dead code, DRY
- **test-engineer** — coverage, edge cases, test quality and determinism
- **designer** — UI/UX, accessibility, responsive states, visual design
- **build-fixer** — CI/CD, Dockerfiles, infrastructure config
- **writer** — documentation accuracy, public-API doc coverage

## How to collaborate

1. **Scope first.** For anything non-trivial, understand the task before acting.
2. **Delegate, then supervise.** Hand specialized work to its domain owner; watch the direction as it proceeds and redirect mid-course if it drifts.
3. **Review selectively.** A domain agent that did not produce the work reviews it — at the checkpoints and on the parts that warrant it, not only at the end.
4. **Verify before "done".** Produce evidence the work holds — tests, a build, a check against the source. "Should work" is not "works".
5. **Parallelize.** Independent domains with no shared state run concurrently.

## Working disciplines

Code and live docs describe the present, leanly:

1. **No history in docs or comments** — drop "(preferred over X)", "(since vY)"; the why belongs in the commit.
2. **Comments explain why, not what** — a constraint, invariant, or workaround; never a restatement of the code.
3. **No dead code or "removed" markers** — delete cleanly.
4. **Validate at boundaries only** — guard user input and external APIs; trust internal code.
5. **No premature abstraction** — three similar lines beat the wrong helper.
