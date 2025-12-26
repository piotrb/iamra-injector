# iamra sidecar webhook for kubernetes

Helm-driven mutating webhook that injects the IAM Roles Anywhere (IAMRA) sidecar into opted-in workloads. The goal is to wrap the upstream `aws-samples/aws-iam-ra-for-kubernetes` assets with a reproducible chart, cert-manager–backed TLS, and automation for multi-arch images.

## What this repo is for
- Annotation-driven injection of the IAMRA sidecar and IMDS env wiring, gated by a namespace opt-in annotation.
- Required chart values: `trustAnchorArn` and `region`; no annotation fallback.
- Webhook TLS via cert-manager issuer + serving certificate; CABundle injected by cainjector (hard requirement).
- Workload certs via a default self-signed `ClusterIssuer`, with toggles for external issuers.
- Webhook image built from `github.com/piotrb/iamra-injector`, published to `ghcr.io/piotrb/iamra-injector` (multi-arch).
- Example/hello-world job planned to demonstrate `aws sts get-caller-identity` with the injected sidecar.

## Status
Design and tasks are tracked in `openspec/changes/add-iamra-helm-webhook/` (proposal, design, tasks). Implementation is being staged phase-by-phase with tests before code.

## Repo layout (relevant parts)
- `openspec/` – project context and the OpenSpec change for this work.
- `vendor/aws-iam-ra-for-kubernetes/` – upstream sample assets kept as a submodule for reference/copying.
- (Planned) `charts/iamra-injector/` – Helm chart for the webhook, issuers, and example job.
- (Planned) `scripts/` – vendor/refresh and chart/publish helpers.

## Prerequisites (intended)
- Kubernetes cluster (k3s/amd64/arm64 tested targets).
- cert-manager **with cainjector** installed; installs should fail fast without it.
- AWS IAM Roles Anywhere trust anchor/profile/role set up and accessible.
- Pull access to `ghcr.io/piotrb/iamra-injector` (or override image values).

## Credits and upstream
- Upstream IAMRA sample: `aws-samples/aws-iam-ra-for-kubernetes`.
- Webhook codebase: `github.com/piotrb/iamra-injector` (multi-arch image at `ghcr.io/piotrb/iamra-injector`).
- Webhook framework: `slok/kubewebhook`.
- TLS and CA injection: `cert-manager` + `cainjector`.
- IAM Roles Anywhere service: AWS.

## Notes
- No remote pushes from this repo; phases require user sign-off per `openspec/changes/add-iamra-helm-webhook/tasks.md`.
- Documentation and tests should land with each phase; avoid deferring validation.
