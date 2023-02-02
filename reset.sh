#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
cd "$SCRIPT_DIR" || fail Unable to cd into the script directory
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

for num in $(seq $(( VIRT_CLUSTER_COUNT > METAL_CLUSTER_COUNT ? VIRT_CLUSTER_COUNT : METAL_CLUSTER_COUNT ))); do
    for kind in subscription.apps application.app; do
        "$OC" delete $kind hello-world-student$num -n $INFRA_ENV --wait
    done
    oc delete placementbinding.policy student$num-binding -n $INFRA_ENV --wait
    oc delete policy.policy student$num-htpasswd -n $INFRA_ENV --wait
    oc delete placementrule.apps student$num-placement -n "$INFRA_ENV" --wait
done
