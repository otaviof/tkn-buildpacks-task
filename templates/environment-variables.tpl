{{/*

  This template is meant to translate the Tekton placeholder utilized by the shell scripts, thus the
  scripts can rely on a pre-defined and repetable way of consuming Tekton attributes.

    Example:
      The placeholder `workspaces.a.b` becomes `WORKSPACES_A_B`

*/}}
{{- define "environment-variables" -}}
    {{- range list
          "workspaces.cache.bound"
          "workspaces.cache.path"
          "workspaces.source.path"
          "workspaces.bindings.path"
          "params.USER_ID"
          "params.GROUP_ID" }}
- name: {{ . | upper | replace "." "_" | quote }}
  value: "$({{ . }})"
    {{- end }}
{{- end }}