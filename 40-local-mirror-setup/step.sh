#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
cd "$SCRIPT_DIR" || fail Unable to change into script directory
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common.sh"

if ! [ "$(podman volume ls | grep -c 'rhte-sno-\(image\|registry\)-data')" -eq 2 ]; then
    podman play kube infra-pvcs.yml
fi

podman play kube --replace infra.yml

< "$SCRIPT_DIR/imageset-configuration.tpl" envsubst '$OPENSHIFT_VERSION' > "$DOWNLOAD_DIR/imageset-configuration.yml"
cd "$DOWNLOAD_DIR" || fail Unable to change to the download directory
"$OC_MIRROR" --dest-use-http --config=imageset-configuration.yml docker://localhost:5000
