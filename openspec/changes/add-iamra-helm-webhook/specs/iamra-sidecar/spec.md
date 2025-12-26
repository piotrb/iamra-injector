## ADDED Requirements

### Requirement: Helm packaging for IAMRA sidecar
The system SHALL provide a Helm chart `iamra-sidecar` that packages the IAM Roles Anywhere sidecar pattern and supports annotation-driven injection.

#### Scenario: Rendered chart
- WHEN the chart is rendered with default values
- THEN it produces resources for webhook, service, and templates that can inject the sidecar when annotations match.

### Requirement: Annotation-scoped opt-in
The system SHALL scope sidecar injection strictly to pods carrying the required IAM-RA annotations (opt-in).

#### Scenario: Annotation gating
- WHEN a pod lacks the IAM-RA annotation set
- THEN the mutating webhook does not inject the sidecar.

### Requirement: Issuer-based TLS
The system SHALL use cert-manager self-signed issuers: a namespaced `Issuer` for webhook TLS (default in `iamra-system`) and a `ClusterIssuer` for workload/IAM-RA certs, created by default and overrideable via existing issuer references.

#### Scenario: Webhook certificate
- WHEN the chart is applied with default values
- THEN a self-signed namespaced Issuer is created for the webhook, a serving certificate is issued for the webhook service, and the CA bundle is populated in the webhook configuration via cainjector.
- WHEN `create=false` for either issuer
- THEN an existing issuer reference MUST be provided (namespaced for the webhook, cluster-scoped for workload by default).

### Requirement: Cainjector enforcement
The system SHALL require cert-manager cainjector to inject the webhook CA bundle and fail installation when cainjector is absent or issuer references are invalid.

#### Scenario: Missing cainjector or issuer
- WHEN helm install/upgrade runs and cainjector is not detected or required issuers are unset
- THEN the release fails with a clear error message and the webhook configuration is not installed.

### Requirement: Multi-arch support
The system SHALL support building and publishing the webhook injector image to GHCR for arm64 and amd64.

#### Scenario: Multi-arch images
- WHEN CI/CD runs the image build workflow
- THEN images for arm64 and amd64 are pushed to GHCR with a shared manifest.

### Requirement: Configurable runtime parameters
The system SHALL expose values for trust anchor ARN, AWS region, signing profile/role defaults, helper image, ports, and scheduling knobs (nodeSelector/tolerations/affinity).

#### Scenario: Value overrides
- WHEN operators set overrides in `values.yaml`
- THEN rendered manifests reflect the provided ARNs, images, ports, volumes, and scheduling constraints.

### Requirement: Example hello-world Job
The system SHALL include a sample hello-world chart that runs a Job executing `aws sts get-caller-identity` to demonstrate annotation-driven sidecar injection and credential retrieval.

#### Scenario: Hello-world execution
- WHEN the hello-world chart is installed with required annotations and values
- THEN the Job runs `aws sts get-caller-identity` successfully using injected credentials and logs the caller identity.

## Design

### Chart scope and namespace
- Default namespace: `iamra-system`; chart does not force creation unless annotations are required, allowing Helm/Argo `createNamespace` to handle it.
- Webhook resources: Deployment, Service, Issuer, and Certificate live in `iamra-system`; `MutatingWebhookConfiguration` is cluster-scoped.

### TLS and issuers
- Webhook TLS: default self-signed namespaced `Issuer` (`iamra-webhook-selfsigned`) issues a serving `Certificate` for `iamra-webhook.iamra-system.svc`. CA secret lives in `iamra-system`; CA bundle injected via cainjector. Values leave room for a future ClusterIssuer toggle.
- Workload certs: default self-signed `ClusterIssuer` (`iamra-workload-selfsigned`), duration 90d, renew-before 30d. Values structured for future namespaced Issuer support (`type/name/namespace` reserved).
- Installation fails fast if cainjector or required issuer references are absent.

### Injection contract
- Required chart values: `trustAnchorArn`, `region`.
- Required pod annotations to trigger injection: `iamra.aws/role-arn`, `iamra.aws/signing-profile-arn`.
- Optional annotations: `iamra.aws/session-name` (default pod name), `iamra.aws/audience` (default `sts.amazonaws.com`), `iamra.aws/token-duration` (default 900s), `iamra.aws/log-level` (default `info`), `iamra.aws/region` (override only).
- No explicit inject flag; presence of required annotations triggers mutation.

### Mutation behavior
- Inject sidecar container exposing an IMDS-compatible endpoint; cert/key/token stay within the sidecar (no app volume sharing).
- Mutate main containers with IMDS wiring env only: `AWS_EC2_METADATA_SERVICE_ENDPOINT=http://169.254.169.254`, `AWS_EC2_METADATA_SERVICE_ENDPOINT_MODE=IPv4`. Region is not injected unless provided.
- Add injection marker/hash annotations to avoid double injection and to roll on config/CA changes.
- No namespace denylist; system namespaces may be injected.

### Failure handling
- Helm templating hard-fails when cainjector is missing, issuer references are invalid, or required values (trust anchor, region) are absent.
- Region comes from the chart value (required). If an override annotation is provided and malformed, fail injection for that pod.

### Observability and ops
- Prometheus: optional `ServiceMonitor`/`PodMonitor` behind `prometheus.enabled`; no CRD guard (install fails if CRDs absent).
- Logging: webhook uses JSON by default; sidecar follows upstream logging defaults.
- Rollouts: checksum annotations on TLS secret/config to trigger Deployment restart on CA/config changes.

### Hello-world example
- Separate example chart (no dependency on the main chart) that installs a Job with required annotations and runs `aws sts get-caller-identity` to validate injection and credential flow.

### Open items / future-ready
- Webhook issuer toggle to ClusterIssuer if cross-namespace CA sharing is desired.
- Workload issuer namespaced Issuer mode if operators prefer per-namespace issuance.
- Multi-arch build/publish location remains TBD (GHCR repo/tagging policy to be decided).
