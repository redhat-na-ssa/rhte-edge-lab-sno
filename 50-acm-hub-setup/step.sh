#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
cd "$SCRIPT_DIR" || fail Unable to change into script directory
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common.sh"

split_arg() {
    echo "$*" | cut -d= -f2-
}

wait_for() {
    args=()
    local kind=""
    local namespace=""
    local name=""
    local jsonpath=""
    local expected=""
    local timeout=""
    local step=""

    while (( ${#} >0 )); do
        case "$1" in
            --kind=*)
                kind="$(split_arg "$1")"
                ;;
            --namespace=*)
                namespace="$(split_arg "$1")"
                ;;
            --name=*)
                name="$(split_arg "$1")"
                ;;
            --jsonpath=*)
                jsonpath="$(split_arg "$1")"
                ;;
            --expected=*)
                expected="$(split_arg "$1")"
                ;;
            --timeout=*)
                timeout="$(split_arg "$1")"
                ;;
            --step=*)
                step="$(split_arg "$1")"
                ;;
            *)
                args+=("$1")
                ;;
        esac; shift
    done
    if [ -z "$expected" ]; then
        fail Unable to wait for null condition
    fi
    timeout="${timeout:-300}"
    step="${step:-5}"

    args+=("$kind")
    if [ -n "$namespace" ]; then
        args+=(-n "$namespace")
    fi
    args+=("$name" -ojsonpath="$jsonpath")

    duration=0
    while ! { "$OC" get "${args[@]}" ||: ; } | grep -qF "$expected"; do
        if (( duration >= timeout )); then
            fail Timed out waiting for "$kind" "$name" to reach "$jsonpath" "$expected" after "$timeout" seconds
        else
            (( duration += step ))
            sleep "$step"
        fi
    done
}

"$OC" apply -f subscription.yml

wait_for \
    --kind=subscriptions.v1alpha1.operators.coreos.com \
    --namespace=open-cluster-management \
    --name=advanced-cluster-management \
    --jsonpath='{.status.state}' \
    --expected=AtLatestKnown

"$OC" apply -f hub.yml

wait_for \
    --kind=multiclusterhub.v1.operator.open-cluster-management.io \
    --namespace=open-cluster-management \
    --name=multiclusterhub \
    --jsonpath='{.status.phase}' \
    --timeout=900 \
    --expected=Running
