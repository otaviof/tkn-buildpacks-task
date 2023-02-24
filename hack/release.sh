#!/usr/bin/env bash
#
# Uses the `helm/chart-releaser` (cr) to package and relase the local chart, the artifact version
# must be the same than the current repository tag. This script packages and upload the data to
# GitHub.
#

shopt -s inherit_errexit
set -eu -o pipefail

source ./scripts/functions.sh

# inspecting the enviroment variables to load all the configuration the chart-releaser needs, that
# includes the GitHub repository coordinates and access token
phase "Loading configuration from environment variables"

# branch or tag triggering the workflow, for the release purposes it must be the same than the chart
# version, thus a repository tag
readonly GITHUB_REF_NAME="${GITHUB_REF_NAME:-}"
readonly GITHUB_ACTOR="${GITHUB_ACTOR:-}"
readonly GITHUB_TOKEN="${GITHUB_TOKEN:-}"
readonly GITHUB_REPOSITORY_NAME="${GITHUB_REPOSITORY_NAME:-}"

[[ -z "${GITHUB_REF_NAME}" ]] && \
	fail "GITHUB_REF_NAME environment variable is not set"

[[ -z "${GITHUB_ACTOR}" ]] && \
	fail "GITHUB_ACTOR environment variable is not set"

[[ -z "${GITHUB_TOKEN}" ]] && \
	fail "GITHUB_TOKEN environment variable is not set"

[[ -z "${GITHUB_REPOSITORY_NAME}" ]] && \
	fail "GITHUB_REPOSITORY_NAME environment variable is not set"

# making sure the chart name and version can be extracted from the Chart.yaml file, it must be
# located in the current directory where the script is being executed
phase "Extrating chart name and version"

[[ ! -f "Chart.yaml" ]] && \
	fail "Chart.yaml is not found on '${PWD}'"

readonly CHART_NAME="$(awk '/^name:/ { print $2 }' Chart.yaml)"
readonly CHART_VERSION="$(awk '/^version:/ { print $2 }' Chart.yaml)"
readonly CHART_TARBALL=".cr-release-packages/${CHART_NAME}-${CHART_VERSION}.tgz"

[[ -z "${CHART_NAME}" ]] && \
	fail "CHART_NAME can't be otainted from Chart.yaml"

[[ -z "${CHART_VERSION}" ]] && \
	fail "CHART_VERSION can't be otainted from Chart.yaml"

[[ "${GITHUB_REF_NAME}" != "${CHART_VERSION}" ]] && \
	fail "Git tag '${GITHUB_REF_NAME}' and chart version '${CHART_VERSION}' must be the same!"

# creating a tarball out of the chart, ignoring files based on the `.helmignore`
phase "Packaing chart '${CHART_NAME}-${CHART_VERSION}'"
cr package

[[ ! -f "${CHART_TARBALL}" ]] && \
	fail "'${CHART_TARBALL}' is not found!"

# showing the contents of the tarball, here it's important to check if there are cluttering that
# should be added to the `.helmignore`
phase "Package contents '${CHART_TARBALL}'"
tar -ztvpf ${CHART_TARBALL}

# uploading the chart release using it's version as the release name
phase "Uploading chart to '${GITHUB_ACTOR}/${GITHUB_REPOSITORY_NAME}' ($CHART_VERSION)"
cr upload \
	--owner=${GITHUB_ACTOR} \
	--git-repo=${GITHUB_REPOSITORY_NAME} \
	--token=${GITHUB_TOKEN} \
	--release-name-template='{{ .Version }}'
