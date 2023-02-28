#!/usr/bin/env bats

source ./test/helper/helper.sh

report_sh="./scripts/report.sh"

# asserting the script will error out when the environment is not complete
@test "[report.sh] should fail when the enviroment is incomplete" {
	run ${report_sh}
	assert_failure
	assert_output --partial 'is not'
}

# running the report script against a mocked `report.yaml` file to assert it can extract the
# important bits and write it back on the expected locations
@test "[report.sh] should be able to extract image digest and URL from buidpacks 'report.toml'" {
	export REPORT_TOML_PATH="./test/mock/report.toml"
	export RESULTS_APP_IMAGE_DIGEST_PATH="${BASE_DIR}/image-digest.txt"
	export RESULTS_APP_IMAGE_URL_PATH="${BASE_DIR}/image-url.txt"

	run ${report_sh}
	assert_success

	# making sure the result files tekton will read from are written and contain what's expected
	assert_file_contains ${RESULTS_APP_IMAGE_DIGEST_PATH} "sha256:digest"
	assert_file_contains ${RESULTS_APP_IMAGE_URL_PATH} "registry.local/namespace/project:latest"
}