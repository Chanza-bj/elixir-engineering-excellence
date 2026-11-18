# Elixir Engineering Excellence

An opinionated, reusable Agent Skill for production-grade Elixir, OTP, BEAM, and Phoenix engineering.

## Contents

- `SKILL.md` — entry point and mandatory engineering standards.
- `references/` — specialist guidance for language, OTP, Phoenix, Ecto, security, fintech, ingestion, testing, production operations, and concrete code patterns (`code-patterns.md`).
- `scripts/validate_skill.exs` — validates frontmatter, name/description limits, reference links, and that every Elixir example parses.
- `evals/evaluation-checklist.md` — realistic tasks for assessing skill effectiveness.

## Install

### Claude Code
Copy the `elixir-engineering-excellence` directory into the appropriate Claude Code skills directory for your environment, commonly:
- Project: `.claude/skills/elixir-engineering-excellence/`
- User: `~/.claude/skills/elixir-engineering-excellence/`

### Claude.ai
Upload the skill package as a ZIP through the Skills interface, if available for your account/workspace.

### Other Agent Skills-compatible tools
Install the folder or ZIP according to that tool's Agent Skills support. The package uses the open `SKILL.md` folder convention and has no runtime dependencies.

## Use

Ask Claude to build, review, refactor, debug, test, or architect an Elixir/Phoenix system. The description in the YAML frontmatter is designed to trigger on those tasks.

The skill is a set of engineering instructions and references, not a compiler, runtime, security certification, or replacement for provider-specific documentation.

## Engineering policy

- Modern Elixir/OTP is preferred for new work.
- Existing projects retain their actual version and compatibility constraints.
- The agent must verify APIs against installed dependencies.
- Security, threat modelling, secure defaults, authorization, tenant isolation, and sensitive-data protection are mandatory engineering concerns.
- New modules and public functions are documented (`@moduledoc`/`@doc`); private code is commented where the reasoning is non-obvious; existing code follows the project's documentation style.
- Financial correctness, idempotency, auditability, bounded concurrency, and recoverability are mandatory concerns for financial workloads.

## Validate

```bash
elixir scripts/validate_skill.exs
```

## Research basis

The package is informed by official Elixir and Erlang/OTP documentation, Phoenix and Ecto conventions, and Anthropic's Agent Skills format. Consult `references/official-resources.md` for the maintained starting points.
