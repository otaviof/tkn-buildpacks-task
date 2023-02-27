#!/usr/bin/env bats

source ./test/helper/helper.sh

# installing the buildpacks and git-clone
@test "[e2e] installing git-clone and buildpacks tasks" {
	readonly GITHUB_HOSTNME="raw.githubusercontent.com"

	readonly GIT_CLONE_PATH="tektoncd/catalog/main/task/git-clone"
	readonly GIT_CLONE_VERSION="0.9"
	readonly GIT_CLONE_URL="https://${GITHUB_HOSTNME}/${GIT_CLONE_PATH}/${GIT_CLONE_VERSION}/git-clone.yaml"

	# installing the git-clone task, employed to clone the sample repository
	run kubectl apply -f ${GIT_CLONE_URL}
	assert_success

	# rendering the task and storing in a variable to assess the payload
	BUILDPACKS_TASK_FILE="${BASE_DIR}/task.yaml"
	BUILDPACKS_TASK=$(helm template .)
	[ -n "${BUILDPACKS_TASK}" ]

	# saving the task payload in a temporary file
	echo -ne "${BUILDPACKS_TASK}" >${BUILDPACKS_TASK_FILE}

	run kubectl apply -f ${BUILDPACKS_TASK_FILE}
	assert_success
}

# registering the Pipeline resource and a private-volume-claim
@test "[e2e] installing pipeline and requirements" {
	run kubectl apply \
		--filename=test/e2e/resources/01-pvc.yaml \
		--filename=test/e2e/resources/10-pipeline.yaml
	assert_success
}

# spinning up a PipeineRun using the internal Container-Registry to store the final image, when the
# process is completed the resource is inspected to assert wether sucessful
@test "[e2e] start pipeline and follow logging output" {
	readonly PARAM_GIT_REPO="${PARAM_GIT_REPO:-}"
	readonly PARAM_GIT_REVISION="${PARAM_GIT_REVISION:-}"
	readonly PARAM_IMAGE_TAG="${PARAM_IMAGE_TAG:-}"

	# asserting all required configuratio is informed
	[ -n "${PARAM_GIT_REPO}" ]
	[ -n "${PARAM_GIT_REVISION}" ]
	[ -n "${PARAM_IMAGE_TAG}" ]

	run tkn pipeline start tkn-buildpacks \
		--param="git-repo=${PARAM_GIT_REPO}" \
		--param="git-revision=${PARAM_GIT_REVISION}" \
		--param="image-tag=${PARAM_IMAGE_TAG}" \
		--workspace="name=source,claimName=workspace-source,subPath=source" \
		--workspace="name=cache,claimName=workspace-source,subPath=cache" \
		--workspace="name=bindings,emptyDir=" \
		--showlog >&3
	assert_success

	readonly TMPL_FILE="${BASE_DIR}/go-template.tpl"

	#
	# Asserting PipelineRun Status
	#

	cat >${TMPL_FILE} <<EOS
{{- range .status.conditions -}}
	{{- if and (eq .type "Succeeded") (eq .status "True") }}
		{{ .message }}
	{{- end }}
{{- end -}}
EOS

	# using template to select the requered information and asserting all tasks have been executed
	# without failed or skipped steps
	run tkn pipelinerun describe --output=go-template-file --template=${TMPL_FILE}
	assert_success
	assert_output --partial '(Failed: 0, Cancelled 0), Skipped: 0'

	#
	# Asserting Results
	#

	cat >${TMPL_FILE} <<EOS
{{- range .status.taskRuns -}}
  {{- range .status.taskResults -}}
    {{ printf "%s=%s\n" .name .value }}
  {{- end -}}
{{- end -}}
EOS

	# using a template to select the interesting task-results printing out the attributes as
	# key/value pairs split by new-line
	run tkn pipelinerun describe --output=go-template-file --template=${TMPL_FILE}
	assert_success
	assert_output --regexp $'^APP_IMAGE_DIGEST=\S+\nAPP_IMAGE_URL=\S+.*'
}
