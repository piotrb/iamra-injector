# Phase 0 – Contracts and Test Plan (draft for approval)

This document captures the proposed value/annotation contract, issuer and cainjector requirements, and the initial test plan for Helm renders and webhook handler logic. Nothing is implemented yet.
Webhook code/image lives in `https://github.com/piotrb/iamra-injector` with GHCR target `ghcr.io/piotrb/iamra-injector`.

## Contract summary
- Required chart values: `trustAnchorArn`, `region` (regional IAM RA endpoint). No annotation fallback for either.
- Namespace gate: injection only when the namespace carries the opt-in marker (default `iamra.aws/enable: "true"`). Gate can be disabled via values to allow cluster-wide use.
- Required pod annotations: `iamra.aws/role-arn`, `iamra.aws/signing-profile-arn`.
- Optional pod annotations:
  - `iamra.aws/session-name` (default pod name)
  - `iamra.aws/audience` (default `sts.amazonaws.com`)
  - `iamra.aws/token-duration` (default 900s)
  - `iamra.aws/log-level` (default `info`)
  - `iamra.aws/region` (override only; otherwise chart value is used)
- Mutation behavior:
  - Inject IAMRA sidecar; keep cert/key/token inside sidecar (no shared volumes).
  - Add IMDS env wiring to app containers: `AWS_EC2_METADATA_SERVICE_ENDPOINT=http://169.254.169.254`, `AWS_EC2_METADATA_SERVICE_ENDPOINT_MODE=IPv4`. Region env only if provided explicitly.
  - Idempotency via marker/hash annotation to avoid double injection and to roll on config/CA changes.
- Issuer/TLS requirements:
  - Webhook TLS: default namespaced self-signed `Issuer` + serving `Certificate` for `iamra-webhook.iamra-system.svc`.
  - Workload certs: default self-signed `ClusterIssuer` (90d duration, 30d renew-before).
  - Overrides allowed via existing issuer refs when `create=false`; webhook issuer must be namespaced, workload issuer cluster-scoped by default.
- Cainjector requirement:
  - CABundle in `MutatingWebhookConfiguration` is injected solely by cert-manager cainjector.
  - Helm render/install must fail fast if cainjector is not detected or issuer references are missing/invalid.

## Test plan (paper only)

### Helm render/unit (helm-unittest/Go templating)
- Fail when `trustAnchorArn` or `region` are unset.
- Fail when cainjector is absent (CA bundle injection guard).
- Fail when issuer references are missing for `create=false` (webhook namespaced issuer, workload ClusterIssuer).
- Webhook certificate SANs include `iamra-webhook.iamra-system.svc`.
- Namespace opt-in:
  - Default: namespace without opt-in annotation → no webhook rule match / mutation (rendered config reflects opt-in key/value).
  - Opt-in disabled via values → webhook admits all namespaces.
- Workload issuer defaults: renders ClusterIssuer with duration/renew-before defaults; toggles respected.

### Webhook handler unit tests
- Inject when namespace is opted-in and required annotations present; add sidecar + IMDS env to all app containers; preserve existing fields.
- No-op when namespace not opted-in.
- No-op when required annotations missing or empty.
- Optional overrides applied: audience, token-duration, region override, session-name, log-level; defaults used otherwise.
- Validation failures:
  - Reject malformed `iamra.aws/token-duration` (non-int or out of bounds).
  - Reject malformed `iamra.aws/region` override.
- Idempotency: reprocessing an already-injected pod is stable (hash/marker unchanged, no duplicate sidecar/env).
- Values precedence: trust anchor and default region always from chart values; never read from annotations.

### Optional envtest/kubewebhook smoke
- Start webhook with self-signed TLS from chart values; ensure CABundle injection via cainjector mock or fixture.
- Basic mutate call with opted-in namespace/pod fixture returns injected pod; missing gate returns original pod.
