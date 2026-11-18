# Ecto and database engineering

## Schemas and changesets
- Schemas describe persisted structures and associations; they are not automatically public API contracts.
- Use changesets to cast permitted external input and validate business-relevant shape.
- Use database constraints for race-safe uniqueness, foreign keys, check constraints, and exclusion rules.
- `unique_constraint/3` and related changeset helpers translate database errors; they do not create the database constraint.
- Do not put network calls or unrelated side effects in changeset functions.
- Avoid overloading schema modules with domain orchestration.

## Querying
- Select only required columns for large/read-heavy paths.
- Avoid N+1 queries; use deliberate joins/preloads and inspect generated SQL.
- Use `Repo.stream/2` inside a transaction where required by the adapter and Ecto API; understand connection ownership and transaction lifetime.
- Use keyset pagination for large tables and frequently changing datasets.
- Avoid `offset` pagination for deep scans where performance degrades or rows shift during concurrent writes.
- Add indexes based on query predicates, joins, sort order, and selectivity. Validate with `EXPLAIN (ANALYZE, BUFFERS)` in a safe environment.
- Do not add indexes blindly; account for write amplification and storage.
- Use partial, composite, and covering indexes when query patterns justify them.
- Avoid loading all rows into memory for exports or imports.

## Transactions
- Use `Ecto.Multi` for named, composable database operations with explicit dependency between steps.
- Keep transactions short and database-focused.
- Never hold row locks while waiting for a remote provider, file upload, email, or human approval.
- A transaction cannot atomically commit a remote HTTP request. Use durable intent/outbox patterns, idempotency, and reconciliation.
- Understand isolation level and locking behaviour of the actual database.
- Use `Repo.insert_all/3` and bulk SQL deliberately; changesets/callbacks are not automatically run for bulk operations.
- Use atomic SQL updates for counters/state transitions where appropriate.
- Use optimistic locking for conflicting edits when it fits the domain.
- Use row locks for short critical sections and always define lock ordering to reduce deadlocks.

## Money and precision
- Never use floats for money.
- Prefer integer minor units when currency exponent is fixed and clear; otherwise use `Decimal` with explicit precision, scale, and rounding policy.
- Store currency alongside amount.
- Define how fees, FX rates, tax, and rounding are calculated and audited.
- Test boundary values and repeated calculations.

## Migrations
- Review generated migrations. Do not accept them blindly.
- Use expand-and-contract for zero/low-downtime changes: add compatible columns/indexes, deploy dual-compatible code, backfill in batches, switch reads/writes, then remove obsolete structures in a later release.
- Assess table size, locks, index build strategy, default values, foreign key validation, and long-running backfills.
- Do not run a large data migration synchronously during app startup.
- Make backfills resumable, observable, rate-limited, and idempotent.
- Have rollback/forward-fix strategy and backups for destructive operations.
- Coordinate schema compatibility with rolling deployments and old app instances.

## Large data access
- Use chunked queries, cursors/streams where supported, and bounded memory.
- Keep database pool capacity in view when running background imports/exports.
- Do not monopolize a small Repo pool with long-running streams; consider dedicated workloads/pools only after measurement.
- For extraction and bulk processing, see `bulk-ingestion-and-extraction.md`.
