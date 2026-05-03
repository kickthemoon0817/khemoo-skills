# Core Reviewers

The 5 always-dispatched reviewers. Run in parallel as 5 distinct sessions. There is no "too small to review" exemption.

## Code Reviewer (`code-reviewer`, opus)

**Look for:** logic correctness (edge cases, null / empty / zero / negative inputs, off-by-one, overflow); async / concurrency (missing `await`, races, lost cancellation, deadlock); error handling (caught + ignored vs surfaced; types preserved across boundaries; no silent fallbacks); API contracts (signatures, return / thrown types — consumers still compile); architecture (module boundaries, no new circular deps); backwards compatibility (additive only); resource management (close on every path).

**Do NOT flag:** naming, formatting → Quality. Complexity, allocation → Performance. Vulnerabilities → Security. Coverage → Test Engineer.

## Security Reviewer (`security-reviewer`, sonnet)

**Look for:** injection (SQL / NoSQL / command / LDAP / template / proto pollution; unparam'd input concatenated into queries / shell / templates); XSS (un-encoded user input; raw-HTML APIs with non-trusted data); authentication (session fixation, weak password handling); authorization (missing access checks on new endpoints; BOLA — guessing IDs to access others' resources); CSRF on state-changing endpoints; input validation (lengths, types, ranges; file upload mime / size; URL validation for redirects); trust boundaries (external data treated as trusted before validation); secrets (tokens / keys / passwords in code, logs, error messages, or history).

**Do NOT flag:** crypto primitives, JWT, OAuth flows, supply-chain → Security Deep. Performance of security checks → Performance. Code style → Quality.

## Quality Reviewer (`quality-reviewer`, sonnet)

**Look for:** naming (identifiers describe what they ARE, not what they DO with it; consistent vocabulary); patterns (matches surrounding idioms); anti-patterns (god functions, magic numbers, deep nesting > 3, Boolean params that flip behavior, mutation in supposedly-pure functions); comments (WHY not WHAT; flag `// removed`, `// used by X`, history parentheticals); cohesion (one function = one thing); DRY (extract at 3+ copies; leave 2; premature DRY > copy); dead code (unused exports, unreachable branches, ownerless TODOs).

**Do NOT flag:** logic correctness → Code. Performance / complexity → Performance (opus pass of this same agent). Test quality → Test Engineer. Vulnerabilities → Security.

## Performance Reviewer (`quality-reviewer`, opus — separate session from Quality)

**Look for:** algorithmic complexity (O(n²) where O(n log n) or O(n) fits; nested loops over the same collection; hoistable repeated work); N+1 queries (per-iteration DB / API / file calls inside loops); memory (unbounded growth per request; large object retention; loading entire files where streaming would do); latency (blocking IO on the request path; sync CPU-heavy work in event loops; unbounded waits without timeout); caching (repeated computation within a request; cache-key correctness, no cross-user collisions); pagination / streaming (list endpoints loading everything; large file responses without streaming).

**Do NOT flag:** cache locality, lock contention, syscall overhead, hot-loop allocation → Systems Performance specialist. Code style → Quality. Security implications → Security.

## Test Engineer (`test-engineer`, sonnet)

**Look for:** coverage of new branches (if / switch / try-catch / loop break — each has ≥1 test); edge cases (empty / null / zero / negative / max-int / unicode / very-long; concurrency races); error paths (verify failure modes, not just success); test quality (specific assertions, no "just runs without throwing"; deterministic — no flaky time / random / network; independent); mocking (only at trust boundaries; not the system under test or its peers; realistic behavior); test data (realistic, not just `foo` / `bar`); setup / teardown (clean; no shared mutable state across tests).

**Do NOT flag:** test framework choice — architecture call. Test code style → Quality. Test performance unless absurdly slow → Performance.
