{{/* ######### Redis related templates */}}

{{/*
Return the redis hostname
If the redis host is provided, it will use that, otherwise it will fallback
to the service name
*/}}
{{- define "gitlab.redis.host" -}}
{{- $_ := set . "redisGlobal" .Values.global.redis -}}
{{- if .redisConfig -}}
{{-   $_ := set . "redisGlobal" (index .Values.global.redis .redisConfig) -}}
{{- end -}}
{{- if .redisGlobal.host -}}
{{-   .redisGlobal.host -}}
{{- else -}}
{{-   $name := default "redis" .Values.redis.serviceName -}}
{{-   printf "%s-%s-master" .Release.Name $name -}}
{{- end -}}
{{- end -}}

{{/*
Return the redis port
If the redis port is provided, it will use that, otherwise it will fallback
to 6379 default
*/}}
{{- define "gitlab.redis.port" -}}
{{- $_ := set . "redisGlobal" .Values.global.redis -}}
{{- if .redisConfig -}}
{{-   $_ := set . "redisGlobal" (index .Values.global.redis .redisConfig) -}}
{{- end -}}
{{- default 6379 .redisGlobal.port -}}
{{- end -}}

{{/*
Return the redis scheme, or redis. Allowing people to use rediss clusters
*/}}
{{- define "gitlab.redis.scheme" -}}
{{- $_ := set . "redisGlobal" .Values.global.redis -}}
{{- if .redisConfig -}}
{{-   $_ := set . "redisGlobal" (index .Values.global.redis .redisConfig) -}}
{{- end -}}
{{- $valid := list "redis" "rediss" "tcp" -}}
{{- $name := default .redisGlobal.scheme "redis" -}}
{{- if has $name $valid -}}
{{    $name }}
{{- else -}}
{{    cat "Invalid redis scheme" $name | fail }}
{{- end -}}
{{- end -}}

{{/*
Return the redis url.
*/}}
{{- define "gitlab.redis.url" -}}
{{- $_ := set . "redisGlobal" .Values.global.redis -}}
{{- if .redisConfig -}}
{{-   $_ := set . "redisGlobal" (index .Values.global.redis .redisConfig) -}}
{{- end -}}
{{ template "gitlab.redis.scheme" . }}://{{- if .redisGlobal.password.enabled -}}:<%= URI.escape(File.read("/etc/gitlab/redis/{{ printf "%s-password" (default "redis" .redisConfig) }}").strip) %>@{{- end -}}{{ template "gitlab.redis.host" . }}:{{ template "gitlab.redis.port" . }}
{{- end -}}

{{/*
Build the structure describing sentinels
*/}}
{{- define "gitlab.redis.sentinels" -}}
{{- $_ := set . "redisGlobal" .Values.global.redis -}}
{{- if .redisConfig -}}
{{-   $_ := set . "redisGlobal" (index .Values.global.redis .redisConfig) -}}
{{- end -}}
sentinels:
{{- range $i, $entry := .redisGlobal.sentinels }}
  - host: {{ $entry.host }}
    port: {{ default 26379 $entry.port }}
{{- end }}
{{- end -}}

{{/*
Return Sentinel list in format for Workhorse
Note: Workhorse only uses the primary Redis (global.redis)
*/}}
{{- define "gitlab.redis.workhorse.sentinel-list" }}
{{- $sentinelList := list }}
{{- range $i, $entry := .Values.global.redis.sentinels }}
  {{- $sentinelList = append $sentinelList (quote (print "tcp://" (trim $entry.host) ":" ( default 26379 $entry.port | int ) ) ) }}
{{- end }}
{{- $sentinelList | join "," }}
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
