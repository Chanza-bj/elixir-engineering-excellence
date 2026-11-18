# Anti-patterns and preferred alternatives

| Anti-pattern | Why it is harmful | Preferred approach |
|---|---|---|
| GenServer for every module | Adds lifecycle and message overhead without stateful need | Plain functions and contexts |
| One GenServer as durable ledger | Volatile state and restart/data-loss risk | Database-backed ledger and constraints |
| External HTTP inside DB transaction | Holds locks/connections; cannot atomically commit remote side effect | Persist intent, commit, call asynchronously, reconcile |
| Blind retry after payment timeout | Provider may already have processed request | Idempotency key, status inquiry, reconciliation |
| Float for money | Binary floating-point precision errors | Decimal or integer minor units |
| PubSub as guaranteed queue | Events can be missed during disconnect/restart | Durable job/outbox/event store |
| Unbounded tasks per row | Memory, scheduler, DB and provider overload | Bounded concurrency and chunking |
| Large `File.read!` import | Memory spikes and process pressure | Stream parser and staged chunks |
| `Enum.to_list` on huge stream | Defeats laziness | Consume incrementally |
| Catch-all `rescue` | Hides defects and corrupts error semantics | Rescue known exceptions at recovery boundary |
| Business logic in controller/LiveView | Coupled to transport and difficult to test | Context/use-case/domain modules |
| Trust client tenant/account IDs | Authorization bypass/IDOR | Derive and scope from authenticated server context |
| Schema changeset as only integrity layer | Race conditions can bypass application checks | Database constraints plus changeset annotations |
| Huge synchronous migration | Locks and deployment outage risk | Expand/contract and batched backfill |
| N+1 query | Unbounded DB round trips | Preload/join/select and inspect query plan |
| Mock every collaborator | Tests implementation, not contract | Real domain logic, narrow adapter seams |
| Retry loop in GenServer callback | Blocks process and can create hot loop | Backoff, supervised task/job, bounded retries |
| Global singleton for coordination | Bottleneck and node-failure hotspot | Partitioned/durable coordination where required |
| Log full provider payload | Leaks credentials and personal/financial data | Structured redacted fields and correlation references |
| Treat timeout as cancellation | Work may continue after caller gives up | Idempotent operation and explicit cancellation protocol |
