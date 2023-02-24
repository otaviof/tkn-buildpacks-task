BATS_CORE = ./test/.bats/bats-core/bin/bats
BATS_FLAGS ?= --print-output-on-failure --show-output-of-passing-tests --verbose-run

INTEGRATION_DIR ?= ./test/integration
E2E_DIR ?= ./test/e2e

ARGS ?=

test-integration:
	$(BATS_CORE) $(BATS_FLAGS) $(INTEGRATION_DIR)/*.bats

test-e2e:
	$(BATS_CORE) $(BATS_FLAGS) $(E2E_DIR)/*.bats

# act runs the github actions workflows, so by default only running the test workflow (integration
# and end-to-end) to avoid running the release workflow accidently
act: ARGS = --workflows=./.github/workflows/test.yaml
act:
	act $(ARGS)