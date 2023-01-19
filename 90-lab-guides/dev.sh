#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
cd "$SCRIPT_DIR" || fail Unable to cd into the script directory
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common.sh"

< content/_data/login.yml.tpl envsubst '$KUBEADMIN_PASS $LAB_USER_PASSWORD $CLUSTER_NAME $BASE_DOMAIN $INFRA_ENV' > content/_data/login.yml

podman build . -t labguide:dev -f Containerfile.dev --build-arg BUILD_REVISION="$(git rev-parse HEAD)"
podman run --rm -itp 8080:8080 -v ./content:/app --security-opt=label=disable --privileged labguide:dev
