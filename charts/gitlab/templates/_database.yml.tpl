{{/* ######## Rails database related templates */}}
{{/*
Returns the contents of the `database.yml` blob for Rails pods
*/}}
{{- define "gitlab.database.yml" -}}
production:
  adapter: postgresql
  encoding: unicode
  database: {{ template "gitlab.psql.database" . }}
  username: {{ template "gitlab.psql.username" . }}
  password: "<%= File.read("/etc/gitlab/postgres/psql-password").strip.dump[1..-2] %>"
  host: {{ include "gitlab.psql.host" . | quote }}
  port: {{ template "gitlab.psql.port" . }}
  pool: {{ template "gitlab.psql.pool" . }}
  prepared_statements: {{ template "gitlab.psql.preparedStatements" . }}
  # load_balancing:
  #   hosts:
  #     - host1.example.com
  #     - host2.example.com
  {{- include "gitlab.psql.ssl.config" . | nindent 2 }}
{{- end -}}
