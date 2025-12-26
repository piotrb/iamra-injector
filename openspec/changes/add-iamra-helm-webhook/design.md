# Design: IAMRA Sidecar Helm/Webhook

## Goals
- Provide a Helm chart that installs a mutating webhook to inject the IAM Roles Anywhere sidecar, scoped by annotations.
- Keep trust anchor ARN and AWS region as required chart values; minimize per-pod required annotations to role/profile ARNs.
- Default to namespaced webhook issuer (for serving TLS) and cluster-scoped workload issuer; fail fast without cainjector.

## Components
- Namespace: default `iamra-system`; `MutatingWebhookConfiguration` is cluster-scoped; Deployment/Service/Issuer/Certificate live in `iamra-system`. Chart relies on Helm/Argo `createNamespace` if needed.
- Webhook: Service DNS `iamra-webhook.iamra-system.svc`; Deployment built with kubewebhook v2 (mutating handler), default framework logging, checksum-based rollout on CA/config changes.
- Issuers/TLS:
  - Webhook: self-signed namespaced `Issuer` (`iamra-webhook-selfsigned`) issuing a serving `Certificate` for the Service; CA secret in `iamra-system`; CABundle injected via cainjector.
  - Workload: self-signed `ClusterIssuer` (`iamra-workload-selfsigned`), duration 90d, renew-before 30d.
  - Values reserved to allow future toggles: webhook ClusterIssuer option; workload namespaced Issuer option (`type/name/namespace`).

## Injection contract
- Required chart values: `trustAnchorArn`, `region`.
- Namespace opt-in: injection only occurs when the namespace has an opt-in marker (configurable key/value, default `iamra.aws/enable: "true"`). Without it, webhook is a no-op.
- Required pod annotations to inject: `iamra.aws/role-arn`, `iamra.aws/signing-profile-arn`.
- Optional annotations: `iamra.aws/session-name` (default pod name), `iamra.aws/audience` (default `sts.amazonaws.com`), `iamra.aws/token-duration` (default 900s), `iamra.aws/log-level` (default `info`), `iamra.aws/region` (override only).
- No explicit inject flag on pods; presence of required annotations plus namespace opt-in triggers mutation. Trust anchor/region never read from annotations.

## Mutation behavior
- Inject sidecar exposing IMDS-compatible endpoint; cert/key/token remain in sidecar (no shared volumes to app).
- Mutate main containers with IMDS env wiring only:
  - `AWS_EC2_METADATA_SERVICE_ENDPOINT=http://169.254.169.254`
  - `AWS_EC2_METADATA_SERVICE_ENDPOINT_MODE=IPv4`
  - Region not injected unless provided explicitly.
- Add injection marker/hash annotations for idempotency and rollouts on config/CA changes.
- Namespace gate: injection only if namespace carries the opt-in marker (system namespaces can be opted in by adding it).

## Failure handling
- Helm templating hard-fails when:
  - cert-manager cainjector is absent,
  - required issuer references are missing/invalid,
  - required values (`trustAnchorArn`, `region`) are unset.
- Region comes from chart value (required). Annotation override must parse or injection fails for that pod.

## Observability/ops
- Optional Prometheus `ServiceMonitor`/`PodMonitor` behind `prometheus.enabled`; no CRD guard (install fails if CRDs absent). Metrics on webhook only (e.g., `:9090/metrics`).
- Webhook uses kubewebhook default logging; sidecar keeps upstream defaults.
- Checksum annotations trigger Deployment restarts when TLS secret/config change (TLS secret + key config/env inputs).

## Example/validation
- Separate example chart (no dependency on main chart) installs a Job with required annotations and runs `aws sts get-caller-identity` to validate injection and credential flow.

## Values sketch (illustrative)
- `namespace`: default `iamra-system`.
- `namespaceOptIn`: `{ enabled: true, annotationKey: iamra.aws/enable, annotationValue: "true" }`
- `trustAnchorArn` (required), `region` (required).
- `webhook`:
  - `issuer`: `{ create: true, name: iamra-webhook-selfsigned, type: Issuer }`
  - `certificate`: `{ name: iamra-webhook-tls, dnsNames: [iamra-webhook.iamra-system.svc] }`
  - `image`: `{ repository, tag, pullPolicy }`
  - `replicaCount`, `resources`, `nodeSelector`, `tolerations`, `affinity`, `podAnnotations`.
  - `service`: `{ port: 443, targetPort: 8443 }`
- `workloadIssuer`: `{ create: true, name: iamra-workload-selfsigned, type: ClusterIssuer, duration: 2160h, renewBefore: 720h }`
- `sidecar`:
  - `image`: `{ repository, tag, pullPolicy }`
  - `port`: IMDS listen port (e.g., 8180), `logLevel` default `info`, `tokenDuration` default 900s, `audience` default `sts.amazonaws.com`.
  - `resources`, `securityContext`.
- `prometheus`: `{ enabled: false, serviceMonitor: {...}, podMonitor: {...} }`
- `helloWorld`: `{ enabled: false, image/tag, annotations }`

## Open items / future-ready
- Allow webhook ClusterIssuer toggle if cross-namespace CA sharing is required.
- Allow workload namespaced Issuer mode if operators prefer per-namespace issuance.
- Finalize GHCR repo/name/tag policy and multi-arch build pipeline.
