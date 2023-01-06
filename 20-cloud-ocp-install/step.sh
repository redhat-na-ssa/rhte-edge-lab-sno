#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
cd "$SCRIPT_DIR" || fail Unable to change into script directory
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common.sh"

# Ensure that SSH keys are generated
if [ ! -f id_rsa ] || [ ! -f id_rsa.pub ]; then
    ssh-keygen -t rsa -b 4096 -C 'admin@edgelab.dev' -N '' -f ./id_rsa
fi
SSH_PUB_KEY="$(cat id_rsa.pub)"
export SSH_PUB_KEY

# Grab and format our pull secret
{ set +x ; } &>/dev/null
PULL_SECRET="$(< ~/.pull-secret.json tr '\n' ' ' | sed 's/\s\+//g')"
set -x
export PULL_SECRET

if [ ! -f "$KUBECONFIG" ]; then
    if [ -d install ]; then
        mv install "install-$(date --iso-8601=seconds)"
    fi
    mkdir install
    cd install || fail Unable to change to install directory
    < "$SCRIPT_DIR/install-config.tpl" envsubst '$BASE_DOMAIN $CLUSTER_NAME $AWS_REGION $SSH_PUB_KEY $PULL_SECRET' > install-config.yaml
    "$OPENSHIFT_INSTALL" create cluster
    cd .. || fail Unable to return from the install directory
fi

"$OC" whoami --show-server
"$OC" whoami
