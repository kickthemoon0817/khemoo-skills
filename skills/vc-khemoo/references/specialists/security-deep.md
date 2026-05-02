# Security Deep Reviewer

## Look for

- Cryptographic primitive choice: AEAD over raw block ciphers; Argon2id / scrypt / bcrypt for passwords (not MD5 / SHA1); Ed25519 / ECDSA-P256 over RSA-1024; HKDF for key derivation; constant-time comparison for secrets
- Cryptographic misuse: nonce / IV reuse (especially GCM); ECB mode; static salts; rolling-your-own; hashing without HMAC where HMAC needed; signature verification ignoring null returns
- Randomness: `crypto.randomBytes` / `getRandomValues` for security-sensitive randomness, not `Math.random`
- Secret lifecycle: retrieved at use-time; rotated; never logged (even in error paths); zeroed in memory where possible; not in git history
- JWT / token: algorithm pinned (no `none`, no algo-confusion); audience / issuer verified; expiry enforced; refresh tokens single-use; rotation supported
- Auth flow design: state on OAuth (CSRF); PKCE on public clients; redirect URI exact match; account-takeover paths reasoned through (email change → password reset → MFA bypass)
- Webhook signatures: verified with constant-time compare; replay protection (timestamp + nonce); body read raw before parsing
- Sandbox boundaries: `eval`, `Function`, `vm.runInNewContext` — threat model? sanitization? resource limits? escape paths?
- Supply-chain: new dependency from low-reputation registry; typosquats; postinstall fetching remote code; lockfile integrity hashes present
- Behavioral high-trust trigger: new endpoint accepting user-controlled identifiers (BOLA surface); new auth/session flow

## Do NOT flag

- Generic OWASP-Top-10 → Security (core)
- Code style in security code → Quality
- Performance of crypto → Performance
- Speculative threats with no concrete code path — tie each finding to a line
