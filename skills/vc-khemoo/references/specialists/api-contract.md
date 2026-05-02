# API / Contract Reviewer

## Look for

- Silent breaking changes: field removed/renamed without deprecation; required field added; type narrowed; enum value removed; nullable → non-nullable
- Semantic breaking changes: field name unchanged but meaning shifts (units, ordering, default); previously-optional field now mandatory at runtime
- Versioning: breaking changes go in the next API version, not the current one
- Additive changes: new optional fields genuinely optional; new endpoints don't conflict with existing routes; new enum values added at the right end
- Error contract: error responses follow the project's existing envelope; new error codes documented
- Pagination, filtering, sorting: new list endpoints expose pagination; existing pagination contracts not silently changed
- Idempotency / safety: new mutating endpoints declare idempotency where appropriate; method matches semantics
- Public types in code: exported types follow the same rules as wire contracts

## Do NOT flag

- Internal implementation that doesn't surface in the contract → Code
- Performance of the new endpoint → Performance
- Whether the API design is "good" in the abstract — focus on whether THIS change is safe
