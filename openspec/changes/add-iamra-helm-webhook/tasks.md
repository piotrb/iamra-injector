# Tasks: add-iamra-helm-webhook (check off at every stop; user validates stubs/tests before impl)

## Workflow guardrails (apply to every phase; not a checklist)
- Always: draft stubs/tests → show user → get explicit approval → implement → show user before moving forward.
- Do not merge/continue a phase without user sign-off on tests and on implemented stubs.
- Never push to any remote (no `git push`).
- Check off completed tasks in this file before committing a phase.
- After user confirms a phase, make a local commit for that phase before moving on.
- Document updates alongside each phase (no deferrals).
- Prefer automation/CI to generate/publish Helm values/README docs to keep them in sync.

## Phase 0 – Contracts and Test Plan (paper first)
- [x] Finalize values/annotation contract (required `trustAnchorArn`, `region`; opt-in namespace gate; required pod annotations).
- [x] Document cainjector + issuer hard requirements; add to spec delta if missing.
- [x] Draft test plan: helm render cases (required values, issuer toggles, opt-in gating), webhook handler unit cases, optional envtest smoke.
- [x] Review plan with user; check off only after approval.

## Phase 1 – Helm bootstrap (cainjector check + issuers only)
- [ ] Scaffold chart skeleton: values file, schema stub, templates directory, example values focused on TLS/issuer pieces.
- [ ] Red helm render/unit tests: fail without cainjector; fail when required values (`trustAnchorArn`, `region`) are unset; render webhook Issuer/Certificate (service DNS SAN) and workload ClusterIssuer.
- [ ] Implement minimal templates: Helm `fail` guard for cainjector, webhook `Issuer` + serving `Certificate`, workload `ClusterIssuer`; no webhook Deployment/Service yet.
- [ ] Walk user through renders/tests; get approval before moving forward.

## Phase 2 – CI/CD: chart publish to gh-pages
- [ ] GitHub Actions: helm lint + helm-unittest/ct; package chart and publish to gh-pages branch.
- [ ] Validate workflow locally with `act` or job-level dry runs.
- [ ] Review workflow plan/results with user; check off after approval.

## Phase 3 – Webhook scaffold + red tests
- [ ] Scaffold webhook module/handler stub; add red unit tests for mutation contract (namespace gate, required pod annotations, idempotency, validation of overrides).
- [ ] Walk user through stubs/tests; get approval before implementation; then check off.

## Phase 4 – Minimal Passing Chart Render
- [ ] Implement values schema + minimal templates (Namespace, Service, Deployment shell, MutatingWebhookConfiguration with CABundle placeholder).
- [ ] Add Helm `fail` guards for missing issuer references when `create=false` and required values.
- [ ] Turn Phase 3 helm tests green with minimal values (reuse issuers from Phase 1).
- [ ] Minimize AWS examples dependency: copy only required assets directly (no submodules), document provenance in code/docs.
- [ ] Demo renders to user; check off after confirmation.

## Phase 5 – Mutation Logic
- [ ] Implement webhook handler: namespace opt-in check; require role/profile annotations; optional overrides; inject sidecar + IMDS env on main containers; add hash/idempotency annotation.
- [ ] Extend unit tests: positive injection, no-op when not opted in or missing annotations, idempotency stability, reject bad overrides (token duration/region).
- [ ] Present handler/tests to user; check off post-approval.

## Phase 6 – Sidecar Wiring and Defaults
- [ ] Wire sidecar image/port/log level/token defaults; ensure env on app containers uses IMDS endpoint + IPv4 mode only.
- [ ] Tests: rendered pod shows sidecar image/tag/pullPolicy/port; overrides for audience/region/token-duration honored.
- [ ] Show rendered outputs/tests to user; check off after approval.

## Phase 7 – Image & chart CI hardening
- [ ] GitHub Actions: multi-arch GHCR build/push for webhook from `github.com/piotrb/iamra-injector` to `ghcr.io/piotrb/iamra-injector`; chart lint/test gates remain.
- [ ] Validate workflows locally with `act` or at least job-level verification steps.
- [ ] Review workflow plan/results with user; check off after approval.

## Phase 8 – Example/Hello-World Job (first live cluster exercise)
- [ ] Add standalone example Job/chart running `aws sts get-caller-identity` with required annotations.
- [ ] Tests: helm render shows expected annotations/injection markers when enabled.
- [ ] Run first live cluster smoke after Phase 5 wiring and CI/CD are in place (install chart + example; validate sidecar injection and STS call).
- [ ] Demo to user; check off after approval.

## Phase 9 – Observability Hooks
- [ ] Add optional Prometheus ServiceMonitor/PodMonitor behind `prometheus.enabled`; render should fail if enabled but CRDs absent.
- [ ] Tests: monitors included/excluded per flag; failure path when CRDs missing.
- [ ] Review with user; check off after approval.

## Phase 10 – Docs
- [ ] Chart README: values/annotations table, issuer expectations, cainjector requirement, k3s arm64 notes, rollback guidance.
- [ ] How-to: self-signed CA setup, Terraform sketch for trust anchor/profile/role, hello-world walkthrough and expected `aws sts get-caller-identity` output.
- [ ] Add markdown lint/checks if available.
- [ ] Present docs to user; check off after approval.
