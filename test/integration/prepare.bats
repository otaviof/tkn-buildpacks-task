#!/usr/bin/env bats

source ./test/helper/helper.sh

export PARAMS_GROUP_ID="$(id -g)"
export PARAMS_USER_ID="$(id -u)"
export SERVICE_BINDING_ROOT="/bindings"
export WORKSPACES_SOURCE_PATH="/workspace/source"

PREPARE_SH="./scripts/prepare.sh"

# when there's no configuration, or the configuration is incomplete, the script must return error,
# this way we can assert it will run with all required configuration
@test "[prepare.sh] should fail when the environment is incomplete" {
	unset WORKSPACES_SOURCE_PATH
	unset SERVICE_BINDING_ROOT

	run ${PREPARE_SH}
	assert_failure
	assert_output --partial 'not set'
}

@test "[prepare.sh] should prepare the filesystem without optional workspaces" {
	[ -n "${BASE_DIR}" ]

	run mkdir -pv \
		"${BASE_DIR}/tekton/home" \
		"${BASE_DIR}/layers" \
		"${BASE_DIR}/${WORKSPACES_SOURCE_PATH}"

	run ${PREPARE_SH}
	assert_success
}

@test "[prepare.sh] should prepare the filesystem with CACHE_BOUND=false" {
	[ -n "${BASE_DIR}" ]

	export WORKSPACES_CACHE_BOUND="false"
	export WORKSPACES_CACHE_PATH="/workspace/cache"

	run mkdir -pv \
		"${BASE_DIR}/tekton/home" \
		"${BASE_DIR}/layers" \
		"${BASE_DIR}/${WORKSPACES_SOURCE_PATH}" \
		"${BASE_DIR}/${WORKSPACES_CACHE_PATH}"

	run ${PREPARE_SH}
	assert_success
}

# runs the complete script workflow against a temporary location with mocked directories, asserting
# all script commands will be executed successfully, and also, assert the expected configuration is
# generated
@test "[prepare.sh] should create/change the expected directories and files" {
	[ -n "${BASE_DIR}" ]

	export WORKSPACES_CACHE_BOUND="true"
	export WORKSPACES_CACHE_PATH="/workspace/cache"
	export WORKSPACES_BINDINGS_PATH="/workspace/bindings"

	# preparing the test enviroment, creating the directories the script will be looking for
	run mkdir -pv \
		"${BASE_DIR}/tekton/home" \
		"${BASE_DIR}/layers" \
		"${BASE_DIR}/${WORKSPACES_SOURCE_PATH}" \
		"${BASE_DIR}/${WORKSPACES_CACHE_PATH}" \
		"${BASE_DIR}/${WORKSPACES_BINDINGS_PATH}"
	assert_success

	touch "${BASE_DIR}/${WORKSPACES_BINDINGS_PATH}/cert.pem"

	# running the prepare script informing a enviroment variables (env-vars) parameter, the script
	# should run successfuly which means every command executed returns exit-code zero
	run ${PREPARE_SH} --env-vars "key=value" "k=v"
	assert_success

	# making sure the --env-vars argument is working as intended, as in creating a new file with the
	# key value pair, buildpacks CNB will pick up those and set in the builder's environment
	PLATFORM_ENV_FILE_1="${BASE_DIR}/platform/env/key"
	PLATFORM_ENV_FILE_2="${BASE_DIR}/platform/env/k"

	assert_file_exists ${PLATFORM_ENV_FILE_1}
	assert_file_contains ${PLATFORM_ENV_FILE_1} '^value$'

	assert_file_exists ${PLATFORM_ENV_FILE_2}
	assert_file_contains ${PLATFORM_ENV_FILE_2} '^v$'

	# asserting the extra binding files are copied into the expected location
	assert_file_exists "${BASE_DIR}/bindings/cert.pem"
}
