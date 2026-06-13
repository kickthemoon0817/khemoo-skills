# AGENTS.md

The standard for how AI agents collaborate in this project.

## Major premise

1. A separate agent is spawned only for what a single context cannot provide — **context isolation**, **parallelism**, or **independent review**.
2. The main agent orchestrates: it does trivial work directly and delegates substantial or self-contained chunks to fresh agents.
3. A delegated agent's **task** defines what it does; it reports back a brief result — what was done and what the orchestrator needs to continue, not its full working context.
4. The orchestrator **never approves its own output** — authoring and review are separate passes, in separate contexts.

## How to collaborate

1. **Trivial work, direct.** Delegation has a cost; small in-context edits don't earn a separate agent.
2. **Delegate when it pays off** — to isolate context, to parallelize, or to get an independent reviewer.
3. **Brief the fresh agent.** A delegated agent sees none of the orchestrator's context. Give it a self-contained briefing — one explicit, simple goal; the standards to follow; a brief of the task; and the core context — and nothing more.
4. **Supervise.** Watch a delegated agent's direction as it works; redirect mid-course if it drifts off-goal.
5. **Review separately.** A non-producer judges the work — selectively, at the checkpoints and on the parts that warrant it. No self-approval.
6. **Verify before "done".** Produce evidence the work holds; "should work" is not "works".

## Working disciplines

Code and live docs describe the present, leanly:

1. **No history in docs or comments** — drop "(preferred over X)", "(since vY)"; the why belongs in the commit.
2. **Comments explain why, not what** — a constraint, invariant, or workaround; never a restatement of the code.
3. **No dead code or "removed" markers** — delete cleanly.
4. **Validate at boundaries only** — guard user input and external APIs; trust internal code.
5. **No premature abstraction** — three similar lines beat the wrong helper.
