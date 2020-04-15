{{/* ######### Redis related templates for Rails consumption */}}

{{- define "gitlab.rails.redis.yaml" -}}
{{- $name := default "resque" .redisConfigFile -}}
{{ $name }}.yml.erb: |
  production:
    url: {{ template "gitlab.redis.url" . }}
    {{- if .Values.global.redis.sentinels }}
    {{-   include "gitlab.redis.sentinels" . | nindent 4 }}
    {{- end }}
    id:
    {{- if eq (default "" .redisConfig) "actioncable" }}
    adapter: redis
    {{-   if .Values.global.redis.actioncable.channelPrefix }}
    channel_prefix: {{ .Values.global.redis.actioncable.channelPrefix }}
    {{-   end }}
    {{- end }}
{{- end -}}

{{- define "gitlab.rails.redis.resque" -}}
{{- $_ := set . "redisConfig" nil }}
{{- $_ := set . "redisConfigFile" nil }}
{{- include "gitlab.rails.redis.yaml" . -}}
{{- end -}}

{{- define "gitlab.rails.redis.cache" -}}
{{- if .Values.global.redis.cache -}}
{{- $_ := set . "redisConfig" "cache" }}
{{- $_ := set . "redisConfigFile" "redis.cache" }}
{{- include "gitlab.rails.redis.yaml" . -}}
{{- $_ := set . "redisConfig" nil }}
{{- end -}}
{{- end -}}

{{- define "gitlab.rails.redis.sharedState" -}}
{{- if .Values.global.redis.sharedState -}}
{{- $_ := set . "redisConfig" "sharedState" }}
{{- $_ := set . "redisConfigFile" "redis.shared_state" }}
{{- include "gitlab.rails.redis.yaml" . -}}
{{- $_ := set . "redisConfig" nil }}
{{- end -}}
{{- end -}}

{{- define "gitlab.rails.redis.queues" -}}
{{- if .Values.global.redis.queues -}}
{{- $_ := set . "redisConfig" "queues" }}
{{- $_ := set . "redisConfigFile" "redis.queues" }}
{{- include "gitlab.rails.redis.yaml" . -}}
{{- $_ := set . "redisConfig" nil }}
{{- end -}}
{{- end -}}

{{/*
cable.yml configuration
If no `global.redis.actioncable`, use `global.redis`
*/}}
{{- define "gitlab.rails.redis.cable" -}}
{{- if .Values.global.redis.actioncable -}}
{{- $_ := set . "redisConfig" "actioncable" }}
{{- end -}}
{{- $_ := set . "redisConfigFile" "cable" }}
{{- include "gitlab.rails.redis.yaml" . -}}
{{- $_ := set . "redisConfig" nil }}
{{- end -}}

{{- define "gitlab.redis.secrets" -}}
{{- range $redis := list "cache" "sharedState" "queues" "actioncable" -}}
{{-   if index $.Values.global.redis $redis -}}
{{-     if index $.Values.global.redis $redis "password" -}}
{{-       if index $.Values.global.redis $redis "password" "enabled" -}}
{{-         $_ := set $ "redisConfig" $redis }}
{{          include "gitlab.redis.secret" $ }}
{{-       end }}
{{-     end -}}
{{-   end -}}
{{- end -}}
{{- $_ := set . "redisConfig" nil }}
{{- if .Values.global.redis.password.enabled }}
{{    include "gitlab.redis.secret" . }}
{{- end }}
{{- end -}}

{{- define "gitlab.redis.secret" -}}
- secret:
    name: {{ template "gitlab.redis.password.secret" . }}
    items:
      - key: {{ template "gitlab.redis.password.key" . }}
        path: redis/{{ printf "%s-password" (default "redis" .redisConfig) }}
{{- end -}}
