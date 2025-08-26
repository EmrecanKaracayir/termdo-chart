{{/*
Expand the name of the chart.
*/}}
{{- define "termdo.name" -}}
  {{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "termdo.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "termdo.chart" -}}
  {{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}


{{/*
Common labels
Usage: include "termdo-chart.labels" .
*/}}
{{- define "termdo.labels" -}}
  helm.sh/chart: {{ include "termdo.chart" . }}
  {{ include "termdo.selectorLabels" . }}
  {{- if .Chart.AppVersion }}
    app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
  {{- end }}
  app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Minimal, stable labels safe for selector usage.
Usage: include "termdo-chart.selectorLabels" (dict "root" . "component" "auth-api")
*/}}
{{- define "termdo.selectorLabels" -}}
  app.kubernetes.io/instance: {{ .Release.Name | quote }}
  app.kubernetes.io/name: {{ include "termdo.name" .root | quote }}
  app.kubernetes.io/component: {{ .component | quote }}
{{- end -}}

{{/*
Build a release-aware name for a specific component.
Usage: include "termdo-chart.componentName" (dict "root" . "component" "auth-api")
*/}}
{{- define "termdo.componentName" -}}
{{- $base := include "termdo.fullname" -}}
{{- printf "%s-%s" $base .component | trunc 63 | trimSuffix "-" -}}
{{- end -}}
