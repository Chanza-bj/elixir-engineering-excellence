# Skill evaluation checklist

Use these tasks to evaluate whether an agent follows the skill. Evaluate the reasoning and implementation, not merely whether the output looks plausible.

## 1. Phoenix REST API
Ask the agent to implement a tenant-scoped resource endpoint with authentication, authorization, pagination, Ecto changesets, and JSON responses.
Pass criteria:
- Thin controller and cohesive context.
- Server-derived tenant scope.
- Explicit allowed params and stable error mapping.
- Tests for unauthorized access, invalid input, pagination, and success.
- No accidental schema field exposure.

## 2. OTP process design
Ask for a design to coordinate finite concurrent work and long-lived workers.
Pass criteria:
- Does not default to GenServer for stateless functions.
- Explains ownership, supervision, restart, timeout, and bounded concurrency.
- Handles process crash without assuming side effects are rolled back.
- Uses appropriate Task/Task.Supervisor/DynamicSupervisor/Oban choices.

## 3. Payment provider integration
Ask for payment initiation plus signed asynchronous callbacks.
Pass criteria:
- Decimal/integer money representation and currency validation.
- Durable idempotency with database uniqueness.
- Distinguishes definitive rejection from uncertain outcome.
- Verifies raw-body signature according to provider contract.
- Persists callback/inbox event and processes idempotently.
- Reconciliation and audit history included.
- No blind retry of uncertain payment.

## 4. Bulk file import
Ask for a large CSV/XLSX import with row-level validation and resumability.
Pass criteria:
- Streaming or bounded chunk processing.
- Upload limits, content validation, safe storage, authorization.
- Staging and progress tracking.
- Explicit partial/all-or-nothing semantics.
- Idempotent chunks and duplicate handling.
- Actionable row errors and bounded concurrency.
- Tests include malformed, duplicate, and interrupted batches.

## 5. Data extraction
Ask for a multi-million-row export.
Pass criteria:
- Keyset/streaming approach and bounded memory.
- Explicit snapshot consistency decision.
- Async generation and secure expiring download.
- Field authorization/redaction and audit.
- Does not hold a long transaction without analysis.

## 6. Production incident
Ask the agent to investigate a Phoenix app returning HTTP 200 while database health checks fail.
Pass criteria:
- Separates liveness/readiness and checks runtime config safely.
- Requests/inspects actual logs and configuration without exposing secrets.
- Verifies DB connectivity from the app runtime identity.
- Does not claim root cause without evidence.
- Proposes reversible diagnostics and confirms after remediation.

## 7. Code review
Provide code with float money, external HTTP inside a transaction, unbounded Task creation, and missing authorization.
Pass criteria:
- Identifies all issues and explains impact.
- Proposes concrete fixes aligned with current project versions.
- Adds tests for invariants and failure cases.

## Scoring
Score each criterion:
- 0: absent or incorrect.
- 1: mentioned but incomplete.
- 2: correctly implemented/explained with evidence.

Record:
- Task and project versions.
- Agent/tool version.
- Score by criterion.
- Compilation/test results.
- Any hallucinated API or unsupported claim.
- Regressions or over-engineering.


## Cross-cutting mandatory checks for every scenario

- **Security:** review authentication, authorization, tenant isolation, untrusted input handling, secrets, sensitive-data logging, resource limits, and relevant threat scenarios. A critical security or data-isolation failure is a failure regardless of the numeric score.
- **Documentation:** new modules and public functions have meaningful `@moduledoc`/`@doc`; non-obvious private logic has an explanatory comment; edits to existing code match its documentation style and do not retrofit comments onto untouched code. Comments explain intent/contracts/invariants rather than restating syntax. Any Elixir code shown must parse.
