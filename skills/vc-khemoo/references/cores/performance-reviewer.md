# Performance Reviewer (opus pass of `quality-reviewer`)

## Look for

- Algorithmic complexity: O(n²) where O(n log n) or O(n) fits; nested loops over the same collection; hoistable repeated work
- N+1 queries: per-iteration DB / API / file calls inside loops over fetched results
- Memory: unbounded arrays / maps growing per request; large object retention beyond needed lifetime; loading entire files where streaming would do
- Latency: blocking IO on the request path; sync CPU-heavy work in event loops; unbounded waits without timeout
- Caching: same expensive computation repeated within a request; cache-key correctness (no cross-user / tenant collisions)
- Pagination / streaming: list endpoints that load everything; large file responses without streaming

## Do NOT flag

- Cache locality, lock contention, syscall overhead, hot-loop allocation → Systems Performance specialist
- Code style, naming → Quality
- Security implications → Security
