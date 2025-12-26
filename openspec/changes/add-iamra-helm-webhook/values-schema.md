# Proposed values schema (illustrative)

```yaml
# Global / core
namespace: iamra-system             # Namespace for webhook resources (not force-created)
trustAnchorArn: ""                  # REQUIRED: IAM RA trust anchor ARN
region: ""                          # REQUIRED: AWS region for IAM RA (service is regional)
namespaceOptIn:                    # Namespace-level opt-in gate (required to allow injection)
  enabled: true
  annotationKey: iamra.aws/enable
  annotationValue: "true"

# Webhook deployment
webhook:
  image:
    repository: ghcr.io/org/iamra-webhook   # Built from this repo; distinct GHCR image from sidecar
    tag: ""                                 # e.g., chart appVersion or SHA
    pullPolicy: IfNotPresent
  replicaCount: 1
  service:
    port: 443
    targetPort: 8443
  metrics:
    enabled: true                   # Expose kubewebhook Prometheus metrics
    port: 9090
    path: /metrics
  resources: {}                      # Standard Kubernetes resources block
  nodeSelector: {}
  tolerations: []
  affinity: {}
  podAnnotations: {}
  securityContext: {}                # Pod-level security context overrides
  containerSecurityContext: {}       # Container-level security context overrides
  logging:
    format: json                     # Webhook logging format

  issuer:                            # Webhook TLS issuer (namespaced Issuer by default)
    create: true
    type: Issuer                     # Reserved for future ClusterIssuer toggle
    name: iamra-webhook-selfsigned
  certificate:
    name: iamra-webhook-tls
    dnsNames:
      - iamra-webhook.iamra-system.svc

# Workload cert issuer
workloadIssuer:
  create: true
  type: ClusterIssuer                # Reserved for future Issuer support
  name: iamra-workload-selfsigned
  duration: 2160h                    # 90d
  renewBefore: 720h                  # 30d

# Sidecar injection config
sidecar:
  image:
    repository: ghcr.io/org/iamra-sidecar    # Built from this repo; distinct GHCR image from webhook
    tag: ""                                  # e.g., chart appVersion or SHA
    pullPolicy: IfNotPresent
  port: 8180                         # IMDS-compatible endpoint port
  logLevel: info
  audience: sts.amazonaws.com        # STS token audience; rarely changed unless custom endpoint
  tokenDurationSeconds: 900
  resources: {}
  securityContext: {}

# Prometheus integration (optional; will fail if CRDs absent)
prometheus:
  enabled: false                     # Toggles metrics endpoint exposure and Service
  serviceMonitor:
    enabled: false                   # Creates ServiceMonitor (requires CRDs)
    interval: 30s
    scrapeTimeout: 10s
  podMonitor:
    enabled: false                   # Creates PodMonitor (requires CRDs)

# Hello-world example (separate chart, gated here for convenience)
helloWorld:
  enabled: false
  image:
    repository: public.ecr.aws/aws-cli
    tag: "2.17.0"
    pullPolicy: IfNotPresent
  annotations: {}                    # Adds required IAM RA annotations for the Job
```

Notes:
- Required annotations to trigger injection: `iamra.aws/role-arn` and `iamra.aws/signing-profile-arn` (others optional).
- Trust anchor ARN and region come from required chart values and are not read from annotations.
- CABundle is injected via cainjector; install fails if cainjector or issuer references are missing.
- Audience: used for STS token requests; default `sts.amazonaws.com` and should only change for nonstandard STS endpoints.
- Prom flags: `prometheus.enabled` exposes metrics + Service; `prometheus.serviceMonitor.enabled` and `prometheus.podMonitor.enabled` create the respective CRDs (will fail if CRDs absent).
