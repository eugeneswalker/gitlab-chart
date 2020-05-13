{{/*
- If `local` is present (true or false; not nil), use that.
- Otherwise, if `global` is present, use that.
- Otherwise, use `default`.

For all cases, return `"true"` for true values, and `""` for false
values. This means that we can keep the literal string 'true' when true,
but have false values act as falsey (because `default` cares about empty
values).

The `default` function won't handle this case correctly as in Sprig,
false is empty.
*/}}
{{- define "gitlab.boolean.local" -}}
{{- if kindIs "bool" .local -}}
{{-   default "" .local -}}
{{- else if kindIs "bool" .global -}}
{{-   default "" .global -}}
{{- else -}}
{{-   default "" .default -}}
{{- end -}}
{{- end -}}
