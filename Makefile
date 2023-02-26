BATS_CORE = ./test/.bats/bats-core/bin/bats
BATS_FLAGS ?= --print-output-on-failure --show-output-of-passing-tests --verbose-run

INTEGRATION_DIR ?= ./test/integration
E2E_DIR ?= ./test/e2e

# usnig the current directory name as the project name
PROJECT_NAME ?= $(shell basename $(CURDIR))

ARGS ?=

.EXPORT_ALL_VARIABLES:

# run the integration tests, does not require a kubernetes instance
test-integration:
	$(BATS_CORE) $(BATS_FLAGS) $(INTEGRATION_DIR)/*.bats

# run end-to-end tests against the current kuberentes context, it will required a cluster with tekton
# pipelines and other requirements installed
test-e2e:
	$(BATS_CORE) $(BATS_FLAGS) $(E2E_DIR)/*.bats

# renders the task resource file printing it out on the standard output, you can redirect the output
# of this target to a `kubectl apply -f -`, for istance
helm-template:
	helm template $(PROJECT_NAME) .

# packages the helm-chart as a single tarball, using it's name and version to compose the file
helm-package:
	helm package .
	tar ztvpf $(PROJECT_NAME)-*.tgz

# renders and installs the task in the current namespace
install:
	helm template $(PROJECT_NAME) . |kubectl apply -f -

# removes the package helm chart, and also the temporary directories for the chart-releaser
clean:
	rm -rf $(PROJECT_NAME)-*.tgz .cr-* > /dev/null 2>&1 || true

# act runs the github actions workflows, so by default only running the test workflow (integration
# and end-to-end) to avoid running the release workflow accidently
act: ARGS = --workflows=./.github/workflows/test.yaml
act:
	act $(ARGS)