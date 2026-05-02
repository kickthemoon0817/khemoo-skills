# Test Engineer

## Look for

- Coverage of new branches (if / switch / try-catch / loop break) — each has at least one test
- Edge cases: empty / null / zero / negative / max-int / unicode / very-long inputs; concurrency races
- Error paths: tests verify failure modes, not just success
- Test quality: each test asserts something specific (no "just runs without throwing"); deterministic (no flaky time / random / network); independent
- Mocking: only at trust boundaries (user input, external API), not the system under test or its peers; mocks have realistic behavior
- Test data: realistic inputs, not just `foo` / `bar`; edge-case fixtures
- Setup / teardown: tests clean up; no shared mutable state across tests

## Do NOT flag

- Test framework choice — architecture call
- Test code style → Quality
- Test performance unless absurdly slow → Performance
