BATS_CORE = ./test/.bats/bats-core/bin/bats
BATS_FLAGS ?= --print-output-on-failure --show-output-of-passing-tests --verbose-run

INTEGRATION_DIR ?= ./test/integration
E2E_DIR ?= ./test/e2e

# chart-releaser version installed by `install-chart-relaser` target
CR_VERSION ?= v1.5.0

DIR_NAME = $(shell basename $(CURDIR))

ARGS ?=

.EXPORT_ALL_VARIABLES:

# run the integration tests, does not require a kubernetes instance
test-integration:
	$(BATS_CORE) $(BATS_FLAGS) $(INTEGRATION_DIR)/*.bats

# run end-to-end tests against the current kuberentes context, it will required a cluster with tekton
# pipelines and other requirements installed
test-e2e:
	$(BATS_CORE) $(BATS_FLAGS) $(E2E_DIR)/*.bats

# installs the chart-releaser (cr) command-line, employed on the release target
install-chart-releaser:
	sudo -E ./hack/install-cr.sh

# runs the release script, which creates a new GitHub release uploading the chart tarball package and
# a rendered task file as well
release:
	./hack/release.sh

# renders the task resource file printing it out on the standard output, you can redirect the output
# of this target to a `kubectl apply -f -`, for istance
helm-template:
	helm template $(DIR_NAME) .

# pacakges the helm-chart as a single tarball, using it's name and version to compose the file
helm-package:
	helm package .
	tar ztvpf $(DIR_NAME)-*.tgz

# removes the package helm chart, and also the temporary directories for the chart-releaser
clean:
	rm -rf $(DIR_NAME)-*.tgz .cr-* > /dev/null 2>&1 || true

# act runs the github actions workflows, so by default only running the test workflow (integration
# and end-to-end) to avoid running the release workflow accidently
act: ARGS = --workflows=./.github/workflows/test.yaml
act:
	act $(ARGS)