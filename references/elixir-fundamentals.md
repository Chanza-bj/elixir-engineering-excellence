# Elixir fundamentals and idioms

## Functional design
- Prefer small, composable functions with explicit inputs and outputs.
- Keep pure transformations separate from I/O, persistence, clocks, randomness, and network access.
- Pass dependencies explicitly at application boundaries; avoid hidden process dictionary or global configuration dependencies in domain logic.
- Use immutable data transformations. Do not emulate mutable object graphs.
- Use pattern matching to express valid shapes and branch on meaningful outcomes.
- Use `with` for linear success paths with explicit `else` handling; avoid deeply nested `case` expressions and avoid using `with` to obscure multiple unrelated branches.
- Use `Enum` for finite in-memory collections and `Stream` when laziness materially reduces memory or enables incremental processing.
- Remember that a Stream is lazy but not automatically bounded: the consumer and upstream source determine resource use.
- Prefer `Map`, structs, `MapSet`, `Keyword`, and standard data structures according to semantics, not habit.
- Use structs for known domain data shapes; maps for dynamic or external payloads.
- Avoid atomizing untrusted strings. Atoms are not garbage-collected; use existing atoms or string keys.
- Use `String` for UTF-8 text and binary operations for raw bytes. Do not assume every byte sequence is valid UTF-8.
- Use `Date`, `Time`, `NaiveDateTime`, and `DateTime` deliberately. Persist timestamps with a clear UTC/time-zone policy.
- Use `Decimal` for decimal arithmetic and currency; define rounding mode and scale explicitly.

## Errors and results
- Use tagged tuples such as `{:ok, value}` and `{:error, reason}` for expected operational outcomes.
- Raise for exceptional programmer errors or violated assumptions where crashing the current operation is appropriate.
- Do not use exceptions as ordinary branching for expected validation or lookup failures.
- Preserve error context while avoiding secret or personal data leakage.
- Do not rescue broadly unless there is a defined recovery action and the rescued exception classes are understood.
- Avoid `{:error, :unknown}` when a structured reason would help callers recover or report accurately.

## Types and contracts
- Add `@spec` to public functions where it clarifies contracts, especially reusable libraries and domain boundaries.
- Use `@type` and `@type t` for important domain structures.
- Treat specs as documentation and Dialyzer input, not runtime validation.
- Define behaviours for replaceable infrastructure adapters when multiple implementations or meaningful test seams exist.
- Do not create abstractions solely to satisfy a theoretical future.

## Naming and modules
- Name modules by domain capability or responsibility.
- Keep modules cohesive. Split when responsibilities, reasons to change, or dependency direction differ.
- Prefer explicit function names over clever aliases and abbreviations.
- Keep public APIs small; mark implementation helpers private.
- Document non-obvious invariants, units, concurrency assumptions, and side effects. Do not narrate obvious syntax.
- Use `mix format` and project formatter configuration as authoritative formatting rules.

## Performance
- Measure before optimizing.
- Understand list append cost, repeated traversals, copying between processes, large binaries, and memory retention.
- Prefer streaming or chunked work for large data.
- Avoid premature micro-optimization that makes code harder to reason about.
- Benchmark representative workloads and include realistic payload sizes and concurrency.

## Example: pure domain function
```elixir
defmodule Payments.Fee do
  @moduledoc "Calculates a fee using explicit decimal arithmetic."

  alias Decimal, as: D

  @spec calculate(Decimal.t(), Decimal.t()) :: Decimal.t()
  def calculate(amount, rate) do
    amount
    |> D.mult(rate)
    |> D.round(2, :half_up)
  end
end
```

The example is illustrative: the calling boundary must validate amount, rate, currency, and rounding policy.
