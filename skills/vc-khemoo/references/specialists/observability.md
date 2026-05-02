# Observability Reviewer

## Look for

- Log structure: new logs are structured (key/value or JSON), not free-form; level appropriate; greppable
- Cardinality: new metric labels / log fields don't include unbounded values (request IDs, free-form strings)
- Sensitive data: no PII / secrets / tokens / auth headers in logs or trace attributes — even at `debug`
- Trace propagation: new async boundaries propagate trace context; spans have meaningful names
- Error reporting: new error paths report to the project's error sink with debug context; no double-reporting
- Naming consistency: new metrics follow the project's existing convention (case, prefix, units in name)
- Alerting impact: metric / log names that an existing alert depends on are not silently renamed

## Do NOT flag

- Application logic → Code
- Whether a metric is "necessary" — product call
- Log message wording → Documentation
