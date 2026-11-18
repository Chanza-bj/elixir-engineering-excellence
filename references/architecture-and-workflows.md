# Architecture decisions and engineering workflow

## Start with the use case
Write a short statement:
- Actor and intent.
- Preconditions.
- Expected result.
- Durable effects.
- Invariants.
- Failure and retry expectations.
- Security boundary.
- Operational requirements.

## Choose architecture proportionately
Use a modular monolith by default unless independent deployment, scaling, ownership, or fault-isolation requirements justify service separation. A well-structured Phoenix application with clear contexts is often easier to operate than premature microservices.

Choose:
- Plain module for stateless rules.
- Context/use-case module for application orchestration.
- Ecto transaction for atomic database changes.
- GenServer for owned serialized state or coordination.
- Task/Task.Supervisor for bounded finite work.
- Oban or equivalent durable job system for work that must survive request/node restarts.
- PubSub/Channel for notifications and real-time fan-out, not durable delivery.
- Inbox/outbox for reliable handoff across database and asynchronous boundaries.
- Streaming pipeline for large input/output with explicit back-pressure.
- Separate service only when a real operational boundary exists.

## Decision record
For meaningful architecture choices, document:
- Context/problem.
- Chosen approach.
- Alternatives considered.
- Trade-offs and failure modes.
- Security and data implications.
- Operational cost.
- Conditions that would justify revisiting the decision.

## Implementation sequence
1. Inspect repository and constraints.
2. Reproduce/understand existing behaviour.
3. Define acceptance criteria and invariants.
4. Design data model and constraints.
5. Design side-effect and retry boundaries.
6. Implement smallest vertical slice.
7. Add tests for success and failure.
8. Run formatter/compiler/tests/static checks.
9. Review security, performance, observability, migrations.
10. Document deployment and operational steps.

## Existing-codebase changes
- Do not replace established architecture merely because another pattern is fashionable.
- Preserve public contracts unless explicitly authorized to change them.
- Identify compatibility risks before migrations or dependency updates.
- Make incremental refactors with tests around existing behaviour.
- When code is broken, diagnose the actual failure before broad refactoring.
- If evidence is incomplete, state assumptions and ask only for information that materially affects correctness.

## Communicating uncertainty
Do not fabricate APIs, configuration keys, library behaviour, benchmark results, or test outcomes. Inspect source/docs for installed versions. If unable to verify, label the uncertainty and provide a safe way to confirm.
