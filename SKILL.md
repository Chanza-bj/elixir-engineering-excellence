---
name: elixir-engineering-excellence
description: Opinionated production-grade Elixir and Phoenix engineering for modern applications. Use when designing, implementing, reviewing, refactoring, testing, debugging, scaling, or deploying Elixir/OTP/Phoenix systems, including REST APIs, LiveView, Channels, distributed applications, Ecto/PostgreSQL, application security, secure coding, authentication and authorization, fintech and banking integrations, payment processing, webhooks, bulk file uploads, data extraction, streaming pipelines, and high-volume transaction systems.
---

# Elixir Engineering Excellence

The goal is not merely code that compiles: design systems that are understandable, observable, secure, recoverable, testable, and correct under concurrency and failure.

This skill covers Elixir/Phoenix work in general. Financial, banking, and bulk-ingestion guidance (Sections 7–8) applies only when the task involves those workloads.

Apply these standards when working in an Elixir or Phoenix codebase. Be opinionated, but respect verified project constraints and explain meaningful trade-offs.

## 1. Operating principles

1. **Understand before changing.** Inspect the project structure, `mix.exs`, lockfile, configuration, supervision tree, schemas, contexts, tests, and deployment conventions before proposing structural changes.
2. **Use the project's actual versions.** Read `.tool-versions`, `mise.toml`, `mix.exs`, CI configuration, and runtime metadata. Verify Elixir/OTP compatibility and the installed Phoenix, LiveView, Ecto, and Oban APIs. Do not invent APIs or silently upgrade dependencies.
3. **Prefer simple functional modules.** A module and functions are the default. Introduce a process only when there is a real need for owned state, coordination, message handling, scheduling, isolation, or lifecycle management.
4. **Use OTP deliberately.** Processes are lightweight isolated units of execution, not a reason to put every function behind a GenServer. Supervise long-lived processes and make restart semantics intentional.
5. **Separate domain decisions from delivery mechanisms.** Keep business rules out of controllers, LiveViews, Channels, plugs, database callbacks, and provider-specific HTTP clients.
6. **Make failure explicit.** Define timeouts, error categories, retry policy, idempotency, compensation, and recovery. Never disguise failure as success.
7. **Design for concurrency.** Assume requests, jobs, callbacks, and nodes can execute concurrently and out of order. Protect invariants at the database boundary.
8. **Test observable behaviour.** Cover domain rules, boundaries, failure paths, concurrency-sensitive invariants, and integration contracts.
9. **Operate what you build.** Include structured logs, telemetry, health checks, deployment considerations, and actionable operational diagnostics.
10. **Do not over-engineer.** Prefer the smallest design that meets stated reliability, throughput, and maintainability requirements.
11. **Security is a design requirement.** Threat-model sensitive workflows and apply secure defaults at every layer; do not defer security to a final review.
12. **Document contracts, not syntax.** New modules and public functions get `@moduledoc`/`@doc`; private code gets a comment where the *why* is not obvious. In existing code, match the project's documentation style. See Section 12.

## 2. Required workflow

For non-trivial tasks, follow this sequence:

### A. Discover
- Identify the application type, entry points, contexts, adapters, schemas, jobs, and runtime processes.
- Read relevant code and tests before editing.
- Check dependency versions and configuration sources. Never print secrets.
- Determine whether the task is a new feature, defect, refactor, migration, performance issue, or production incident.
- Identify data sensitivity, transaction criticality, throughput, latency, and availability expectations.
- Identify trust boundaries, attacker-controlled inputs, authentication/authorization requirements, secrets, and likely abuse cases.

### B. Model the problem
- State the business invariant and expected behaviour.
- Identify inputs, outputs, side effects, ownership, and failure modes.
- Determine consistency requirements: atomic database transaction, eventual consistency, at-least-once delivery, or best-effort action.
- Identify duplicate, replay, timeout, partial-failure, and concurrent-execution scenarios.
- Choose the simplest suitable process, database, and delivery boundaries.

### C. Design
- Keep domain logic in plain modules and application contexts.
- Define explicit behaviour for errors and retries.
- Enforce important invariants with database constraints as well as application validation.
- Design idempotency and audit records before implementing money-moving or externally visible operations.
- Bound memory, concurrency, queue growth, request size, and execution time.
- Add observability at meaningful boundaries.
- Perform a proportionate threat model for exposed endpoints, sensitive data, privileged actions, file handling, and external integrations.
- Define secure defaults for authentication, authorization, validation, rate limits, secrets, transport security, and data retention.

### D. Implement
- Follow local naming, formatting, context, and test conventions unless they are demonstrably harmful.
- Make focused changes; avoid unrelated rewrites.
- Use pattern matching and `with` for clear control flow, not cleverness.
- Use Ecto changesets for input casting/validation and database constraints for race-safe enforcement.
- Keep external I/O behind adapters or dedicated integration modules.
- Do not introduce a dependency without explaining why existing tools are insufficient.
- Follow the security requirements in `references/security-practices.md`.
- Document new modules and public functions as described in Section 12.
- For common idioms (raw-body webhooks, bounded concurrency, idempotent inserts, streaming exports, concurrency tests), start from `references/code-patterns.md`.

### E. Verify
Run the relevant checks available in the repository, normally:
- `mix format --check-formatted`
- `mix compile --warnings-as-errors` (where the project supports it)
- `mix test`
- `mix credo --strict` if configured
- `mix dialyzer` if configured
- `mix sobelow` and `mix deps.audit` / `mix hex.audit` if configured (security static analysis and dependency advisories)
- focused integration or migration checks

Do not claim a check passed unless you actually ran it and observed success. If a command cannot run, state why and what remains unverified.

### F. Report
Summarize:
- What changed and why.
- Important design decisions and trade-offs.
- Files changed.
- Commands/tests run and their actual outcomes.
- Migration, configuration, deployment, security, or operational steps.
- Known limitations and follow-up risks.

For a small question, do not force this entire workflow into the answer. Scale process to task size.

## 3. Architecture rules

### Boundaries
- **Web layer:** HTTP/LiveView/Channel protocol concerns, authentication context, parameter parsing, response rendering.
- **Application layer:** use cases and orchestration across domain rules, persistence, and external systems.
- **Domain layer:** business concepts, calculations, state transitions, and invariants; avoid Phoenix and provider dependencies.
- **Infrastructure layer:** Ecto repositories, external HTTP clients, message brokers, file/object storage, and provider-specific adapters.

Use Phoenix contexts as cohesive public APIs into application capabilities. Do not create a context for every table or a giant context that owns unrelated business areas.

### Data and state
- Persist durable business state in an appropriate durable store.
- Do not use a GenServer as the source of truth for money, mandates, orders, or other durable business records.
- Treat caches and process state as disposable unless explicitly designed otherwise.
- Make ownership clear: which process or transaction is allowed to change a state machine?
- Use database constraints to protect uniqueness, referential integrity, and valid state transitions under races.

### API and web
- Keep controllers thin. Validate/authorize, call a context/use case, and map outcomes to HTTP.
- Use explicit request and response contracts. Avoid exposing Ecto structs as accidental public API contracts.
- Authenticate and authorize every protected operation. Authentication is not authorization.
- Use consistent status codes, pagination, filtering, and error shapes.
- Version APIs when compatibility requirements justify it.
- For LiveView and Channels, authorize subscriptions and events; never trust client-supplied identity, tenant, account, or amount fields.

## 4. OTP and BEAM rules

- Use `GenServer` for serialized stateful coordination, not stateless business functions.
- Use `Task` for bounded, finite asynchronous work; choose supervision and result semantics deliberately.
- Use `Task.Supervisor` for dynamically spawned tasks that need lifecycle control.
- Use `DynamicSupervisor` for dynamic long-lived workers.
- Use `Registry` for local process lookup when appropriate; understand that it is node-local unless a distributed solution is deliberately added.
- Use `GenStage`/Broadway or another back-pressure-aware design when the workload requires demand-driven concurrent processing; do not add them reflexively.
- Use `:gen_statem` when a complex process has explicit states and state-dependent transitions that benefit from a formal state machine.
- Supervision restarts processes; it does not roll back external side effects or restore arbitrary in-memory state.
- Choose `:one_for_one`, `:one_for_all`, or `:rest_for_one` based on dependency relationships and restart consequences.
- Avoid unbounded mailboxes, unbounded task creation, long blocking callbacks, and large messages copied between processes.
- Use timeouts for synchronous calls and external operations. Understand that a caller timeout does not necessarily cancel work already running.
- Treat node distribution as a failure-prone network: partitions, reconnects, duplicate messages, stale membership, and partial availability are normal design concerns.

See `references/otp-and-beam.md`.

## 5. Phoenix rules

Support conventional Phoenix MVC, JSON APIs, LiveView, Channels, Presence, and multi-node Phoenix applications.

- Use current Phoenix conventions from the installed version; do not cargo-cult old Phoenix 1.6/1.7 examples into newer applications.
- Keep controllers and LiveViews orchestration-focused.
- Use contexts to define application boundaries.
- Use HEEx function components for reusable presentation.
- Use LiveView for server-driven interactive UI when it fits; do not force it where a separate client/API architecture is more appropriate.
- Use Channels for bidirectional real-time communication and Presence for distributed online presence, not as a durable event store.
- Authorize socket connections, topic joins, events, and LiveView actions.
- On Phoenix 1.8+, use the generated **scope** (`current_scope`) to carry the authenticated principal and tenant into contexts; pass the scope into context functions rather than raw IDs. On older versions, follow the project's existing equivalent.
- In LiveView, use `assign_async/3` / `start_async/3` (LiveView 0.20+/1.x) for slow loads instead of blocking `mount/3` or `handle_event/3`.
- Prefer `Req` for new outbound HTTP integrations unless the project already standardizes on another client.
- Use PubSub for notifications, not as a durable queue or guaranteed event log.
- Understand that PubSub delivery and Presence state are not equivalent to durable business persistence.
- For multi-node deployments, verify cluster topology, PubSub adapter, node naming/cookie configuration, network policy, and deployment platform behaviour.

See `references/phoenix-engineering.md`.

## 6. Ecto and database rules

- Use schemas to map persisted data, changesets to cast and validate input, and migrations to evolve storage.
- Prefer database constraints for invariants that must survive concurrent requests.
- Use `unique_constraint/3`, `foreign_key_constraint/3`, and related changeset annotations to translate database constraint errors into changeset errors; the database constraint itself must exist.
- Use `Ecto.Multi` or an explicit transaction for multiple dependent database writes that must commit or roll back together.
- Keep transactions short. Do not make slow external HTTP calls while holding database locks or a transaction open.
- Use optimistic locking, row locking, unique constraints, or atomic SQL updates where the business invariant requires them.
- Avoid N+1 queries, unbounded result sets, and loading entire tables into memory.
- Use keyset pagination for large or changing datasets when offset pagination is unsuitable.
- Inspect query plans and indexes before optimizing based on intuition.
- Treat migrations as production changes: consider table size, lock duration, backfills, compatibility with old application versions, rollback, and deployment order.
- Use decimal arithmetic for money. Never use floating-point numbers for financial amounts.

See `references/ecto-and-databases.md`.

## 7. Financial systems, integrations, and webhooks

For payments, banking, fintech, mandates, settlement, reconciliation, and other financial workflows, correctness takes priority over convenience.

Non-negotiable:
- Use integer minor units or `Decimal` with explicit currency/scale rules. Never use binary floats for money.
- Define transaction identity, idempotency key scope, uniqueness, and replay behaviour.
- Persist inbound provider events before acknowledging them when reliable processing is required.
- Verify webhook signatures against the raw request body using constant-time comparison where supported; validate timestamp/replay windows where the provider protocol supports them.
- Do not trust callback status, amount, currency, account, or reference without validating it against the expected transaction and provider contract.
- Model payment lifecycle transitions explicitly. Reject illegal transitions.
- Separate initiation, provider communication, callback handling, posting, settlement, and reconciliation.
- Use an outbox/inbox or equivalent durable handoff when database state and asynchronous delivery must remain coordinated.
- Never assume a network timeout means the provider did not process a request.
- Reconcile internal records against provider/bank statements and settlement reports.
- Preserve immutable audit history for financially significant actions.
- Redact credentials, PAN-like data, account identifiers, tokens, and sensitive payloads from logs.
- Define maker-checker/approval requirements where the business or regulatory context requires them.

Never claim regulatory compliance merely because code follows this skill. Confirm applicable jurisdiction, provider, scheme, and institutional requirements with authoritative sources and domain owners.

See `references/fintech-and-banking.md`.

## 8. Bulk uploads, extraction, and data pipelines

- Stream large files; do not read a multi-gigabyte upload into one binary or list.
- Enforce upload size, row count, decompression ratio, MIME/content checks, timeout, and tenant/user authorization limits.
- Treat file extensions and client MIME types as untrusted hints.
- Store files in controlled temporary or object storage with lifecycle/retention rules.
- Separate upload acceptance from asynchronous parsing, validation, enrichment, and persistence.
- Use staging records or staging tables for large imports.
- Validate row-level data and report line numbers, field names, and actionable errors without leaking sensitive values.
- Define duplicate detection, partial acceptance, all-or-nothing semantics, and resumability before implementation.
- Use bounded concurrency and back-pressure. Preserve deterministic ordering where required.
- Make import jobs idempotent and restartable. Track batch, file, row, and job status.
- For extraction, define source format, encoding, schema, normalization, provenance, and quality checks.
- Protect against archive bombs, path traversal, malicious documents, formula injection in generated spreadsheets, and parser vulnerabilities.
- For exports, stream/chunk output and use asynchronous generation for expensive datasets.

See `references/bulk-ingestion-and-extraction.md`.

## 9. Testing and quality

- Test domain rules without starting the whole application where practical.
- Use `DataCase` for database behaviour and `ConnCase` for HTTP behaviour according to project conventions.
- Test success, invalid input, authorization failure, missing records, duplicate requests, concurrency conflicts, timeouts, and provider failures.
- Test webhook signature validation and replay/idempotency behaviour.
- Test financial arithmetic and rounding boundaries.
- Test job retries and uniqueness using the actual job framework's supported test mode.
- Avoid brittle tests coupled to private implementation details.
- Prefer dependency injection through behaviours/configuration boundaries over extensive global mocking.
- Use factories/fixtures that are explicit and valid; avoid hidden test setup with surprising side effects.
- Run formatter, compiler, tests, and configured static analysis.

See `references/testing-and-quality.md`.

## 10. Production and operations

- Use runtime configuration for environment-specific secrets and endpoints.
- Validate required configuration at startup; fail clearly rather than silently starting in a broken state.
- Use releases and a repeatable deployment process appropriate to the project.
- Implement graceful shutdown and understand in-flight request/job handling.
- Instrument request latency, database query time, queue latency, job outcomes, provider errors, throughput, memory, and process/mailbox pressure where relevant.
- Use structured logs with correlation/request/job/provider references.
- Build health checks that distinguish process liveness from dependency readiness.
- Back up data and test restoration. A backup that has never been restored is not a verified recovery plan.
- Use safe rollout patterns for schema changes and background backfills.
- Keep secrets out of source control, logs, exception messages, and generated artifacts.

See `references/production-engineering.md`.

## 11. Security engineering (mandatory)

Security applies to every application, not only financial systems. Load `references/security-practices.md` for any task touching authentication, authorization, user input, uploads, webhooks, secrets, or exposed endpoints. The non-negotiables:

- Authenticate and authorize every protected operation on the server, deny by default. Hiding UI controls is not authorization.
- Derive tenant/account/role from the authenticated principal (the Phoenix 1.8 scope, where available), and scope every query and command by it. Never trust client-supplied ownership, tenant, role, amount, or status fields.
- Treat all external input as untrusted; never interpolate it into SQL, shell commands, file paths, atoms, or `raw/1` HTML.
- Bound every exposed or expensive operation: body/upload size, pagination caps, rate limits, timeouts, concurrency.
- Keep secrets and sensitive data out of source, client bundles, logs, telemetry, exceptions, and fixtures.
- Never claim an application is secure or compliant because these checks were considered. State what was tested, what was not, and what needs specialist review.

## 12. Documentation and commenting standard

Document contracts and intent, not syntax. Comments that restate the code are noise and rot.

### New code written by this skill
- Every new module gets an `@moduledoc` stating its responsibility, architectural place, and important invariants or side effects. Use `@moduledoc false` for deliberately internal modules.
- Every new public function gets an `@doc` covering purpose and, where relevant: return shapes, errors, side effects, authorization expectations, idempotency, and concurrency semantics. Add `@spec` at domain and adapter boundaries.
- Private functions get a `#` comment only when the reason, invariant, or non-obvious choice is not clear from the name and body.
- Tests are documented by descriptive `describe`/`test` names; add a comment only when the setup or the property being verified is non-obvious (e.g. a concurrency race).

### Existing code
- Match the project's existing documentation style and density.
- Document what you add or materially change; do not retrofit documentation onto untouched functions as part of an unrelated change.

### Always
- Keep comments accurate when code changes; delete comments that become false.
- Do not leave TODO/FIXME comments as a substitute for implementation or for stating a known limitation in the report.

Example:

```elixir
defmodule Billing.PaymentProcessor do
  @moduledoc """
  Coordinates payment processing and enforces payment lifecycle invariants.
  """

  @doc """
  Processes a payment idempotently and returns its persisted outcome.

  Repeated calls with the same provider reference return the original result.
  """
  @spec process_payment(map()) :: {:ok, map()} | {:error, term()}
  def process_payment(attrs) do
    # The unique index on provider_reference, not this lookup, is what stops
    # concurrent retries from creating duplicate payments.
    {:ok, Map.put(attrs, :status, normalize_status(attrs[:provider_status]))}
  end

  defp normalize_status("SUCCESS"), do: :confirmed
  defp normalize_status("FAILED"), do: :failed
  defp normalize_status(_unknown), do: :pending
end
```

`normalize_status/1` has no comment because its clauses already say everything a comment would.

## 13. Anti-patterns

Reject or challenge the patterns in `references/anti-patterns.md`. The most common: GenServer for stateless code, business logic in web/transport modules, network calls inside database transactions, blind retries of side effects, floats for money, unbounded tasks/streams/mailboxes, PubSub as durable delivery, catch-all `rescue`, `{:ok, _}` after a failed side effect, and trusting client-supplied ownership fields.

## 14. Decision checklist

Before finalizing a non-trivial design, ask:

1. What is the business invariant?
2. Where is the source of truth?
3. What must be atomic?
4. What can be retried, and under what idempotency key?
5. What happens if the process, node, database, or provider fails at each step?
6. Is concurrency bounded?
7. Can the operation be resumed or reconciled?
8. What must be observable by operators?
9. How will this be tested under duplicate, timeout, and concurrent execution?
10. Does the design fit the project's actual versions and conventions?

## 15. Reference loading

Read only the references relevant to the task:
- Language idioms: `references/elixir-fundamentals.md`
- Processes, OTP, BEAM, distribution: `references/otp-and-beam.md`
- Phoenix MVC, LiveView, Channels, Presence, APIs: `references/phoenix-engineering.md`
- Schemas, queries, transactions, migrations: `references/ecto-and-databases.md`
- Payments, banking, webhooks, reconciliation: `references/fintech-and-banking.md`
- Large uploads, extraction, imports, exports: `references/bulk-ingestion-and-extraction.md`
- Tests, static analysis, quality: `references/testing-and-quality.md`
- Releases, observability, incidents: `references/production-engineering.md`
- Architecture and implementation workflow: `references/architecture-and-workflows.md`
- Security, threat modelling, secure Phoenix/Ecto practices: `references/security-practices.md`
- Smells and safer alternatives: `references/anti-patterns.md`
- Concrete code for common idioms (webhooks, bounded concurrency, idempotent writes, streaming exports, Oban uniqueness, concurrency tests): `references/code-patterns.md`

When a task depends on framework/library behaviour that may have changed, consult the official documentation for the exact installed version. The links in `references/official-resources.md` are starting points, not substitutes for version verification.
