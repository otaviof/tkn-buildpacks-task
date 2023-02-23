#!/usr/bin/env bats

source ./test/helper/helper.sh

# asserting `helm template` output for the buildpacks task, it should sucessfuly render the template
# as a valid YAML payload, helm command fails otherwise
@test "[helm-template] the task htemplate should be rendered successfuly" {
	run helm template --debug .
	assert_success
	assert_output --partial 'apiVersion: tekton.dev/v1beta1'
}