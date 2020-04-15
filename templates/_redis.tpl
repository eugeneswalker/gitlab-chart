{{/* ######### Redis related templates */}}

{{/*
Return the redis password secret name

This define is not currently used, but left in place for when the
a dynamic secret name can be specified to the Redis chart.
*/}}
{{- define "gitlab.redis.password.secret" -}}
{{- $_ := set . "redisGlobal" .Values.global.redis -}}
{{- if .redisConfig -}}
{{-   $_ := set . "redisGlobal" (index .Values.global.redis .redisConfig) -}}
{{- end -}}
{{- coalesce .redisGlobal.password.secret .Values.global.redis.password.secret (printf "%s-redis-secret" .Release.Name) | quote -}}
{{- end -}}

{{/*
Return the redis password secret key
*/}}
{{- define "gitlab.redis.password.key" -}}
{{- $_ := set . "redisGlobal" .Values.global.redis -}}
{{- if .redisConfig -}}
{{-   $_ := set . "redisGlobal" (index .Values.global.redis .redisConfig) -}}
{{- end -}}
{{- coalesce .redisGlobal.password.key .Values.global.redis.password.key "secret" | quote -}}
{{- end -}}
