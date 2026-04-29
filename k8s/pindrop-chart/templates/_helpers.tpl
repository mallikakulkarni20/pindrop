{{/* Shared helper templates */}}

{{/* Chart name */}}
{{- define "pindrop.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Full release name */}}
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

{{/* Chart label */}}
{{- define "pindrop.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Common labels */}}
{{- define "pindrop.labels" -}}
helm.sh/chart: {{ include "pindrop.chart" . }}
app.kubernetes.io/name: {{ include "pindrop.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/* Immutable selector labels */}}
{{- define "pindrop.selectorLabels" -}}
app.kubernetes.io/name: {{ include "pindrop.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/* Backend labels */}}
{{- define "pindrop.backendLabels" -}}
{{ include "pindrop.labels" . }}
app.kubernetes.io/component: backend
{{- end }}

{{/* Backend selector labels */}}
{{- define "pindrop.backendSelectorLabels" -}}
{{ include "pindrop.selectorLabels" . }}
app.kubernetes.io/component: backend
{{- end }}

{{/* Frontend labels */}}
{{- define "pindrop.frontendLabels" -}}
{{ include "pindrop.labels" . }}
app.kubernetes.io/component: frontend
{{- end }}

{{/* Frontend selector labels */}}
{{- define "pindrop.frontendSelectorLabels" -}}
{{ include "pindrop.selectorLabels" . }}
app.kubernetes.io/component: frontend
{{- end }}

{{/* Namespace helper */}}
{{- define "pindrop.namespace" -}}
{{- default .Release.Namespace .Values.namespace }}
{{- end }}

{{/* Backend image */}}
{{- define "pindrop.backendImage" -}}
{{- printf "%s:%s" .Values.backend.image.repository .Values.backend.image.tag }}
{{- end }}

{{/* Frontend image */}}
{{- define "pindrop.frontendImage" -}}
{{- printf "%s:%s" .Values.frontend.image.repository .Values.frontend.image.tag }}
{{- end }}
