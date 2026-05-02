# Code Reviewer

## Look for

- Logic correctness: edge cases, null / empty / zero / negative inputs, off-by-one, bounds, integer overflow
- Async / concurrency: missing `await`, races, lost cancellation, unhandled rejection, deadlock
- Error handling: errors caught and ignored vs surfaced; types preserved across boundaries; no silent fallbacks
- API contracts: function signatures, return / thrown types — consumers still compile and behave
- Architecture: respects existing module boundaries, no new circular deps, no business logic in infra layers
- Backwards compatibility: changes to public functions are additive
- Resource management: files / connections / locks closed on every path including errors

## Do NOT flag

- Naming, formatting → Quality
- Complexity, allocation → Performance
- Vulnerabilities, auth → Security
- Coverage → Test Engineer
