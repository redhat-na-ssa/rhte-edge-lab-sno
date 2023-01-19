#!/bin/bash

OPENSHIFT_VERSION="${OPENSHIFT_VERSION:-stable-4.12}"
SHORT_VERSION="$(echo "$OPENSHIFT_VERSION" | tr -d '[:lower:]' | tr -d '-')"
CLUSTER_NAME="${CLUSTER_NAME:-edge1}"
BASE_DOMAIN=rhte.edgelab.dev
FULL_CLUSTER_NAME="$CLUSTER_NAME.$BASE_DOMAIN"
AWS_REGION="${AWS_REGION:-us-east-2}"
VIRT_CLUSTER_COUNT=15
INFRA_ENV="${INFRA_ENV:-na}"

set -eu

PROJECT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
DOWNLOAD_DIR="$PROJECT_DIR/tmp"
VENV="$PROJECT_DIR/venv"
OPENSHIFT_INSTALL_DIR="$DOWNLOAD_DIR/install"
ACME_DIR="$DOWNLOAD_DIR/acme.sh"
ANSIBLE_DIR="$PROJECT_DIR/ansible"
ACME_EMAIL='jharmison@redhat.com'

KUBECONFIG="$OPENSHIFT_INSTALL_DIR/auth/kubeconfig"
SSH_PRIV_KEY_FILE="$DOWNLOAD_DIR/id_rsa"
SSH_PUB_KEY_FILE="$DOWNLOAD_DIR/id_rsa.pub"

CLUSTER_CERT_PREFIX="$DOWNLOAD_DIR/$CLUSTER_NAME-cluster"
CLUSTER_CERT_FILE="$CLUSTER_CERT_PREFIX.crt"
CLUSTER_PRIVATE_KEY_FILE="$CLUSTER_CERT_PREFIX-key.pem"
CLUSTER_FULLCHAIN_FILE="$CLUSTER_CERT_PREFIX-fullchain.crt"

VIRT_CERT_PREFIX="$DOWNLOAD_DIR/$CLUSTER_NAME-virt"
VIRT_CERT_FILE="$VIRT_CERT_PREFIX.crt"
VIRT_PRIVATE_KEY_FILE="$VIRT_CERT_PREFIX-key.pem"
VIRT_FULLCHAIN_FILE="$VIRT_CERT_PREFIX-fullchain.crt"

OPENSHIFT_INSTALL="$DOWNLOAD_DIR/openshift-install"
OC="$DOWNLOAD_DIR/oc"
OC_MIRROR="$DOWNLOAD_DIR/oc-mirror"

PIP="$VENV/bin/pip"
AWS="$VENV/bin/aws"
ANSIBLE_PLAYBOOK="$VENV/bin/ansible-playbook"
ANSIBLE_GALAXY="$VENV/bin/ansible-galaxy"

declare -A INFRA_ENV_LOCS=(
  [na]=dallas
  [latam]=buenos_aires
  [emea]=dublin
  [apac]=singapore
)

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

export OPENSHIFT_VERSION
export SHORT_VERSION
export CLUSTER_NAME
export BASE_DOMAIN
export FULL_CLUSTER_NAME
export AWS_REGION
export VIRT_CLUSTER_COUNT
export INFRA_ENV

export PROJECT_DIR
export DOWNLOAD_DIR
export VENV
export OPENSHIFT_INSTALL_DIR
export ACME_DIR
export ANSIBLE_DIR
export ACME_EMAIL

export KUBECONFIG
export SSH_PRIV_KEY_FILE
export SSH_PUB_KEY_FILE
if [ -f "$SSH_PUB_KEY_FILE" ]; then
    SSH_PUB_KEY="$(cat "$SSH_PUB_KEY_FILE")"
    export SSH_PUB_KEY
fi

export CLUSTER_CERT_PREFIX
export CLUSTER_CERT_FILE
export CLUSTER_PRIVATE_KEY_FILE
export CLUSTER_FULLCHAIN_FILE

export VIRT_CERT_PREFIX
export VIRT_CERT_FILE
export VIRT_PRIVATE_KEY_FILE
export VIRT_FULLCHAIN_FILE

export OPENSHIFT_INSTALL
export OC
export OC_MIRROR

export PIP
export AWS
export ANSIBLE_PLAYBOOK
export ANSIBLE_GALAXY

export INFRA_ENV_LOCS

function set_hosted_zone {
    # Set the hosted zone ID for our expected cluster domain
    HOSTED_ZONE="$("$AWS" route53 list-hosted-zones | jq -r '.HostedZones[] | select(.Name == "'"$BASE_DOMAIN"'.") | .Id' | rev | cut -d/ -f1 | rev)"
    export HOSTED_ZONE
}

set -x
