{{/* ######### Redis related templates */}}
{{ $_ := set $ "redisConfig" "" }}
{{ $_ := set $ "redisGlobal" (dict "redisConfig" "bogus") }}
{{/*
Build a dict of redis configuration

- inherit from global.redis, all but sentinels
- use values within children, if they exist, even if "empty"
*/}}
{{- define "gitlab.redis.configMerge" -}}
{{- $_ := set $ "redisConfig" (default "" $.redisConfig) -}}
{{/*  # prevent repeat operations -- default mess is to handle `.redisGlobal` not existing yet */}}
{{-   if or (not $.redisGlobal) (ne (default "" $.redisConfig) (default "" (index (default (dict) $.redisGlobal) "redisConfig") )) -}}
{{/*    # reset, preventing pollution. stashing the .redisConfig used to make this */}}
{{-     $_ := set . "redisGlobal" (dict "redisConfig" $.redisConfig) -}}
{{-     range $want := list "host" "port" "password" "scheme" -}}
{{-       $_ := set $.redisGlobal $want (pluck $want (index $.Values.global.redis $.redisConfig) $.Values.global.redis | first) -}}
{{-     end -}}
{{-   else -}}
{{/*     printf "gitlab.redis.configMerge: %s - %s" $.redisConfig (toJson $.redisGlobal) | fail */}}
{{-   end -}}
{{- end -}}

{{/*
Return the redis password secret name

This define is not currently used, but left in place for when the
a dynamic secret name can be specified to the Redis chart.
*/}}
{{- define "gitlab.redis.password.secret" -}}
{{- include "gitlab.redis.configMerge" . -}}
{{- coalesce .redisGlobal.password.secret .Values.global.redis.password.secret (printf "%s-redis-secret" .Release.Name) | quote -}}
{{- end -}}

{{/*
Return the redis password secret key
*/}}
{{- define "gitlab.redis.password.key" -}}
{{- include "gitlab.redis.configMerge" . -}}
{{- coalesce .redisGlobal.password.key .Values.global.redis.password.key "secret" | quote -}}
{{- end -}}
