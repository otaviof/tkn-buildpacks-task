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
	run tkn pipeline start tkn-buildpacks \
		--param="git-repo=https://github.com/otaviof/nodejs-ex.git" \
		--param="git-revision=main" \
		--param="image-tag=registry.registry.svc.cluster.local:32222/otaviof/nodejs-ex:latest" \
		--workspace="name=source,claimName=workspace-source,subPath=source" \
		--workspace="name=cache,claimName=workspace-source,subPath=cache" \
		--showlog
	assert_success

	readonly TMPL_FILE="${BASE_DIR}/go-template.tpl"

	# go-template to select the expected condition showing the PipelineRun final status
	cat >${TMPL_FILE} <<EOS
{{ range .status.conditions }}
	{{ if and (eq .type "Succeeded") (eq .status "True") }}
		{{ .message }}
	{{ end }}
{{ end }}
EOS

	# using template to select the requered information and asserting all tasks have been executed
	run tkn pipelinerun describe --output=go-template-file --template=${TMPL_FILE}
	assert_success
	assert_output --partial '(Failed: 0, Cancelled 0), Skipped: 0'
}
