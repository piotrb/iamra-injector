<!-- OPENSPEC:START -->
# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:
- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:
- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->

# CLAUDE Best Practices

## Testing and TDD
- Start with contracts: sketch public interfaces and file/module layout before implementation.
- Create skeleton files and method stubs, then add failing tests that express desired behavior; only then implement to make tests pass.
- Keep the red/green/refactor loop tight; no long stretches of untested coding.
- Do not accept compilation/type errors as “failing tests”; code must compile before tests can be considered red/green.
- Prefer higher-signal tests over brittle mocks; when isolation is needed, use dependency injection to supply fakes/stubs with realistic behavior.
- Exercise integration paths where possible (e.g., rendering Helm templates, exercising webhook handlers with admission review fixtures).

## Design and code quality
- Favor dependency injection and explicit configuration (values.yaml, env vars) over globals and hidden state.
- Keep functions small and single-purpose; push business logic into pure helpers that are easy to unit test.
- Structure logs as JSON with stable fields; avoid noisy debug unless gated by level.
- Validate inputs early and fail fast with actionable errors (especially around issuers, CA injection, and required annotations/values).
- Default to least privilege in RBAC and network exposure; make opt-in features explicit.

## Delivery discipline
- Treat lint/format warnings as errors; keep the tree buildable at all times.
- When adding new behavior, land tests in the same change set; avoid leaving TODOs for coverage.
- Prefer reproducible scripts (e.g., make targets) for common flows: lint, test, template rendering, and image/chart builds.
- Write documentation alongside the code change (same phase/PR), not afterward.
- Use automation/CI to generate and publish Helm chart values/README docs to keep them in sync.