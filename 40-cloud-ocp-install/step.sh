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

# Configure our certs
if ! "$OC" get secret cluster-api -n openshift-config; then
    "$OC" create secret tls cluster-api --cert="$CLUSTER_FULLCHAIN_FILE" --key="$CLUSTER_PRIVATE_KEY_FILE" -n openshift-config
fi
if ! "$OC" get secret cluster-router -n openshift-ingress; then
    "$OC" create secret tls cluster-router --cert="$CLUSTER_FULLCHAIN_FILE" --key="$CLUSTER_PRIVATE_KEY_FILE" -n openshift-ingress
fi
"$OC" patch ingresscontroller.operator default --type=merge -p '{
    "spec": {
        "defaultCertificate": {
            "name": "cluster-router"
        }
    }
}' -n openshift-ingress-operator
if ! "$OC" patch apiserver.config cluster --type=merge -p '{
    "spec": {
        "servingCerts": {
            "namedCertificates": [
                {
                    "names": [
                        "api.'"$FULL_CLUSTER_NAME"'"
                    ], "servingCertificate": {
                        "name": "cluster-api"
                    }
                }
            ]
        }
    }
}' | grep -qF '(no change)'; then
    # API server certificate has changed
    mv "$KUBECONFIG" "$KUBECONFIG-orig"
    # We need to remove it from the KUBECONFIG
    sed '/certificate-authority-data/d' "$KUBECONFIG"
    # And wait for the rollouts to start with a generous sleep
    sleep 30

    duration=0
    timeout=1800
    step=5
    # Expect the following values from the while loop grep:
    # - empty (an error occurred because we don't have the updated certificate yet)
    # - "True\nFalse" (some cluster operators are not reporting a completed rollout)
    # - "True" (all cluster operators are reporting a completed rollout)
    while [ "$({ "$OC" get co -ojsonpath='{range .items[*].status.conditions[?(@.type=="Available")]}{.status}{"\n"}{end}' ||: ; } | sort -u)" != "True" ]; do
        if (( duration >= timeout )); then
            fail Timed out waiting for API server to recover after certificate update
        else
            (( duration += step ))
            sleep "$step"
        fi
    done
fi
