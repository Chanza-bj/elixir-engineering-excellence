# Code patterns for common idioms

These are starting points for idioms that are easy to get subtly wrong. Module and app names (`MyApp`, `MyAppWeb`) are placeholders. Check every option against the dependency versions in the project's `mix.lock` before using it.

## 1. Webhook: keep the raw body and verify the signature

`Plug.Parsers` consumes the body, so the bytes the provider signed are gone unless you keep them. Keep them with a custom `body_reader`.

```elixir
defmodule MyAppWeb.CacheRawBody do
  @moduledoc """
  `Plug.Parsers` body reader that keeps the raw request body in
  `conn.assigns.raw_body` for webhook signature verification.
  """

  @doc "Reads the body as `Plug.Conn.read_body/2` does and accumulates the raw chunks."
  def read_body(conn, opts) do
    case Plug.Conn.read_body(conn, opts) do
      {:ok, body, conn} -> {:ok, body, append(conn, body)}
      {:more, body, conn} -> {:more, body, append(conn, body)}
      {:error, reason} -> {:error, reason}
    end
  end

  # Large bodies arrive in several chunks; keep every chunk, not just the last.
  defp append(conn, chunk) do
    Plug.Conn.assign(conn, :raw_body, [conn.assigns[:raw_body] || "" | chunk])
  end
end
```

In the endpoint:

```elixir
plug Plug.Parsers,
  parsers: [:urlencoded, :multipart, :json],
  pass: ["*/*"],
  body_reader: {MyAppWeb.CacheRawBody, :read_body, []},
  json_decoder: Phoenix.json_library()
```

If keeping every body costs too much memory, apply the reader only to webhook routes, for example with a separate pipeline or by matching on `conn.request_path` inside `read_body/2`.

Verification. Follow the provider's exact algorithm, header names, and timestamp format.

```elixir
defmodule MyApp.Webhooks.Signature do
  @moduledoc """
  HMAC-SHA256 webhook signature verification with a replay window.
  """

  @tolerance_seconds 300

  @doc """
  Returns `:ok` only when the signature over `"timestamp.raw_body"` matches and
  the timestamp falls inside the tolerance window.
  """
  @spec verify(iodata(), String.t(), String.t(), binary()) ::
          :ok | {:error, :invalid_signature | :stale_timestamp | :malformed_timestamp}
  def verify(raw_body, timestamp, signature_hex, secret) do
    with {ts, ""} <- Integer.parse(timestamp),
         :ok <- check_window(ts) do
      expected =
        :crypto.mac(:hmac, :sha256, secret, [timestamp, ".", raw_body])
        |> Base.encode16(case: :lower)

      if Plug.Crypto.secure_compare(expected, String.downcase(signature_hex)) do
        :ok
      else
        {:error, :invalid_signature}
      end
    else
      # Order matters: {:error, _} is also a 2-tuple and must match first.
      {:error, _} = error -> error
      :error -> {:error, :malformed_timestamp}
      {_int, _trailing} -> {:error, :malformed_timestamp}
    end
  end

  # Rejects events outside the replay window in either direction.
  defp check_window(ts) do
    if abs(System.system_time(:second) - ts) <= @tolerance_seconds,
      do: :ok,
      else: {:error, :stale_timestamp}
  end
end
```

After verification, persist the event to the inbox, using the provider event ID as a unique key, and acknowledge it (section 3). Do the processing asynchronously.

## 2. Bounded concurrency with `Task.async_stream`

```elixir
MyApp.TaskSupervisor
|> Task.Supervisor.async_stream_nolink(
  items,
  &MyApp.Provider.fetch/1,
  max_concurrency: 8,
  timeout: 15_000,
  on_timeout: :kill_task,
  ordered: false
)
|> Enum.reduce(%{ok: [], failed: []}, fn
  {:ok, {:ok, result}}, acc -> %{acc | ok: [result | acc.ok]}
  {:ok, {:error, reason}}, acc -> %{acc | failed: [reason | acc.failed]}
  {:exit, reason}, acc -> %{acc | failed: [{:exit, reason} | acc.failed]}
end)
```

- Size `max_concurrency` from the real limit: the Repo pool, the provider's rate limit, or memory. Do not default to `System.schedulers_online()` for I/O-bound work.
- Without `on_timeout: :kill_task`, a timeout crashes the caller.
- `async_stream_nolink` keeps one crashing task from taking down the caller. Plain `Task.async_stream` links each task to the caller.
- A killed task may already have performed its side effect, so the work must be idempotent.

## 3. Idempotent insert backed by a unique constraint

Migration:

```elixir
create unique_index(:inbox_events, [:provider, :provider_event_id])
```

Insert:

```elixir
def record_event(provider, event_id, payload) do
  %InboxEvent{}
  |> InboxEvent.changeset(%{provider: provider, provider_event_id: event_id, payload: payload})
  |> Repo.insert(
    on_conflict: :nothing,
    conflict_target: [:provider, :provider_event_id],
    returning: true
  )
  |> case do
    # With on_conflict: :nothing, a conflicting insert returns a struct whose id is nil.
    {:ok, %InboxEvent{id: nil}} -> {:ok, :duplicate}
    {:ok, event} -> {:ok, {:new, event}}
    {:error, changeset} -> {:error, changeset}
  end
end
```

To return the original row on a duplicate, fetch it by the unique key after `:duplicate`. Where the request must be idempotent and not just deduplicated, compare a stored request fingerprint to detect a conflicting replay.

For a business write plus an outbox record that must commit together:

```elixir
Ecto.Multi.new()
|> Ecto.Multi.insert(:payment, Payment.create_changeset(attrs))
|> Ecto.Multi.insert(:outbox, fn %{payment: p} ->
  Outbox.changeset(%{topic: "payment.created", aggregate_id: p.id})
end)
|> Repo.transaction()
```

Do not call the provider inside this transaction. A worker claims outbox rows after the commit.

## 4. Streaming export with bounded memory

`Repo.stream/2` only works inside a transaction. Keep that transaction's duration in mind (vacuum, the connection it holds). For very large or long exports, use keyset pagination instead.

```elixir
Repo.transaction(
  fn ->
    from(t in Transaction,
      where: t.org_id == ^scope.org_id,
      order_by: [asc: t.id],
      select: [t.id, t.amount, t.currency, t.inserted_at]
    )
    |> Repo.stream(max_rows: 1_000)
    |> Stream.map(&encode_csv_row/1)
    |> Stream.into(File.stream!(path))
    |> Stream.run()
  end,
  timeout: :infinity
)
```

Keyset alternative, which needs no long transaction:

```elixir
def page_after(scope, last_id, limit) do
  from(t in Transaction,
    where: t.org_id == ^scope.org_id and t.id > ^last_id,
    order_by: [asc: t.id],
    limit: ^limit
  )
  |> Repo.all()
end
```

Neutralize spreadsheet formula injection in `encode_csv_row/1` for cells that start with `=`, `+`, `-`, `@`, tab, or CR.

## 5. Oban job uniqueness

```elixir
defmodule MyApp.Workers.SettlePayment do
  @moduledoc """
  Settles one payment. Unique per payment while the job is pending or running.
  """
  use Oban.Worker,
    queue: :payments,
    max_attempts: 10,
    unique: [keys: [:payment_id], period: :infinity, states: [:available, :scheduled, :executing, :retryable]]

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"payment_id" => id}}) do
    MyApp.Payments.settle(id)
  end
end
```

- Oban uniqueness reduces duplicate enqueues. It is not a business invariant. `settle/1` must still be idempotent and guarded by a database state transition.
- The accepted `unique` options and state names differ between Oban versions. Check the installed version's docs.
- Test with `use Oban.Testing, repo: MyApp.Repo`, using `assert_enqueued/1` and `perform_job/2`.

## 6. Concurrency test against real constraints

```elixir
test "concurrent duplicate deliveries record exactly one event" do
  parent = self()

  tasks =
    for _ <- 1..10 do
      Task.async(fn ->
        Ecto.Adapters.SQL.Sandbox.allow(MyApp.Repo, parent, self())
        MyApp.Inbox.record_event("acme", "evt_123", %{})
      end)
    end

  results = Task.await_many(tasks, 5_000)

  assert Enum.count(results, &match?({:ok, {:new, _}}, &1)) == 1
  assert Repo.aggregate(InboxEvent, :count) == 1
end
```

- `Task` processes inherit sandbox access through `$callers`, so the explicit `Sandbox.allow/3` is only strictly needed for processes not started by `Task` (raw `spawn`, GenServers). It is shown here to make the ownership explicit.
- The sandbox wraps each test in a transaction, so the "concurrent" inserts are serialized on one connection. This test checks the conflict-handling code path, not true parallel races at the database level. To test real races, use a test that is not sandboxed (one that cleans up after itself) or a dedicated integration environment.
- Never use `Process.sleep/1` to "make" a race happen.
