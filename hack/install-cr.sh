#!/usr/bin/env bash
#
# Installs the Tekton CLI (tkn) informed version.
#

shopt -s inherit_errexit
set -eu -o pipefail

source ./scripts/functions.sh

readonly CR_VERSION="${CR_VERSION:-}"

[[ -z "${CR_VERSION}" ]] && \
	fail "CR_VERSION enviroment variable is not set!"

# the version needs to be numeric only to compose the tarball name
readonly CR_SHORT_VERSION="${CR_VERSION//v/}"

readonly CR_TARBALL="chart-releaser_${CR_SHORT_VERSION}_linux_amd64.tar.gz"
readonly CR_HOST_PATH="helm/chart-releaser/releases/download"
readonly CR_URL="https://github.com/${CR_HOST_PATH}/${CR_VERSION}/${CR_TARBALL}"

readonly TMP_DIR="/tmp"
readonly OUTPUT_DOCUMENT="${TMP_DIR}/${CR_TARBALL}"

phase "Installing chart-releaser '${CR_VERSION}'"

# making sure the previous download is removed
[[ -f "${OUTPUT_DOCUMENT}" ]] && rm -fv ${OUTPUT_DOCUMENT}

phase "Downloading the chart-releaser tarball '${CR_URL}'"
wget --quiet --output-document="${OUTPUT_DOCUMENT}" ${CR_URL}
tar -C ${TMP_DIR} -zxvpf ${OUTPUT_DOCUMENT} cr

phase "Installing the CR executable"
exec install --verbose --mode=0755 "${TMP_DIR}/cr" /usr/local/bin