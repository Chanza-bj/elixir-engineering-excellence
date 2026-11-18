# Fintech, banking, payments, and external integrations

This reference defines engineering safeguards, not legal or scheme certification. Confirm each provider's current API contract, banking scheme rules, institutional requirements, and applicable jurisdiction.

## Model the lifecycle
Represent financial workflows as explicit state machines or carefully constrained state transitions. Example conceptual states may include `initiated`, `submitted`, `pending`, `confirmed`, `failed`, `reversed`, `settled`, and `reconciled`; choose states that match the real scheme/provider.

For every transition define:
- Allowed source states and target state.
- Actor/source of transition.
- Preconditions and evidence.
- Idempotency and duplicate handling.
- Audit record.
- Retry/recovery behaviour.
- Whether the transition moves money or only records information.

Do not let a late callback overwrite a more authoritative terminal state without a defined correction/reversal process.

## Idempotency
- Define key scope: provider, merchant/tenant, operation type, and client reference as applicable.
- Persist the key with a unique database constraint.
- Store request fingerprint and outcome so replays can return the original result.
- Reject reuse of the same key with materially different request content.
- Ensure concurrent requests cannot both perform the same financial action.
- Retain idempotency records for a period aligned with provider replay windows, reconciliation, and audit requirements.
- Idempotency does not mean blindly ignoring all duplicates: classify exact replay, conflicting replay, and duplicate event with different transport ID.

## Provider calls
- Put each provider behind a dedicated adapter/client boundary.
- Define connect and receive timeouts, TLS requirements, authentication, request signing, response validation, and error mapping.
- Distinguish definitive rejection from uncertain outcome (timeout, connection reset, ambiguous 5xx).
- Do not retry an uncertain money-moving request unless provider idempotency or a safe status inquiry makes retry correct.
- Use circuit breakers or rate limiting only when justified and designed with recovery semantics.
- Avoid logging raw request/response bodies. Redact secrets, account data, personal information, and tokens.
- Keep provider-specific fields out of core domain models where possible; map to canonical internal types.

## Webhooks and callbacks
1. Enforce body size and content-type limits.
2. Preserve raw request bytes for signature verification if the provider signs raw payload.
3. Verify signatures using provider-defined algorithm and constant-time comparison where available.
4. Validate timestamp/replay window and key rotation rules where defined.
5. Validate merchant, transaction reference, amount, currency, and expected state against persisted records.
6. Persist the received event and deduplication identity before acknowledging, when reliable processing is required.
7. Return the provider-required acknowledgement quickly; process heavier work asynchronously.
8. Make event handling idempotent and safe under concurrent duplicate delivery.
9. Store processing status, attempts, and failure reason with appropriate retention and redaction.
10. Provide replay/reprocessing tools with authorization and audit.

A webhook is evidence from an external system, not unquestionable truth. Apply provider contract validation and reconciliation.

## Durable handoff: inbox/outbox
Use an inbox table to durably record inbound events and deduplicate provider deliveries. Use an outbox table when a committed business change must trigger asynchronous delivery. A worker claims pending records, performs bounded work, and records outcome. Claiming must be concurrency-safe (for example, database locking/atomic state transition). Delivery is normally at-least-once; consumers must be idempotent.

Do not claim exactly-once execution across a database and external service without a real protocol that provides it.

## Ledger and accounting integrity
- Prefer append-only journal/ledger entries for financial postings; corrections are compensating entries, not destructive edits.
- Define debit/credit sign conventions and enforce balanced postings at the appropriate transaction boundary.
- Separate transaction status from accounting posting status.
- Preserve source references, posting dates, value dates, currency, amount, and actor/system provenance.
- Prevent duplicate posting with unique business keys and database constraints.
- Define reversal, refund, chargeback, and adjustment as distinct business operations.
- Do not derive account balance solely from mutable cached state without reconciliation controls.

## Reconciliation
- Compare internal transactions, provider records, settlement reports, bank statements, and ledger postings.
- Classify unmatched, amount mismatch, currency mismatch, duplicate, missing, delayed, reversed, and settled-but-unposted cases.
- Preserve source files and extraction metadata under appropriate security/retention controls.
- Make reconciliation repeatable and auditable.
- Never silently discard unmatched rows.
- Provide controlled resolution workflow with maker-checker where required.

## ISO/banking file integrations
- Treat file formats and scheme profiles as versioned contracts.
- Validate encoding, delimiters, record lengths, checksums, control totals, headers/trailers, sequence numbers, and required fields.
- Handle Unicode and special characters deliberately; do not strip data without a documented normalization rule.
- Preserve original input and normalized representation where audit policy permits.
- Make parsing deterministic and report exact record/field errors.
- Define duplicate file detection, replay, partial acceptance, and file-level atomicity.
- Do not assume a file name alone uniquely identifies a batch.
- Keep format-specific parsing separate from canonical transaction/domain processing.

## Security
- Apply least privilege to service credentials and database roles.
- Use secrets management and rotation.
- Redact sensitive values from logs, telemetry labels, traces, exception messages, and test snapshots.
- Use encryption in transit and appropriate encryption at rest.
- Apply access control to exports, reconciliation files, and operational replay tools.
- Define retention and deletion policies with legal/compliance owners.
