# Change: add-iamra-helm-webhook

## Why
- Upstream `aws-iam-ra-for-kubernetes` is sample-only; no Helm chart or mutating webhook for transparent sidecar injection.
- Need ClusterIssuer-based TLS and annotation-driven injection to work on k3s (arm64 Raspberry Pi) and amd64.
- Want to reuse upstream assets (minimal drift) while automating builds (GHCR) and chart refreshes.

## What Changes

### Packaging & Vendor
- Add upstream as pinned submodule under `vendor/aws-iam-ra-for-kubernetes`.
- Provide `scripts/update-vendor.sh` to refresh/pin the submodule for builds.

### Helm Chart
- New chart `charts/iamra-injector`:
  - Annotation-driven injection of IAMRA sidecar (env/volumes) modeled on `cert-manager-self-managed-ca`; opt-in solely via annotations with IAM-RA fields present.
  - Uses cert-manager self-signed `ClusterIssuer` for webhook TLS (default create) and a distinct self-signed `ClusterIssuer` for workload/IAM-RA certs (default create); can point to existing issuers when `create=false`.
  - Templates trust/profile/role ARNs, helper image, ports, volumes, and scheduling (arm64/amd64).

### Mutating Webhook
- Deployment + Service + `MutatingWebhookConfiguration` that injects the sidecar when annotations match.
- Webhook cert issued by cert-manager self-signed ClusterIssuer; CA bundle injected only via cert-manager cainjector. Install must fail fast if cainjector is absent or issuer references are missing.

### Sync & Build Tooling
- `scripts/refresh-chart-from-vendor.sh` to copy upstream manifests/templates (pod spec, env tpl, openssl.cnf, etc.) into chart assets.
- GitHub Actions:
  - Build/publish webhook injector image to GHCR (arm64/amd64).
  - Publish chart via gh-pages in this repo (chart artifacts/pages branch).
  - Optional: build helper image from upstream Dockerfile if no public image is available.

### Documentation
- Chart README with values/annotations, k3s arm64 example, and observability notes.
- Instructions for self-signed CA setup mirroring `kpi-argo/kluster-system/roles-anywhere`.
- Guidance on pod annotations required to assume roles.
- Conceptual + Terraform example for AWS trust anchor/profile/role setup (anchor creation sample).
- Hello-world example app/chart (Job) that runs `aws sts get-caller-identity` to demonstrate injection and credential flow.

### Design Reference
- See `design.md` in this change directory for technical details and values contracts (no separate JSON schema doc required).

## Impact

### Affected Capabilities
- `iamra-injector` (new) – annotation-based IAM Roles Anywhere sidecar injection with cert-manager integration.

### Affected Infrastructure
- cert-manager ClusterIssuer usage for webhook TLS.
- New webhook Deployment/Service and GHCR images (multi-arch).
- Upstream vendor content referenced via submodule.

### Risk Assessment
- Moderate (webhook injection path); mitigated by opt-in annotations, cert-manager-issued certs, and vendor reuse.

### Breaking Changes
- None; additive and opt-in.

## Deliverables
1) OpenSpec change directory with proposal/tasks/spec deltas.
2) Pinned vendor submodule + update script.
3) Helm chart `charts/iamra-injector` with ClusterIssuer support and annotation-based injection.
4) Mutating webhook manifests with cert-manager-issued self-signed TLS (cainjector required for CA bundle).
5) Sync/refresh script for chart assets from upstream.
6) GitHub Actions for GHCR multi-arch builds and chart publish (plus helper fallback if needed).
7) Chart docs with k3s arm64 example and observability notes.

## Planned Tasks (gist, not yet executing)
- Scaffold spec delta/design (if needed) under `openspec/changes/add-iamra-helm-webhook/`.
- Add vendor submodule and `scripts/update-vendor.sh`.
- Scaffold `charts/iamra-injector` with values for ARNs/images/ports/volumes and arm64/amd64 scheduling.
- Add mutating webhook (Deployment/Service/MutatingWebhookConfiguration) using cert-manager self-signed ClusterIssuer TLS and CA bundle injection via cainjector; expose tunables via values; fail fast when cainjector or issuers are unavailable.
- Add `scripts/refresh-chart-from-vendor.sh` to copy upstream assets.
- Add GH Actions for multi-arch GHCR image build and gh-pages chart publish; optional helper-image fallback.
- Document values/annotations, k3s arm64 example, observability/health and rollback notes.
- Document self-signed CA setup (aligned with `kpi-argo/kluster-system/roles-anywhere`), pod annotation usage, and Terraform sample for AWS trust anchor/profile/role; call out dual self-signed ClusterIssuers (webhook/workload) and cainjector requirement.
- Add hello-world Job/chart that calls `aws sts get-caller-identity` to illustrate annotation + sidecar behavior.
- Validate templates and multi-arch build matrix.

## Success Criteria
- Proposal and tasks recorded in OpenSpec; specs capture new capability requirements.
- Vendor submodule refresh is reproducible via script.
- Chart renders sidecar injection and ClusterIssuer wiring from values and annotations.
- Webhook TLS cert issued via cert-manager and CA bundle patched; injector image builds for arm64/amd64 to GHCR.
- Chart docs describe values, annotations, and k3s arm64 usage with observability expectations.
