# Testing, quality gates, and review

## Test layers
- Pure unit tests: domain calculations, transformations, state transitions, validation policy.
- Context tests: application use cases and persistence behaviour.
- DataCase: Repo/schema/transaction/constraint behaviour.
- ConnCase: routes, plugs, controllers, authentication and HTTP contracts.
- LiveView tests: rendered state and user events.
- Channel tests: join authorization, event handling, broadcasts and disconnect behaviour.
- Integration tests: provider adapters, database, object storage, queues and external contracts.
- System/acceptance tests: critical end-to-end workflows where proportionate.

## What to test
For every meaningful use case consider:
- Valid input and expected result.
- Invalid and boundary input.
- Missing or unauthorized resource.
- Duplicate request and replay.
- Concurrent conflicting requests.
- Timeout and dependency failure.
- Partial failure and recovery.
- State transition rejection.
- Audit/telemetry side effects where contractually important.

Financial tests must cover amount precision, currency mismatch, rounding, duplicate posting, reversal, callback replay, out-of-order events, and reconciliation mismatch.

Bulk pipeline tests must cover malformed files, encoding, large files, row-level errors, duplicate rows, partial acceptance, cancellation, retry/resume, and resource bounds.

## Test design
- Test behaviour, not private function names or internal implementation.
- Use deterministic clocks, IDs, and provider responses where possible.
- Avoid real network calls in ordinary unit tests.
- Use behaviours or explicit adapter boundaries for external dependencies.
- Use sandbox/test credentials and provider test environments for contract tests.
- Use SQL Sandbox correctly and understand shared vs manual mode for async tests.
- Do not run database-dependent tests concurrently unless ownership/isolation is configured correctly.
- Assert meaningful error shape, not fragile full exception text.
- Do not make tests pass by weakening production validation.

## Concurrency tests
- Use barriers/synchronization rather than arbitrary sleeps.
- Exercise simultaneous duplicate requests against real database constraints.
- Assert exactly one durable business effect where the design promises deduplication.
- Test worker claiming and competing updates.
- Test timeout semantics and ensure retries do not duplicate side effects.

## Quality gates
Run project-configured checks. Typical checks:
```bash
mix format --check-formatted
mix compile --warnings-as-errors
mix test
mix credo --strict
mix dialyzer
```
Not every repository has every tool. Do not add tools automatically without considering project policy.

Review migrations and lockfile changes. Check for secrets, unsafe logging, missing authorization, unbounded work, and API compatibility.

## Definition of done
- Behaviour meets acceptance criteria.
- Error paths and security boundaries are covered.
- Tests pass, or failures are clearly reported.
- Formatting/compile/static checks are run where available.
- Database migrations are reviewed for production safety.
- Operational signals and recovery path exist for critical workflows.
- Documentation/configuration changes are included.
