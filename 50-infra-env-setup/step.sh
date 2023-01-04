#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
cd "$SCRIPT_DIR" || fail Unable to change into script directory
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common.sh"

"$OC" apply -f agentserviceconfig.yml
< cim-nlb.tpl envsubst '$FULL_CLUSTER_NAME' > "$DOWNLOAD_DIR/cim-nlb.yml"
"$OC" apply -f "$DOWNLOAD_DIR/cim-nlb.yml"
while ! "$OC" get route -n multicluster-engine assisted-image-service; do
    sleep 5
done
"$OC" patch route -n multicluster-engine assisted-image-service -p '
{
    "metadata": {
        "labels": {
            "router-type": "nlb"
        }
    }, "spec": {
        "host": "assisted-image-service-multicluster-engine.nlb-apps.'"$FULL_CLUSTER_NAME"'"
    }
}'
"$OC" apply -f provisioning.yml

SSH_PUB_KEY="$(cat "$DOWNLOAD_DIR/id_rsa.pub")"
export SSH_PUB_KEY

{ set +x ; } &>/dev/null
PULL_SECRET_B64="$(< ~/.pull-secret.json base64 -w0)"
set -x
export PULL_SECRET_B64
for env_name in "${!INFRA_ENV_LOCS[@]}"; do
    env_loc="${INFRA_ENV_LOCS[$env_name]}"
    export env_name
    export env_loc
    < infraenv.tpl envsubst '$env_name $env_loc $SSH_PUB_KEY $PULL_SECRET_B64' > "$DOWNLOAD_DIR/infraenv-$env_name.yml"
    "$OC" apply -f "$DOWNLOAD_DIR/infraenv-$env_name.yml"
done
