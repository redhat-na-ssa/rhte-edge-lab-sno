#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common.sh"
cd "$DOWNLOAD_DIR" || fail Unable to change to the download dir

# Grab and format our pull secret
{ set +x ; } &>/dev/null
PULL_SECRET="$(< ~/.pull-secret.json tr '\n' ' ' | sed 's/\s\+//g')"
set -x
export PULL_SECRET

if [ ! -f "$KUBECONFIG" ]; then
    if [ -d "$OPENSHIFT_INSTALL_DIR" ]; then
        mv "$OPENSHIFT_INSTALL_DIR" "$OPENSHIFT_INSTALL_DIR-$(date --iso-8601=seconds)"
    fi
    mkdir "$OPENSHIFT_INSTALL_DIR"
    < "$SCRIPT_DIR/install-config.tpl" envsubst \
        '$BASE_DOMAIN $CLUSTER_NAME $AWS_REGION $SSH_PUB_KEY $PULL_SECRET' \
        > "$OPENSHIFT_INSTALL_DIR/install-config.yaml"
    "$OPENSHIFT_INSTALL" create cluster --dir="$OPENSHIFT_INSTALL_DIR"
fi

"$OC" whoami --show-server
"$OC" whoami
