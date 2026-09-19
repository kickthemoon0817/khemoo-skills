---
name: harness-khemoo
description: Set up and operate the harness-khemoo GitHub issue worker through a pinned upstream submodule. Use for harness setup, manual ticks, scheduling, status, stopping, or troubleshooting an autonomous labeled-issue queue; ordinary task recording belongs to tasks-khemoo.
---

# GitHub issue harness

`upstream/` is the [harness-khemoo](https://github.com/kickthemoon0817/harness-khemoo) Git submodule. Its launcher, configuration, prompts, and operational documentation remain maintained there. This skill is the integration layer; do not fork the engine into this plugin.

Invoke as `/harness-khemoo` in Claude Code or `$harness-khemoo` in Codex. Either client can configure and operate it. The upstream worker engine currently invokes `claude -p`; Codex orchestration does not make `CLAUDE_BIN=codex` valid because the CLI flags, model handling, and telemetry differ.

## Commands and routing

- `/harness-khemoo` or `status` — inspect the configured runtime and report queue, logs, and live workers. Without a configured runtime, explain setup requirements.
- `/harness-khemoo setup` — prepare a runtime and project-specific runbook. Setup alone does not launch workers or install cron jobs.
- `/harness-khemoo run` — fire the launcher once for the configured issue queue; one firing can spawn multiple workers.
- `/harness-khemoo start` — schedule recurring firings using the configured interval.
- `/harness-khemoo stop` — remove only this runtime's scheduler entry; let its in-flight workers finish.

Read [upstream/README.md](upstream/README.md) for setup and configuration. For running, scheduling, status, stopping, or recovery, also read [upstream/docs/OPERATIONS.md](upstream/docs/OPERATIONS.md). Before the first sustained run, read [upstream/docs/LESSONS.md](upstream/docs/LESSONS.md). Load [upstream/docs/ARCHITECTURE.md](upstream/docs/ARCHITECTURE.md) only when debugging allocator or coordination behavior.

## Resolve the upstream checkout

Resolve paths relative to this `SKILL.md`, not the user's working directory. Verify `upstream/bin/tick.sh` exists before using it.

In a Git checkout of khemoo-skills, initialize the recorded revision from the plugin root:

```bash
git submodule update --init --recursive -- skills/harness-khemoo/upstream
```

If the installation lacks submodule contents and Git metadata, use a recursive checkout of khemoo-skills. Load it with `claude --plugin-dir /absolute/path/to/khemoo-skills` for Claude Code, or link its skill folders into `.agents/skills` for Codex. Do not silently substitute upstream HEAD: the parent repository pins the integration revision.

## Setup

1. Identify the target checkout, explicit GitHub `owner/repo`, runtime directory, issue/claim labels, work branch, verification commands, and merge policy from the user's request and repository instructions. Ask only for unresolved choices that affect the work. Keep runtime configuration, logs, and locks outside the plugin and target checkout.
2. Check the runtime host has authenticated `claude` and `gh`, Bash 4+, `flock`, and `setsid`. The pinned engine uses Linux utilities; macOS's stock Bash 3.2 is insufficient. Prefer a Linux host for execution. The skill wrapper can be inspected and configured on macOS.
3. Create `bin/`, `config/`, and `prompts/` in the runtime. Link `bin/tick.sh` to the absolute `upstream/bin/tick.sh` path. Copy the upstream environment example to `config/harness.env` and both prompt templates to their corresponding names without `.template`. Preserve existing runtime files; edit them only as required by the requested configuration.
4. Fill every template placeholder. Set `TARGET_REPO` to the absolute target checkout and `GH_REPO` explicitly. Set `HARNESS_PATH` to include the actual tool locations on the runtime host. Choose `MAX_SLOTS` and permission flags deliberately: upstream defaults to eight slots and `--dangerously-skip-permissions`. Preparing files does not authorize unattended execution with those flags.
5. Define measurable verification commands and the allowed issue queue in the runbook. Default to leaving PRs open for review unless the user has authorized merging into a specific scratch branch. Keep protected/shared branches subject to the project's approval rules. Disable unsolicited audit issue creation unless the user requested it.
6. Preserve worktree isolation, one issue per worker, finite batch execution, honest verification evidence, and claim/resource teardown. All workers for a target must share the same state/lock directory on one host; a PID from a different host cannot establish local ownership. Serialize claim selection and labeling with a shared claim lock, then re-read labels under that lock: launch staggering alone does not make claims atomic.
7. Report the runtime paths and resolved configuration. Before an authorized run, ensure the configured labels exist in the explicit target repository. Label creation and worker activity belong to the requested execution scope, not a read-only status check.

The optional usage fetcher/cache from `setup-khemoo` uses the upstream telemetry schema. Reuse it when installed on the runtime host; missing or stale telemetry makes upstream use its conservative concurrency fallback.

## Run and schedule

Use absolute paths and explicitly export `HARNESS_HOME` for each firing. Run from `TARGET_REPO` so GitHub operations have the correct repository context. For example, after resolving the actual paths:

```bash
cd /absolute/path/to/target-repo
HARNESS_HOME=/absolute/path/to/runtime /absolute/path/to/runtime/bin/tick.sh
```

One firing returns after spawning workers; inspect their logs to establish results. A successful launcher exit does not prove that an issue was fixed. Before scheduling, verify a manual firing and review its evidence. Carry the same working directory and `HARNESS_HOME` into the scheduler command, shell-quote paths, and preserve unrelated scheduler entries. Do not change the user's requested interval implicitly.

For stop, edit out only the entry for this runtime. **Do not use upstream's `crontab -r` examples:** they delete unrelated jobs. Observe this runtime's processes and logs while in-flight work drains; do not treat every `claude -p` process on the machine as a harness worker.

For status and recovery, distinguish launch failures, worker failures, exhausted usage, and an empty queue. Scope inspection to this runtime and the configured GitHub repository. Verify an owner is dead before reclaiming a claim or lease; preserve recorded progress so the next worker can resume.

## Maintenance boundary

Engine defects and engine changes belong in [upstream issues](https://github.com/kickthemoon0817/harness-khemoo/issues) and upstream PRs. Wrapper instructions and plugin integration belong in khemoo-skills. File an issue only when requested or authorized by the active workflow.

Update the submodule pointer deliberately after reviewing the upstream revision. Do not patch tracked engine files in the parent repository or advance to upstream HEAD during ordinary setup.
