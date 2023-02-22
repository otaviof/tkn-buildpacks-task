#!/usr/bin/env bash

shopt -s inherit_errexit
set -xeu -o pipefail

source functions.sh

#
# Filesystem Permissions
#

phase "Preparing the filesystem"

if [ "${WORKSPACES_CACHE_BOUND}" == "true" ]; then
    phase "Setting permissions on '${WORKSPACES_CACHE_PATH}'"
    chown -R "${PARAMS_USER_ID}:${PARAMS_GROUP_ID}" "${WORKSPACES_CACHE_PATH}"
fi

for DIR in "/tekton/home" "/layers" "${WORKSPACES_SOURCE_PATH}"; do
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

for arg in "${@}"; do
    if [ "${arg}" == "--env-vars" ]; then
        phase "Parsing environment variables"
        PARSING_FLAG="env-vars"
    elif [ "${PARSING_FLAG}" == "env-vars" ]; then
        ENVS+=("${arg}")
    fi
done

phase "Processing environment variables"

readonly ENV_DIR="/platform/env"

phase "Creating 'env' directory '${ENV_DIR}'"
[[ ! -d "${ENV_DIR}" ]] && mkdir -p "${ENV_DIR}"

for KV in "${ENVS[@]}"; do
    IFS='=' read -r KEY VALUE <<<"${KV}"
    if [[ ! -n "${KEY}" && ! -n "${VALUE}" ]]; then
        FILE_PATH="${ENV_DIR}/${KEY}"
        phase "Writing '${FILE_PATH}'"
        echo -n "${VALUE}" >"${FILE_PATH}"
    fi
done
