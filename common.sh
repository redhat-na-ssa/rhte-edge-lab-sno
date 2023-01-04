#!/bin/bash

OPENSHIFT_VERSION="${OPENSHIFT_VERSION:-candidate-4.12}"
SHORT_VERSION="$(echo "$OPENSHIFT_VERSION" | tr -d '[:lower:]' | tr -d '-')"
CLUSTER_NAME="${CLUSTER_NAME:-edge1}"
BASE_DOMAIN=rhte.edgelab.dev
FULL_CLUSTER_NAME="$CLUSTER_NAME.$BASE_DOMAIN"
AWS_REGION="${AWS_REGION:-us-east-2}"

set -eux

PROJECT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
DOWNLOAD_DIR="$PROJECT_DIR/tmp"
KUBECONFIG="$DOWNLOAD_DIR/install/auth/kubeconfig"

OPENSHIFT_INSTALL="$DOWNLOAD_DIR/openshift-install"
OC="$DOWNLOAD_DIR/oc"
OC_MIRROR="$DOWNLOAD_DIR/oc-mirror"

declare -A INFRA_ENV_LOCS=(
  [na]=dallas
  [latam]=buenos_aires
  [emea]=dublin
  [apac]=singapore
)

function cleanup {
    if [ -n "${tmp_dir:-}" ]; then
        set -x
        cd "$PROJECT_DIR" || cd ||:
        rm -rf "$tmp_dir"
    fi
}

function fail_trap {
    { set +x ; } &>/dev/null
    msg="${1}"
    line="${2}"
    echo "Failure in ${0} at line $line: $msg" >&2
}

function fail {
    { set +x ; } &>/dev/null
    echo "$*"
    exit 1
}

trap 'fail_trap "${BASH_COMMAND}" "${LINENO}"' ERR
trap 'cleanup' EXIT

export OPENSHIFT_VERSION
export SHORT_VERSION
export CLUSTER_NAME
export BASE_DOMAIN
export FULL_CLUSTER_NAME
export AWS_REGION

export PROJECT_DIR
export DOWNLOAD_DIR
export KUBECONFIG

export OPENSHIFT_INSTALL
export OC
export OC_MIRROR

export INFRA_ENV_LOCS
