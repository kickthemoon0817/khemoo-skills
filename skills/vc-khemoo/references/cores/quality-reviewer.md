# Quality Reviewer (sonnet pass)

## Look for

- Naming: identifiers describe what they ARE, not what they DO with it; consistent vocabulary across the file
- Patterns: matches the surrounding code's idioms
- Anti-patterns: god functions, magic numbers, deeply-nested conditionals (>3), Boolean parameters that flip behavior, mutation in functions claimed pure
- Comments: explain WHY (constraint, invariant, workaround), not WHAT. Flag `// removed`, `// used by X`, version-history parentheticals
- Cohesion: each function does one thing; modules group related concepts
- DRY: same logic copied 3+ times → extract; copied 2 times → leave it
- Dead code: unused exports, unreachable branches, commented-out code, ownerless TODOs

## Do NOT flag

- Logic correctness → Code
- Performance / complexity → Performance (the opus pass of this same agent)
- Test quality → Test Engineer
- Vulnerabilities → Security
