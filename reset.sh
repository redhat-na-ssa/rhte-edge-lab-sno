#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
cd "$SCRIPT_DIR" || fail Unable to cd into the script directory
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

set +e

function delete {
    "$OC" delete --wait "${@}"
}
for num in $(seq $(( VIRT_CLUSTER_COUNT > METAL_CLUSTER_COUNT ? VIRT_CLUSTER_COUNT : METAL_CLUSTER_COUNT ))); do
    for kind in subscription.apps application.app; do
        delete $kind hello-world-student$num -n $INFRA_ENV
    done
    delete placementbinding.policy student$num-binding -n $INFRA_ENV
    delete policy.policy student$num-htpasswd -n $INFRA_ENV
    delete placementrule.apps student$num-placement -n "$INFRA_ENV"

    delete kluterletaddonconfig -n vm$num vm$num
    delete kluterletaddonconfig -n metal$num metal$num
    delete managedcluster vm$num
    delete managedcluster metal$num
    delete secret pullsecret-cluster-student$num -n vm$num
    delete agentclusterinstall vm$num -n vm$num
    delete clusterdeployment.hive vm$num -n vm$num
    delete namespace vm$num
    delete namespace metal$num
done
for infra_env in "${!INFRA_ENV_LOCS[@]}"; do
    delete infraenv $infra_env -n $infra_env
    delete namespace $infra_env
done

pushd "$ANSIBLE_DIR" || fail Unable to change into the ansible directory
"$ANSIBLE_PLAYBOOK" kill-vms.yml
popd || fail Unable to return from the ansible directory

exec ./all.sh
