#!/usr/bin/env bash
#
# Inspects the `/layers/report.toml` to extract attributes about the image built by the CNB, and use
# the data to write the expected Tekton result files.
#

shopt -s inherit_errexit
set -eu -o pipefail

source "$(dirname ${BASH_SOURCE[0]})/functions.sh"

# path to the report.toml, by default it's located on the /layers directory
readonly REPORT_TOML_PATH="${REPORT_TOML_PATH:-/layers/report.toml}"

phase "Making sure report file exists '${REPORT_TOML_PATH}'"
[[ ! -f "${REPORT_TOML_PATH}" ]] &&
	fail "Report file is not found at 'REPORT_TOML_PATH=${REPORT_TOML_PATH}'!"

# tekton result files, the location where tekton pipelines is expecting to find the values for the
# result attributes declared on the task spec
readonly RESULTS_APP_IMAGE_DIGEST_PATH="${RESULTS_APP_IMAGE_DIGEST_PATH:-}"
readonly RESULTS_APP_IMAGE_URL_PATH="${RESULTS_APP_IMAGE_URL_PATH:-}"

for v in RESULTS_APP_IMAGE_DIGEST_PATH RESULTS_APP_IMAGE_URL_PATH; do
    [[ -z "${!v}" ]] &&
        fail "'${v}' environment variable is not set!"
done

#
# Extracting Image Details
#

phase "Extracting result image digest and URL"

readonly digest="$(awk -F '"' '/digest/ { print $2 }' ${REPORT_TOML_PATH})"
readonly image_tag="$(awk -F '"' '/tags/ { print $2 }' ${REPORT_TOML_PATH})"

phase "Writing image digest '${digest}' to '${RESULTS_APP_IMAGE_DIGEST_PATH}'"
printf "%s" "${digest}" >${RESULTS_APP_IMAGE_DIGEST_PATH}

phase "Writing image URL '${image_tag}' to '${RESULTS_APP_IMAGE_URL_PATH}'"
printf "%s" "${image_tag}" >${RESULTS_APP_IMAGE_URL_PATH}
