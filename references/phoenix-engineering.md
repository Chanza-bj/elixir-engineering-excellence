# Phoenix engineering: MVC, LiveView, Channels, Presence, APIs

## Application boundaries
Phoenix is the transport and interaction layer. Use contexts as cohesive application-facing APIs. Keep business policy in domain/application modules rather than controllers, LiveViews, socket callbacks, or templates.

Typical responsibilities:
- Router: route and pipeline composition.
- Plug: cross-cutting HTTP concerns such as authentication context, request IDs, rate limiting, and parsing.
- Controller: protocol boundary, authorization, call application capability, map result to response.
- Context/application service: use-case orchestration and domain boundary.
- Schema/changeset: persistence mapping and input validation.
- LiveView: stateful server-driven UI orchestration and presentation.
- Channel: real-time topic protocol and event boundary.
- Function component: reusable presentation.

Do not create one context per schema automatically. A context should express a meaningful capability and protect its invariants.

## MVC and REST
- Keep controllers thin and explicit.
- Validate input at the boundary; authorize each action.
- Use allowlists for accepted fields. Never pass arbitrary client params into privileged changesets.
- Use explicit JSON serializers/views or response maps; do not expose internal schema fields accidentally.
- Define stable error envelopes and appropriate HTTP status codes.
- Use pagination with maximum page sizes. Define sort/filter allowlists.
- Use request IDs and correlation IDs.
- Apply rate limits and payload limits to expensive or sensitive endpoints.
- Make create/update operations safe against retries where duplicate requests are possible.
- Do not rely on route obscurity for security.

## Authentication and authorization
- Authentication answers who the caller is; authorization answers what that identity may do.
- Authorize at every server-side action, including LiveView events and Channel events.
- Derive tenant, user, account, and role from verified server-side identity and policy. Never trust client-supplied ownership fields.
- Prevent insecure direct object references by scoping lookups to authorized ownership/tenant.
- Use CSRF protections for browser session flows and secure cookie settings.
- Keep secrets and tokens out of assigns, URLs, logs, and rendered HTML.
- Consider session revocation, expiry, rotation, and multi-factor requirements for sensitive systems.

## LiveView
- Treat the client as untrusted. Events and params can be forged.
- Re-check authorization for every sensitive event; mount-time authorization alone may become stale.
- Keep assigns bounded. Do not assign huge datasets or secrets.
- Use streams or paginated queries for large collections.
- Move expensive work out of synchronous event handlers; use supervised async operations or background jobs and expose progress.
- Handle stale UI state and duplicate event submissions.
- Keep domain logic in contexts/services, not event handlers.
- Use components for reusable UI, not as a substitute for domain boundaries.
- Understand connected vs disconnected mount and avoid duplicate side effects during mount.

## Channels and Presence
- Authorize socket connections and topic joins.
- Validate every inbound event and enforce per-topic/per-user permissions.
- Use Presence for ephemeral online/availability state, not authoritative business state.
- Use PubSub/Channels for notification and fan-out; delivery is not durable unless paired with durable storage.
- Define reconnect, resubscribe, and missed-event recovery behaviour. A reconnecting client should fetch authoritative current state.
- Do not broadcast secrets or sensitive financial payloads.
- For high fan-out, consider payload size, topic cardinality, node topology, and rate limits.

## Distributed Phoenix
- Confirm cluster formation and node discovery for the actual runtime platform.
- Verify PubSub adapter and deployment configuration across nodes.
- Understand that Presence is distributed ephemeral state, not a transaction coordinator.
- Do not assume local ETS, Registry, process names, or caches are shared across nodes.
- Use durable database/job/event mechanisms for business-critical cross-node work.
- Test node loss, reconnect, and rolling deployment scenarios where availability matters.

## API design
- Define contract, authentication, authorization, idempotency, pagination, and error semantics before implementation.
- Use OpenAPI or equivalent contract documentation where appropriate.
- Validate content type, body size, encoding, and schema.
- For webhooks, see `fintech-and-banking.md`.
- For outbound HTTP, see `fintech-and-banking.md` and `production-engineering.md`.

## Version awareness
Phoenix conventions evolve. Inspect the installed `phoenix`, `phoenix_live_view`, and related versions. Verify current generator output and official versioned guides rather than copying an example from an older book without adaptation.
