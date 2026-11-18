# Official documentation and reference policy

Use these official sources as starting points. Always select documentation matching the versions installed in the target repository.

## Core language and runtime
- Elixir documentation: https://elixir-lang.org/docs/
- Elixir getting started: https://elixir-lang.org/getting-started/introduction.html
- Elixir compatibility/deprecations: https://elixir-lang.org/compatibility-and-deprecations.html
- Erlang/OTP documentation: https://www.erlang.org/doc/
- OTP design principles: https://www.erlang.org/doc/system/design_principles.html

## Phoenix and data
- Phoenix guides: https://hexdocs.pm/phoenix/overview.html
- Phoenix LiveView: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html
- Ecto: https://hexdocs.pm/ecto/Ecto.html
- Ecto SQL: https://hexdocs.pm/ecto_sql/Ecto.Adapters.SQL.html
- Oban: https://hexdocs.pm/oban/Oban.html
- Telemetry: https://hexdocs.pm/telemetry/readme.html

## Agent Skill format
- Anthropic Agent Skills overview: https://docs.anthropic.com/en/docs/agents-and-tools/agent-skills/overview
- Anthropic skills repository: https://github.com/anthropics/skills
- Agent Skills specification: https://agentskills.io/specification

## Research and version discipline
1. Inspect `mix.lock`, `mix.exs`, `.tool-versions`, `mise.toml`, and runtime versions.
2. Open the official docs for the installed version, not just the latest `main` branch.
3. Check changelogs/release notes when relying on recently introduced APIs.
4. Prefer official documentation and source code over copied snippets and blog posts.
5. Treat third-party examples as illustrative until verified.
