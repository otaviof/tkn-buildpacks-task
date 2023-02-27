#!/usr/bin/env bash
#
# Prepares the Tekton current context to execute a Buildpacks CNB, which means the files and
# permissions must be in place, and special environment variables needs to become files in the
# "/platform/env" directory.
#

shopt -s inherit_errexit
set -xeu -o pipefail

source "$(dirname ${BASH_SOURCE[0]})/functions.sh"

phase "Searching the environment for the required variables"

# base directory for all fullpaths, allows integration testing
readonly BASE_DIR="${BASE_DIR:-}"

WORKSPACES_SOURCE_PATH="${WORKSPACES_SOURCE_PATH:-}"
WORKSPACES_CACHE_PATH="${WORKSPACES_CACHE_PATH:-}"
WORKSPACES_BINDINGS_PATH="${WORKSPACES_BINDINGS_PATH:-}"
SERVICE_BINDING_ROOT=${SERVICE_BINDING_ROOT:-}

[[ -z "${WORKSPACES_SOURCE_PATH}" ]] &&
    fail "'WORKSPACES_SOURCE_PATH' environment variable is not set!"

[[ -z "${SERVICE_BINDING_ROOT}" ]] &&
    fail "'SERVICE_BINDING_ROOT' environment variable is not set!"

# making sure the directory paths needed in this script start on the base directory (BASE_DIR),
# therefore we can simulate the script enviroment
readonly WORKSPACES_SOURCE_PATH="${BASE_DIR}/${WORKSPACES_SOURCE_PATH}"
readonly SERVICE_BINDING_ROOT="${BASE_DIR}/${SERVICE_BINDING_ROOT}"

[[ -n "${WORKSPACES_CACHE_PATH}" ]] &&
    WORKSPACES_CACHE_PATH="${BASE_DIR}/${WORKSPACES_CACHE_PATH}"

[[ -n "${WORKSPACES_BINDINGS_PATH}" ]] &&
    WORKSPACES_BINDINGS_PATH="${BASE_DIR}/${WORKSPACES_BINDINGS_PATH}"

readonly WORKSPACES_CACHE_PATH
readonly WORKSPACES_BINDINGS_PATH

# sets a wider cache directory permission
readonly WORKSPACES_CACHE_BOUND=${WORKSPACES_CACHE_BOUND:-false}

# tekton home directory, by convention
readonly TEKTON_HOME="${BASE_DIR}/tekton/home"
# buildpacks platform environment directory
readonly ENV_DIR="${BASE_DIR}/platform/env"
# buildapcks layers directory, where the buildpacks components are stored and assembled
readonly LAYERS_DIR="${BASE_DIR}/layers"

#
# Filesystem Permissions
#

phase "Preparing the filesystem ('BASE_DIR=${BASE_DIR}')"

if [ "${WORKSPACES_CACHE_BOUND}" == "true" ]; then
    phase "Setting permissions on '${WORKSPACES_CACHE_PATH}'"
    chown -R "${PARAMS_USER_ID}:${PARAMS_GROUP_ID}" "${WORKSPACES_CACHE_PATH}"
fi

for DIR in "${TEKTON_HOME}" \
    "${LAYERS_DIR}" \
    "${WORKSPACES_SOURCE_PATH}" \
    "${WORKSPACES_CACHE_PATH}"; do
    # skipping optional workspaces (and directories), the directory name is empty
    [[ -z "${DIR}" ]] && continue

    phase "Setting permissions on '${DIR}' ('${PARAMS_USER_ID}:${PARAMS_GROUP_ID}')"
    chown -R "${PARAMS_USER_ID}:${PARAMS_GROUP_ID}" "${DIR}"
done

chmod 775 "${WORKSPACES_SOURCE_PATH}"

#
# Additional Configuration
#

phase "Parsing additional configuration (--env-vars)"

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

phase "Creating 'env' directory at '${ENV_DIR}'"
[[ ! -d "${ENV_DIR}" ]] &&
    mkdir -pv "${ENV_DIR}"

for KV in "${ENVS[@]}"; do
    IFS='=' read -r KEY VALUE <<<"${KV}"
    if [[ -n "${KEY}" && -n "${VALUE}" ]]; then
        FILE_PATH="${ENV_DIR}/${KEY}"
        phase "Writing environment file '${FILE_PATH}'"
        echo -n "${VALUE}" >"${FILE_PATH}"
    fi
done

#
# Bindings
#

phase "Preparing buildpacks bindings '${SERVICE_BINDING_ROOT}'"
[[ ! -d "${SERVICE_BINDING_ROOT}" ]] &&
    mkdir -pv "${SERVICE_BINDING_ROOT}"

for F in $(find ${WORKSPACES_BINDINGS_PATH} -name "*.pem"); do
    phase "Copying PEM file '${F}' into '${SERVICE_BINDING_ROOT}'"
    cp -v ${F} ${SERVICE_BINDING_ROOT}
done
