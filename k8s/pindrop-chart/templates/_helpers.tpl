{{/*
HELM TEMPLATE HELPERS

This file contains reusable template functions (like macros or functions).

Why use helpers?
- DRY (Don't Repeat Yourself): Define once, use everywhere
- Consistency: Same labels/names across all resources
- Maintainability: Change in one place, applies everywhere

Key concepts:
- .Values = Access values from values.yaml
- .Chart = Access values from Chart.yaml
- .Release = Access Helm release information
- The dot (.) is the context containing all template data
*/}}

{{/*
------------------------------------------------------------------------------
Chart Name
------------------------------------------------------------------------------
Returns the chart name, truncated to 63 characters (K8s name limit).
Handles cases where nameOverride is provided in values.yaml.
*/}}
{{- define "pindrop.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
------------------------------------------------------------------------------
Full Name
------------------------------------------------------------------------------
Creates a fully qualified app name combining release name and chart name.
Truncated to 63 characters to meet Kubernetes naming requirements.

Example:
- Release name: my-release
- Chart name: pindrop
- Result: my-release-pindrop

If release name contains chart name, it won't duplicate:
- Release name: pindrop
- Chart name: pindrop  
- Result: pindrop (not pindrop-pindrop)
*/}}
{{- define "pindrop.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
------------------------------------------------------------------------------
Chart Label
------------------------------------------------------------------------------
Creates a label identifying the chart name and version.
Used for tracking which chart version deployed a resource.
*/}}
{{- define "pindrop.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
------------------------------------------------------------------------------
Common Labels
------------------------------------------------------------------------------
Standard labels applied to ALL resources in this chart.
These labels help with:
- Organizing resources (kubectl get all -l app.kubernetes.io/name=pindrop)
- Helm tracking (which release deployed this)
- Version tracking (which version is deployed)
*/}}
{{- define "pindrop.labels" -}}
helm.sh/chart: {{ include "pindrop.chart" . }}
app.kubernetes.io/name: {{ include "pindrop.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
------------------------------------------------------------------------------
Selector Labels
------------------------------------------------------------------------------
Labels used in selector fields (Deployment.spec.selector.matchLabels).
These MUST be immutable after creation - don't include version here!
*/}}
{{- define "pindrop.selectorLabels" -}}
app.kubernetes.io/name: {{ include "pindrop.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
------------------------------------------------------------------------------
Backend Labels
------------------------------------------------------------------------------
Labels specific to backend resources.
*/}}
{{- define "pindrop.backendLabels" -}}
{{ include "pindrop.labels" . }}
app.kubernetes.io/component: backend
{{- end }}

{{/*
------------------------------------------------------------------------------
Backend Selector Labels
------------------------------------------------------------------------------
*/}}
{{- define "pindrop.backendSelectorLabels" -}}
{{ include "pindrop.selectorLabels" . }}
app.kubernetes.io/component: backend
{{- end }}

{{/*
------------------------------------------------------------------------------
Frontend Labels
------------------------------------------------------------------------------
Labels specific to frontend resources.
*/}}
{{- define "pindrop.frontendLabels" -}}
{{ include "pindrop.labels" . }}
app.kubernetes.io/component: frontend
{{- end }}

{{/*
------------------------------------------------------------------------------
Frontend Selector Labels
------------------------------------------------------------------------------
*/}}
{{- define "pindrop.frontendSelectorLabels" -}}
{{ include "pindrop.selectorLabels" . }}
app.kubernetes.io/component: frontend
{{- end }}

{{/*
------------------------------------------------------------------------------
Namespace
------------------------------------------------------------------------------
Returns the namespace to deploy to.
Defaults to .Release.Namespace (where helm install is run).
*/}}
{{- define "pindrop.namespace" -}}
{{- default .Release.Namespace .Values.namespace }}
{{- end }}

{{/*
------------------------------------------------------------------------------
Backend Image
------------------------------------------------------------------------------
Constructs the full image reference for the backend.
*/}}
{{- define "pindrop.backendImage" -}}
{{- printf "%s:%s" .Values.backend.image.repository .Values.backend.image.tag }}
{{- end }}

{{/*
------------------------------------------------------------------------------
Frontend Image
------------------------------------------------------------------------------
Constructs the full image reference for the frontend.
*/}}
{{- define "pindrop.frontendImage" -}}
{{- printf "%s:%s" .Values.frontend.image.repository .Values.frontend.image.tag }}
{{- end }}
