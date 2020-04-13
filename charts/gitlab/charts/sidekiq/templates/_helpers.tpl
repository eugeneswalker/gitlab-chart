{{/*
Whether Sidekiq Cluster should be enabled. If this is set to true
globally, and false for a pod, `default` won't handle that correctly as
in Sprig, false is empty.
*/}}
{{- define "sidekiq.cluster" -}}
{{- if kindIs "bool" .local -}}
{{-   .local -}}
{{- else if kindIs "bool" .global -}}
{{-   .global -}}
{{- else -}}
{{-   false -}}
{{- end -}}
{{- end -}}
