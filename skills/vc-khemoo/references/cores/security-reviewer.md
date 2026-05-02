# Security Reviewer

## Look for

- Injection: SQL / NoSQL / command / LDAP / template / prototype pollution; user input concatenated into queries / shell / templates without parameterization
- XSS: user input rendered without encoding; raw-HTML APIs called with non-trusted data
- Authentication: session fixation, weak password handling (no rate limiting, no lockout, plaintext storage)
- Authorization: missing access checks on new endpoints; broken object-level auth (BOLA — guessing IDs to access others' resources)
- CSRF: state-changing endpoints without CSRF protection
- Input validation: lengths, types, ranges; file upload mime-type / size; URL validation for redirects
- Trust boundaries: external data treated as trusted before validation
- Secrets: tokens / keys / passwords in code, logs, error messages, or commit history

## Do NOT flag

- Crypto primitives, JWT, OAuth flows, supply-chain → Security Deep
- Performance of security checks → Performance
- Code style → Quality
