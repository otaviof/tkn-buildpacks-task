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

for v in WORKSPACES_SOURCE_PATH SERVICE_BINDING_ROOT; do
    [[ -z "${!v}" ]] &&
        fail "'${v}' environment variable is not set!"
done

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
readonly tekton_home="${BASE_DIR}/tekton/home"
# buildpacks platform environment directory
readonly env_dir="${BASE_DIR}/platform/env"
# buildapcks layers directory, where the buildpacks components are stored and assembled
readonly layers_dir="${BASE_DIR}/layers"

#
# Filesystem Permissions
#

phase "Preparing the filesystem ('BASE_DIR=${BASE_DIR}')"

if [ "${WORKSPACES_CACHE_BOUND}" == "true" ]; then
    phase "Setting permissions on '${WORKSPACES_CACHE_PATH}'"
    chown -R "${PARAMS_USER_ID}:${PARAMS_GROUP_ID}" "${WORKSPACES_CACHE_PATH}"
fi

for d in "${tekton_home}" \
    "${layers_dir}" \
    "${WORKSPACES_SOURCE_PATH}" \
    "${WORKSPACES_CACHE_PATH}"; do
    # skipping optional workspaces (and directories), the directory name is empty
    [[ -z "${d}" ]] && continue

    phase "Setting permissions on '${d}' ('${PARAMS_USER_ID}:${PARAMS_GROUP_ID}')"
    chown -R "${PARAMS_USER_ID}:${PARAMS_GROUP_ID}" "${d}"
done

chmod 775 "${WORKSPACES_SOURCE_PATH}"

#
# Additional Configuration
#

phase "Parsing additional configuration (--env-vars)"

parsing_flag=""
environment_variables=()

for arg in ${@}; do
    if [ "${arg}" == "--env-vars" ]; then
        phase "Parsing environment variables"
        parsing_flag="env-vars"
    elif [ "${parsing_flag}" == "env-vars" ]; then
        environment_variables+=("${arg}")
    fi
done

phase "Processing environment variables"

phase "Creating 'env' directory at '${env_dir}'"
[[ ! -d "${env_dir}" ]] &&
    mkdir -pv "${env_dir}"

for kv in "${environment_variables[@]}"; do
    IFS='=' read -r key value <<<"${kv}"
    if [[ -n "${key}" && -n "${value}" ]]; then
        file_path="${env_dir}/${key}"
        phase "Writing environment file '${file_path}'"
        echo -n "${value}" >"${file_path}"
    fi
done

#
# Bindings
#

phase "Preparing buildpacks bindings '${SERVICE_BINDING_ROOT}'"
[[ ! -d "${SERVICE_BINDING_ROOT}" ]] &&
    mkdir -pv "${SERVICE_BINDING_ROOT}"

for f in $(find ${WORKSPACES_BINDINGS_PATH} -name "*.pem"); do
    phase "Copying PEM file '${f}' into '${SERVICE_BINDING_ROOT}'"
    cp -v ${f} ${SERVICE_BINDING_ROOT}
done
