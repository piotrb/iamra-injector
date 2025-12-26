# Tasks: add-iamra-helm-webhook (check off at every stop; user validates stubs/tests before impl)

## Workflow guardrails (apply to every phase; not a checklist)
- Always: draft stubs/tests → show user → get explicit approval → implement → show user before moving forward.
- Do not merge/continue a phase without user sign-off on tests and on implemented stubs.
- Never push to any remote (no `git push`).
- After user confirms a phase, make a local commit for that phase before moving on.
- Document updates alongside each phase (no deferrals).
- Prefer automation/CI to generate/publish Helm values/README docs to keep them in sync.

## Phase 0 – Contracts and Test Plan (paper first)
- [ ] Finalize values/annotation contract (required `trustAnchorArn`, `region`; opt-in namespace gate; required pod annotations).
- [ ] Document cainjector + issuer hard requirements; add to spec delta if missing.
- [ ] Draft test plan: helm render cases (required values, issuer toggles, opt-in gating), webhook handler unit cases, optional envtest smoke.
- [ ] Review plan with user; check off only after approval.

## Phase 1 – Scaffold + Red Tests
- [ ] Scaffold chart skeleton: values file, schema stub, templates directory, example values.
- [ ] Add helm render/unit tests that currently fail: missing required values error, missing cainjector error, webhook cert SANs include service DNS, namespace opt-in rendered.
- [ ] Scaffold webhook module/handler stub; add red unit tests for mutation contract (namespace gate, required pod annotations, idempotency, validation of overrides).
- [ ] Walk user through stubs/tests; get approval before implementation; then check off.

## Phase 2 – Minimal Passing Chart Render
- [ ] Implement values schema + minimal templates (Namespace, Service, Deployment shell, Issuer/Certificate, MutatingWebhookConfiguration with CABundle placeholder).
- [ ] Add Helm `fail` guards for missing cainjector/issuers/required values.
- [ ] Turn Phase 1 helm tests green with minimal values.
- [ ] Minimize AWS examples dependency: copy only required assets directly (no submodules), document provenance in code/docs.
- [ ] Demo renders to user; check off after confirmation.

## Phase 3 – Mutation Logic
- [ ] Implement webhook handler: namespace opt-in check; require role/profile annotations; optional overrides; inject sidecar + IMDS env on main containers; add hash/idempotency annotation.
- [ ] Extend unit tests: positive injection, no-op when not opted in or missing annotations, idempotency stability, reject bad overrides (token duration/region).
- [ ] Present handler/tests to user; check off post-approval.

## Phase 4 – TLS Issuers and CA Injection
- [ ] Flesh Issuer/Certificate templates (defaults + existing issuer refs), workload ClusterIssuer defaults, checksum rollout on TLS/config changes.
- [ ] Helm tests: create=true renders issuers/certs; create=false respects external refs; render fails without cainjector for CABundle.
- [ ] Optional envtest/kubewebhook smoke for TLS loading.
- [ ] Review renders/tests with user; check off after approval.

## Phase 5 – Sidecar Wiring and Defaults
- [ ] Wire sidecar image/port/log level/token defaults; ensure env on app containers uses IMDS endpoint + IPv4 mode only.
- [ ] Tests: rendered pod shows sidecar image/tag/pullPolicy/port; overrides for audience/region/token-duration honored.
- [ ] Show rendered outputs/tests to user; check off after approval.

## Phase 6 – CI/CD Early Enablement (needed for Phase 6 deploy)
- [ ] GitHub Actions: multi-arch GHCR build/push for webhook; chart lint/test (helm lint + helm-unittest/ct) gated before publish to gh-pages; optional helper image build only if strictly required.
- [ ] Validate workflows locally with `act` or at least job-level verification steps.
- [ ] Review workflow plan/results with user; check off after approval.

## Phase 7 – Example/Hello-World Job (first live cluster exercise)
- [ ] Add standalone example Job/chart running `aws sts get-caller-identity` with required annotations.
- [ ] Tests: helm render shows expected annotations/injection markers when enabled.
- [ ] Run first live cluster smoke after Phase 5 wiring and CI/CD are in place (install chart + example; validate sidecar injection and STS call).
- [ ] Demo to user; check off after approval.

## Phase 8 – Observability Hooks
- [ ] Add optional Prometheus ServiceMonitor/PodMonitor behind `prometheus.enabled`; render should fail if enabled but CRDs absent.
- [ ] Tests: monitors included/excluded per flag; failure path when CRDs missing.
- [ ] Review with user; check off after approval.

## Phase 9 – Docs
- [ ] Chart README: values/annotations table, issuer expectations, cainjector requirement, k3s arm64 notes, rollback guidance.
- [ ] How-to: self-signed CA setup, Terraform sketch for trust anchor/profile/role, hello-world walkthrough and expected `aws sts get-caller-identity` output.
- [ ] Add markdown lint/checks if available.
- [ ] Present docs to user; check off after approval.
