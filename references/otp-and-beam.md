# OTP, BEAM, concurrency, and distribution

## Process model
A BEAM process has isolated process state, a mailbox, and independent failure. Processes are not OS threads. Message passing avoids shared mutable memory, but message payloads, mailbox growth, scheduling, and copying still have costs.

Design each process around a clear lifecycle and responsibility:
- What state does it own?
- Who starts and supervises it?
- Who may send it messages?
- What is the mailbox growth bound?
- What happens on restart?
- Is state reconstructible from durable storage?
- Can requests block its callbacks?

## Choose the right abstraction
- Plain function: stateless calculation or orchestration.
- `Task`: finite asynchronous computation with a caller or supervisor responsible for its result/lifecycle.
- `Task.Supervisor`: dynamically started tasks that must be supervised.
- `GenServer`: serialized stateful coordination or protocol endpoint.
- `Supervisor`: lifecycle management for related child processes.
- `DynamicSupervisor`: dynamically created long-lived children.
- `Registry`: local name/lookup mechanism.
- `Agent`: simple state wrapper only when its minimal abstraction is genuinely appropriate; do not use it as a default domain store.
- `:gen_statem`: explicit state machine with non-trivial state-dependent events/timeouts.
- `GenStage`/Broadway: demand/back-pressure pipeline when the workload benefits from producer-consumer flow and bounded demand.

Do not introduce a GenServer just to hide a function call or serialize access to a database that already provides correct transactional primitives.

## Supervision
- Define child specs with stable IDs and restart semantics.
- Use `:permanent`, `:transient`, and `:temporary` based on whether a child should restart after normal or abnormal exit.
- Choose strategy based on dependency graph:
  - `:one_for_one`: siblings are independent.
  - `:one_for_all`: siblings must restart together.
  - `:rest_for_one`: later children depend on earlier children.
- Set restart intensity and period intentionally.
- Avoid restart loops caused by invalid configuration or unavailable permanent dependencies without a recovery plan.
- Ensure child shutdown timeouts are sufficient but bounded.
- Remember supervisors restart processes, not business operations. A restarted worker may repeat work; durable jobs and idempotency must handle this.

## Calls, messages, and timeouts
- Prefer documented APIs (`GenServer.call`, `cast`, `send`) over ad-hoc protocols when a behaviour fits.
- Set meaningful call timeouts and handle exits/timeouts at the correct boundary.
- `cast` is fire-and-forget from the caller's perspective; do not use it when the caller needs confirmation.
- A timeout only tells the caller it did not receive a response in time. It does not prove the operation stopped.
- Keep callbacks short. Move slow I/O to supervised tasks or job workers when appropriate.
- Never perform unbounded work in `handle_info/2`.
- Avoid sending huge payloads; pass identifiers or references and retrieve data from storage when appropriate.
- Monitor mailbox length and process memory for critical services.

## Concurrency and back-pressure
- Bound concurrency based on database pool size, provider rate limits, CPU, memory, and downstream capacity.
- Avoid spawning one task per row for large files.
- Use chunking, streaming, demand, and queue limits.
- Define overload behaviour: reject, defer, shed low-priority work, or apply back-pressure.
- Do not assume more workers always mean more throughput.
- Avoid head-of-line blocking by separating work classes and queues when justified.

## Distribution
- Node names, cookies, DNS, ports, firewall rules, and cluster formation must be configured and secured deliberately.
- Distributed process registration and PubSub are not substitutes for durable storage.
- Networks partition. A node may be alive but unreachable. Membership can be stale.
- Do not assume exactly-once message delivery across nodes or external brokers.
- Use durable events/jobs, idempotent consumers, deduplication, and reconciliation for important work.
- Design node restart and rolling deployment behaviour.
- Avoid globally registered singletons as a scalability strategy without evaluating availability and contention.
- Use a distributed coordination system only when the consistency requirement justifies its complexity.

## Telemetry
Instrument process/task lifecycle, queue wait, execution time, failures, and throughput. Prefer `:telemetry` events at stable application boundaries and avoid high-cardinality metric labels such as raw user IDs, transaction IDs, or arbitrary URLs.

## Review questions
1. Is a process genuinely needed?
2. Is the work finite or long-lived?
3. Who owns the result?
4. What bounds concurrency and mailbox growth?
5. What happens after a crash halfway through side effects?
6. Is the state durable or reconstructible?
7. Does the supervisor strategy match dependencies?
8. Does multi-node behaviour tolerate partitions and duplicate delivery?
