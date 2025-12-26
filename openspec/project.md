# Project Context: aws-iam-ra-for-kubernetes wrapper

## Purpose
Package and extend the upstream `aws-samples/aws-iam-ra-for-kubernetes` project with a Helm chart and mutating webhook that injects the IAM Roles Anywhere sidecar using cert-manager-issued certificates.

## Scope & Constraints
- Target clusters: k3s on Raspberry Pi 4b (arm64) and amd64; low-resource friendly.
- Images: publish to GHCR; prefer multi-arch (arm64/amd64).
- Certificates: use cert-manager `ClusterIssuer` (not namespaced) for webhook TLS and workload certs.
- Vendor strategy: keep upstream in `vendor/aws-iam-ra-for-kubernetes`, refresh via script/submodule.
- Injection: annotation-driven mutating webhook to add the IAMRA sidecar, env vars, and volumes.
- Reuse: copy upstream assets at build time rather than reimplementing logic.

## Expectations
- Add monitoring/observability notes for new runtime components (webhook, sidecar path).
- Avoid timestamps in docs.
- Keep change proposals concise with clear deliverables and validation steps.
