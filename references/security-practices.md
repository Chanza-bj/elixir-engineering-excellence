# Security Practices for Elixir and Phoenix Applications

Security is a continuous engineering concern. Apply these practices proportionately to the application's threat model, data sensitivity, exposure, and business impact. Use current official framework guidance and recognized standards such as OWASP ASVS and the OWASP Cheat Sheet Series as reference points; do not claim certification or compliance without a formal assessment.

## 1. Threat modelling

Before implementing a sensitive feature, identify:
- Assets: credentials, personal data, financial records, tokens, uploaded documents, administrative capabilities, and service availability.
- Trust boundaries: browser to Phoenix, tenant to tenant, application to database, application to provider, node to node, and operator to production environment.
- Entry points: HTTP routes, LiveView events, Channels, APIs, webhooks, file uploads, background jobs, imports, exports, and administrative tools.
- Abuse cases: account takeover, privilege escalation, IDOR/BOLA, tenant escape, replay, enumeration, resource exhaustion, injection, data exfiltration, and denial of service.
- Required controls, residual risks, and tests that demonstrate the controls.

Keep threat modelling lightweight for low-risk changes and more formal for payments, identity, sensitive records, public APIs, and privileged operations.

## 2. Authentication and session security

- Prefer maintained Phoenix authentication generators and framework-supported password hashing; inspect generated code rather than treating it as automatically correct for every application.
- Never store plaintext passwords or invent a password hashing algorithm. Use a modern password hashing function supported by maintained libraries and configure its cost appropriately.
- Use secure random tokens with sufficient entropy, store token digests where appropriate, expire and revoke tokens, and scope tokens to their purpose.
- Regenerate session identifiers after authentication or privilege changes. Invalidate sessions on logout and account/security events as required.
- Configure cookies with `Secure`, `HttpOnly`, and an appropriate `SameSite` policy. Use HTTPS in production.
- Protect state-changing browser requests against CSRF. Do not disable CSRF protections to make a test or integration work without understanding the alternative control.
- Rate-limit login, password reset, registration, OTP, and token verification flows. Avoid account enumeration in externally visible responses.
- Implement safe password reset and account recovery flows; do not log reset tokens or expose them in analytics.
- Consider MFA and step-up authentication for administrators and high-risk financial actions.

## 3. Authorization and tenant isolation

- Authentication answers who the caller is; authorization decides what that caller may do. Enforce both.
- Deny by default. Check authorization in the server-side context/use-case boundary, not only in controllers, LiveViews, templates, or navigation.
- On Phoenix 1.8+, pass the generated scope struct (`current_scope`) into context functions and filter queries by it; do not unpack it into loose IDs that callers could substitute.
- Scope database queries by the authenticated principal's organization/tenant and permitted resources. Do not fetch globally and rely on the UI to hide other tenants' records.
- Never trust user-supplied `user_id`, `organization_id`, account number, role, ownership, or approval state without verifying it against the authenticated identity and policy.
- Check authorization for every object access and every mutation, including nested resources, exports, downloads, LiveView events, Channel topics, and background job initiation.
- Separate roles from permissions where complexity warrants it. Avoid broad administrator privileges and enforce maker-checker separation for sensitive workflows where required.
- Test horizontal and vertical privilege escalation, IDOR/BOLA, cross-tenant reads/writes, and unauthorized exports.

## 4. Input handling and injection prevention

- Treat every external value as untrusted, including values read from the database if they originated externally.
- Use changesets for casting and validation, but do not confuse validation with authorization or business-rule enforcement.
- Use parameterized Ecto queries. Do not interpolate untrusted values into SQL fragments, raw SQL, shell commands, file paths, or HTML.
- If dynamic SQL is unavoidable, allowlist identifiers and construct parameters separately; identifiers generally cannot be safely parameterized like values.
- Validate lengths, ranges, formats, encodings, and allowed values at boundaries. Enforce limits before expensive parsing or database work.
- Avoid atom creation from untrusted strings. Do not use `String.to_atom/1` on external input; use existing atoms or safe conversion patterns.
- Avoid unsafe deserialization of untrusted Erlang terms or serialized data. Prefer explicit, schema-validated formats such as JSON.
- Escape output by default. HEEx escapes interpolated content; do not use `raw/1` or mark content safe unless it is trusted and sanitized for the exact output context.
- Validate redirect destinations and avoid open redirects.
- Protect against SSRF: allowlist destinations where possible, reject unexpected schemes/hosts, control redirects, and block access to loopback, link-local, private, and metadata-service addresses as appropriate to the deployment environment.

## 5. HTTP, API, LiveView, and Channels

- Require authentication and authorization for protected routes and every action/event; a connected socket or authenticated mount does not make all subsequent events authorized.
- Do not trust client-supplied identity, role, tenant, account, price, amount, status, or ownership fields.
- Validate WebSocket/Channel topic names and authorize topic joins and events. Treat client messages as untrusted API input.
- Apply request body limits, upload limits, pagination caps, rate limits, timeouts, and bounded concurrency.
- Configure security headers appropriate to the application, including a considered Content Security Policy, `X-Content-Type-Options`, frame restrictions, and a suitable `Referrer-Policy`. Avoid blindly copying a CSP that breaks the app or permits unsafe inline execution.
- Use CORS allowlists for browser APIs; do not combine wildcard origins with credentialed requests.
- Return generic external errors while preserving safe diagnostic detail in protected logs. Never return stack traces, SQL errors, secrets, or internal topology to clients.
- Validate content types and request formats. Do not rely on a client-provided MIME type as proof of content.

## 6. Secrets, cryptography, and transport

- Keep secrets in runtime environment/configuration or a dedicated secret manager; never commit them or bake them into client assets or container images.
- Use separate credentials per environment and service, least privilege, rotation, and revocation. Do not reuse production secrets in development or tests.
- Never implement custom cryptography. Use maintained, vetted libraries and current algorithms/protocols appropriate to the use case.
- Use TLS for external and internal network connections where the threat model requires it; verify certificates and hostnames. Do not disable TLS verification in production.
- Use cryptographically secure randomness for tokens, keys, nonces, and security-sensitive identifiers.
- Use authenticated encryption for sensitive data at rest when required; define key storage, rotation, access, and recovery separately from encrypted data.
- Compare authentication tags, signatures, and secret-derived values using constant-time comparison functions provided by trusted libraries.
- Do not log passwords, access/refresh tokens, API keys, private keys, full payment credentials, or sensitive request/response bodies.

## 7. File uploads, imports, and exports

- Enforce maximum file size, row count, archive expansion limits, processing time, and per-user/tenant quotas.
- Verify file content using safe parsing or signature checks; do not trust filename extensions or browser MIME declarations.
- Generate server-side storage names. Prevent path traversal and never use an untrusted filename as a filesystem path.
- Store uploads outside the public web root or in private object storage. Authorize every download and define retention/deletion policies.
- Scan or sandbox risky file types when appropriate. Keep parsers and document-processing dependencies patched.
- Protect archive extraction against path traversal, symlinks, and decompression bombs.
- Prevent spreadsheet formula injection when exporting untrusted values to CSV/XLSX by neutralizing formula-leading cells according to the target format and consumer.
- Avoid exposing sensitive row contents in validation errors, logs, or downloadable reports.

## 8. Webhooks and financial integrations

- Verify signatures over the exact raw body and according to provider specifications. Preserve raw request bytes where required; parsing and re-encoding JSON can change the signed content.
- Validate signature encoding, key selection, timestamp tolerance, and replay protection. Rotate signing secrets safely.
- Persist verified inbound events durably before acknowledging when reliable processing is required.
- Make event processing idempotent with a durable uniqueness boundary. Handle duplicate and out-of-order events explicitly.
- Validate provider, merchant/account, currency, amount, reference, and expected lifecycle transition against internal records.
- Do not treat a callback as the only proof of settlement; reconcile against provider/bank reports and statements.
- Never blindly retry an ambiguous money-moving request. Query provider state or reconcile before retrying, using provider-supported idempotency keys where available.
- Keep immutable audit history for privileged and financially significant actions; restrict who can amend or reverse records.

## 9. Data protection, logging, and audit

- Classify data and collect only what is needed. Define retention, deletion, export, and access policies.
- Apply least privilege to database users, service accounts, operators, and background workers.
- Use database constraints and transactions to preserve security-sensitive invariants under concurrency.
- Redact or tokenize sensitive fields in logs, traces, metrics, exception reports, and support tooling.
- Use correlation identifiers without embedding personal or financial data in them.
- Protect audit logs against unauthorized modification and define retention and access controls.
- Encrypt backups and test restoration; restrict backup access as carefully as production database access.

## 10. Dependency and deployment security

- Inspect dependencies before adding them; consider maintenance status, ownership, permissions, transitive dependencies, and known vulnerabilities.
- Keep Elixir, OTP, Phoenix, Ecto, operating system images, and dependencies patched according to a risk-based process.
- Run available dependency/security audits in CI (for example `mix deps.audit` from mix_audit, `mix hex.audit` for retired packages, and `mix sobelow` for Phoenix-specific static analysis) and review findings rather than blindly suppressing them.
- Run services as non-root users, minimize container/image contents, restrict network access, and avoid unnecessary production tools.
- Separate development, test, staging, and production configuration and credentials.
- Fail safely when required security configuration is missing. Do not silently fall back to insecure defaults in production.
- Restrict administrative endpoints and operational consoles; protect remote shell and release management access.

## 11. Security testing checklist

For relevant features, test:
- Unauthenticated access to protected resources.
- Authenticated users attempting unauthorized actions.
- Cross-tenant reads, updates, deletes, searches, and exports.
- Invalid, oversized, malformed, and adversarial input.
- CSRF/session behaviour and cookie configuration.
- Rate limits and resource-exhaustion controls.
- SQL/HTML/path/command injection boundaries.
- SSRF and redirect validation where outbound URLs or redirects exist.
- Webhook signature failure, replay, duplicate, out-of-order, and wrong-amount scenarios.
- Secret and sensitive-data redaction in logs and errors.
- Dependency audit and production configuration checks.

Record what was actually tested. Security tests reduce risk but do not prove the absence of vulnerabilities. For high-risk or regulated systems, obtain independent security review and confirm applicable legal, regulatory, scheme, and contractual requirements with qualified owners.
