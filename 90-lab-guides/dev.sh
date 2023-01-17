#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
cd "$SCRIPT_DIR" || fail Unable to cd into the script directory
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common.sh"

podman build . -t labguide:dev -f Containerfile.dev --build-arg BUILD_REVISION="$(git rev-parse HEAD)"
podman run --rm -itp 8080:8080 -v ./content:/app --security-opt=label=disable --privileged labguide:dev
