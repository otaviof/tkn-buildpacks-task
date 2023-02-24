BATS_CORE = ./test/.bats/bats-core/bin/bats
BATS_FLAGS ?= --print-output-on-failure --show-output-of-passing-tests --verbose-run

INTEGRATION_DIR ?= ./test/integration
E2E_DIR ?= ./test/e2e

# chart-releaser version
CR_VERSION ?= v1.5.0

DIR_NAME = $(shell basename $(CURDIR))

ARGS ?=

.EXPORT_ALL_VARIABLES:

test-integration:
	$(BATS_CORE) $(BATS_FLAGS) $(INTEGRATION_DIR)/*.bats

test-e2e:
	$(BATS_CORE) $(BATS_FLAGS) $(E2E_DIR)/*.bats

install-chart-releaser:
	sudo -E ./hack/install-cr.sh

release:
	./hack/release.sh

helm-package:
	helm package .
	tar ztvpf $(DIR_NAME)-*.tgz

clean:
	rm -f $(DIR_NAME)-*.tgz || true

# act runs the github actions workflows, so by default only running the test workflow (integration
# and end-to-end) to avoid running the release workflow accidently
act: ARGS = --workflows=./.github/workflows/test.yaml
act:
	act $(ARGS)