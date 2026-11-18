# Production engineering, deployment, and observability

## Configuration
- Keep non-secret defaults in application config and environment-specific runtime settings in runtime configuration.
- Validate required environment variables and parse types at startup.
- Fail fast with actionable messages when critical configuration is missing or malformed.
- Never commit secrets or print them in diagnostics.
- Avoid configuration sprawl and implicit fallback to production endpoints in development/test.

## Releases and deployment
- Inspect current deployment model before changing it: release, container, systemd, Kubernetes, platform-as-a-service, or other.
- Build reproducibly with pinned versions and lockfiles.
- Understand release boot, migrations, runtime config, health checks, and shutdown.
- Separate migration execution from app startup when appropriate.
- Use expand/contract database changes for rolling deployments.
- Ensure old and new application versions can coexist during rollout.
- Define rollback or forward-fix strategy.
- Drain/stop nodes gracefully and account for in-flight requests and jobs.
- Never assume a successful build means a successful production deployment.

## Observability
Use structured logs, metrics, traces, and correlation IDs:
- HTTP request count, status, latency.
- Repo query latency and pool queue time.
- Job queue depth, queue latency, attempt count, execution duration, failure rate.
- Provider request latency, error category, timeout and circuit state.
- Import/export throughput, rows processed, memory, and failure stage.
- VM memory, scheduler utilization, process count, mailbox length, and reductions where appropriate.

Keep metric labels low-cardinality. Put transaction IDs and request IDs in logs/traces, not metric labels. Redact sensitive information.

## Health checks
- Liveness: is the process/runtime alive enough to continue?
- Readiness: can this instance safely receive traffic given required dependencies?
- Avoid making liveness fail merely because a transient external provider is unavailable.
- Use bounded dependency checks and avoid cascading health-check load.
- Report dependency state without leaking credentials or topology details publicly.

## Incident response
1. Establish impact, start time, affected service/tenant/transaction range.
2. Preserve logs, traces, provider references, and relevant evidence.
3. Determine whether issue is code, configuration, infrastructure, database, network, provider, or data.
4. Avoid destructive repair before understanding durable state.
5. Contain safely; do not replay financial operations blindly.
6. Restore service with reversible steps where possible.
7. Reconcile business state after technical recovery.
8. Document root cause, contributing factors, detection gap, remediation, and prevention.

## Performance
- Measure with representative load and payloads.
- Establish latency/throughput/error targets.
- Tune concurrency with DB pool and downstream capacity in mind.
- Profile CPU, memory, allocations, query plans, and mailbox pressure.
- Separate latency-sensitive work from bulk/background work.
- Apply load shedding and rate limits intentionally.
- Do not scale horizontally to hide an unbounded queue or inefficient query.
