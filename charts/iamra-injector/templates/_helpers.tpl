{{/*
Common template helpers for the iamra-injector chart.
*/}}

{{- define "iamra-injector.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "iamra-injector.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "iamra-injector.namespace" -}}
{{- if and .Release.Namespace (ne .Release.Namespace "") -}}
{{- .Release.Namespace -}}
{{- else -}}
{{- default "iamra-system" .Values.namespace -}}
{{- end -}}
{{- end -}}

{{- define "iamra-injector.webhookServiceName" -}}
iamra-webhook
{{- end -}}

{{- define "iamra-injector.requireNonEmpty" -}}
{{- if or (not .value) (eq .value "") -}}
{{- fail (printf "%s is required" .name) -}}
{{- end -}}
{{- end -}}

{{- define "iamra-injector.prechecks" -}}
{{- template "iamra-injector.requireNonEmpty" (dict "value" .Values.trustAnchorArn "name" "trustAnchorArn") -}}
{{- template "iamra-injector.requireNonEmpty" (dict "value" .Values.region "name" "region") -}}
{{- if not (.Capabilities.APIVersions.Has "cert-manager.io/v1") -}}
{{- fail "cert-manager (including cainjector) is required: cert-manager.io/v1 APIs not detected" -}}
{{- end -}}
{{- end -}}
