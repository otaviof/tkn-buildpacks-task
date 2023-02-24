#!/usr/bin/env bash
#
# Makes required configuration for Helm `helm/chart-releaser-action`
#

shopt -s inherit_errexit
set -eu -o pipefail

source ./scripts/functions.sh

readonly GITHUB_ACTOR=${GITHUB_ACTOR:-}

[[ -z "${GITHUB_ACTOR}" ]] && \
	fail "GITHUB_ACTOR environment variable is not set"

set -x
git config user.name "${GITHUB_ACTOR}"
git config user.email "${GITHUB_ACTOR}@users.noreply.github.com"