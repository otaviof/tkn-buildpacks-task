BATS_CORE = ./test/.bats/bats-core/bin/bats
BATS_FLAGS ?= --print-output-on-failure --show-output-of-passing-tests --verbose-run

INTEGRATION_DIR ?= ./test/integration
E2E_DIR ?= ./test/e2e

# usnig the current directory name as the project name
PROJECT_NAME ?= $(shell basename $(CURDIR))

# parameters for the end-to-end tests pipeline-run, in order to run the tests agasint a different
# cluster you might need to tweek the following settings
PARAM_GIT_REPO ?= https://github.com/otaviof/nodejs-ex.git
PARAM_GIT_REVISION ?= main
PARAM_IMAGE_TAG ?= registry.registry.svc.cluster.local:32222/otaviof/nodejs-ex:latest

# generic arguments employed in most of the targets
ARGS ?=

# making sure the variables declared in the Makefile are exported to the excutables/scripts invoked
# on all targets
.EXPORT_ALL_VARIABLES:

# run the integration tests, does not require a kubernetes instance
test-integration:
	$(BATS_CORE) $(BATS_FLAGS) $(ARGS) $(INTEGRATION_DIR)/*.bats

# run end-to-end tests against the current kuberentes context, it will required a cluster with tekton
# pipelines and other requirements installed
test-e2e:
	$(BATS_CORE) $(BATS_FLAGS) $(ARGS) $(E2E_DIR)/*.bats

# renders the task resource file printing it out on the standard output, you can redirect the output
# of this target to a `kubectl apply -f -`, for istance
helm-template:
	helm template $(ARGS) $(PROJECT_NAME) .

# renders and installs the task in the current namespace
install:
	helm template $(PROJECT_NAME) . |kubectl $(ARGS) apply -f -

# packages the helm-chart as a single tarball, using it's name and version to compose the file
helm-package:
	rm -f $(PROJECT_NAME)-*.tgz || true
	helm package $(ARGS) . && \
		tar -ztvpf $(PROJECT_NAME)-*.tgz

# removes the package helm chart, and also the chart-releaser temporary directories
clean:
	rm -rf $(PROJECT_NAME)-*.tgz > /dev/null 2>&1 || true

# act runs the github actions workflows, so by default only running the test workflow (integration
# and end-to-end) to avoid running the release workflow accidently
act: ARGS = --workflows=./.github/workflows/test.yaml
act:
	act $(ARGS)