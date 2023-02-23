BATS_CORE = ./test/.bats/bats-core/bin/bats
BATS_FLAGS ?= --print-output-on-failure --show-output-of-passing-tests --verbose-run

INTEGRATION_DIR ?= ./test/integration
E2E_DIR ?= ./test/e2e

test-integration:
	$(BATS_CORE) $(BATS_FLAGS) $(INTEGRATION_DIR)/*.bats

test-e2e:
	$(BATS_CORE) $(BATS_FLAGS) $(E2E_DIR)/*.bats