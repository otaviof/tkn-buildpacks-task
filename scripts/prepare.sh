#!/usr/bin/env bash
#
# Prepares the Tekton current context to execute a Buildpacks CNB, which means the files and
# permissions must be in place, and special environment variables needs to become files in the
# "/platform/env" directory.
#

shopt -s inherit_errexit
set -xeu -o pipefail

source "$(dirname ${BASH_SOURCE[0]})/functions.sh"

# base directory for all fullpaths
readonly BASE_DIR="${BASE_DIR:-}"

# workspace directories
readonly WORKSPACES_CACHE_PATH="${BASE_DIR}/${WORKSPACES_CACHE_PATH}"
readonly WORKSPACES_SOURCE_PATH="${BASE_DIR}/${WORKSPACES_SOURCE_PATH}"

# buildpacks platform environment directory
readonly ENV_DIR="${BASE_DIR}/platform/env"

#
# Filesystem Permissions
#

phase "Preparing the filesystem ('BASE_DIR=${BASE_DIR}')"

if [ "${WORKSPACES_CACHE_BOUND}" == "true" ]; then
    phase "Setting permissions on '${WORKSPACES_CACHE_PATH}'"
    chown -R "${PARAMS_USER_ID}:${PARAMS_GROUP_ID}" "${WORKSPACES_CACHE_PATH}"
fi

for DIR in "${BASE_DIR}/tekton/home" "${BASE_DIR}/layers" "${WORKSPACES_SOURCE_PATH}"; do
    phase "Setting permissions on '${DIR}' ('${PARAMS_USER_ID}:${PARAMS_GROUP_ID}')"
    chown -R "${PARAMS_USER_ID}:${PARAMS_GROUP_ID}" "${DIR}"
done

chmod 775 "${WORKSPACES_SOURCE_PATH}"

#
# Additional Configuration
#

phase "Parsing additional configuration"

PARSING_FLAG=""
ENVS=()

for ARG in ${@}; do
    if [ "${ARG}" == "--env-vars" ]; then
        phase "Parsing environment variables"
        PARSING_FLAG="env-vars"
    elif [ "${PARSING_FLAG}" == "env-vars" ]; then
        ENVS+=("${ARG}")
    fi
done

phase "Processing environment variables"

phase "Creating 'env' directory '${ENV_DIR}'"
[[ ! -d "${ENV_DIR}" ]] && mkdir -p "${ENV_DIR}"

for KV in "${ENVS[@]}"; do
    IFS='=' read -r KEY VALUE <<<"${KV}"
    if [[ -n "${KEY}" && -n "${VALUE}" ]]; then
        FILE_PATH="${ENV_DIR}/${KEY}"
        phase "Writing environment file '${FILE_PATH}'"
        echo -n "${VALUE}" >"${FILE_PATH}"
    fi
done
