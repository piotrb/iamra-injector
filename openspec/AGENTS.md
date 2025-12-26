# OpenSpec Instructions

Guidance for specs/proposals in this repo (IAMRA Helm/webhook work).

## TL;DR
- Read `openspec/project.md` before planning or proposing changes.
- Use OpenSpec changes for new capabilities, architecture, or automation.
- Prefer spec deltas when adding/modifying capabilities; no time estimates.
- Validate assumptions and monitoring considerations in proposals.

## When to create a change
- New features/capabilities (e.g., Helm chart, webhook, automation).
- Breaking/architectural changes or security-impacting changes.
- Skip for typos or mechanical refactors.

## Workflow
1) Check existing changes/specs to avoid duplication.
2) Pick a verb-led `change-id` (kebab-case).
3) Scaffold `openspec/changes/<id>/` with `proposal.md`, `tasks.md`, optional `design.md`, and spec deltas under `specs/`.
4) Write deltas with `## ADDED|MODIFIED|REMOVED Requirements` and at least one `#### Scenario`.
5) No time estimates; focus on deliverables, risks, and validation.

## Directory shape
```
openspec/
├── AGENTS.md          # This guidance
├── project.md         # Repo-specific context
├── changes/
│   └── <change-id>/
│       ├── proposal.md
│       ├── tasks.md
│       ├── design.md (optional)
│       └── specs/
│           └── <capability>/spec.md
└── changes/archive/   # Completed changes
```

## Notes
- Prefer additive, templated, and multi-arch friendly designs.
- Document monitoring/observability expectations for new runtime components.
- Avoid timestamps in docs; git history is the source of truth.
