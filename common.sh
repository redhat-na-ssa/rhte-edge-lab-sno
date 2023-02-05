#!/bin/bash

OPENSHIFT_VERSION="${OPENSHIFT_VERSION:-stable-4.12}"
SHORT_VERSION="$(echo "$OPENSHIFT_VERSION" | tr -d '[:lower:]' | tr -d '-')"
CLUSTER_NAME="${CLUSTER_NAME:-edge1}"
BASE_DOMAIN="${BASE_DOMAIN:-rhte.edgelab.dev}"
FULL_CLUSTER_NAME="$CLUSTER_NAME.$BASE_DOMAIN"
AWS_REGION="${AWS_REGION:-us-east-2}"
declare -A AWS_AMIS
AWS_AMIS[us-east-2]=ami-0c39257433c03e8ad
AWS_AMIS[eu-west-1]=ami-0a988768d3b40afd2
AWS_AMIS[ap-southeast-1]=ami-0816720497fc1763a
AWS_AMIS[sa-east-1]=ami-0cb86104c83a5f6bd

VIRT_CLUSTER_COUNT=${VIRT_CLUSTER_COUNT:-15}
METAL_CLUSTER_COUNT=${METAL_CLUSTER_COUNT:-15}
INFRA_ENV="${INFRA_ENV:-na}"
LAB_INFRA_INTERFACE="${LAB_INFRA_INTERFACE:-enp0s31f6}"
LAB_INFRA_IP="${LAB_INFRA_IP:-192.168.99.1}"
LAB_INFRA_NETWORK="${LAB_INFRA_NETWORK:-192.168.99.0/24}"
LAB_WAN_NM_CONN="${LAB_WAN_NM_CONN:-Harmison}"
METAL_INSTANCE_NIC="${METAL_INSTANCE_NIC:-enp2s0}"

DEFAULT_MAC_ADDRESS=da:d5:de:ad:be:ef
declare -A METAL_MAC_ADDRESSES=(
    [metal1_na]=84:8b:cd:4d:16:37
    [metal2_na]=84:8b:cd:4d:15:79
    [metal3_na]=84:8b:cd:4d:16:2f
    [metal4_na]=84:8b:cd:4d:15:6f
    [metal5_na]=84:8b:cd:4d:15:63
    [metal6_na]=84:8b:cd:4d:15:eb
    [metal7_na]=84:8b:cd:4d:15:c8
    [metal8_na]=84:8b:cd:4d:14:a3
    [metal9_na]=84:8b:cd:4d:15:c7
    [metal10_na]=84:8b:cd:4d:14:67
    [metal11_na]=84:8b:cd:4d:14:62
    [metal12_na]=84:8b:cd:4d:14:73
    [metal13_na]=84:8b:cd:4d:15:56
    [metal14_na]=84:8b:cd:4d:14:c5
    [metal15_na]=84:8b:cd:4d:14:44
)

set -eu

PROJECT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
DOWNLOAD_DIR="$PROJECT_DIR/tmp"
VENV="$PROJECT_DIR/venv"
OPENSHIFT_INSTALL_DIR="$DOWNLOAD_DIR/install"
ACME_DIR="$DOWNLOAD_DIR/acme.sh"
ANSIBLE_DIR="$PROJECT_DIR/ansible"
ACME_EMAIL='jharmison@redhat.com'
ZEROSSL_CREDS_FILE="$HOME/.zerossl"

KUBECONFIG="$OPENSHIFT_INSTALL_DIR/auth/kubeconfig"
SSH_PRIV_KEY_FILE="$DOWNLOAD_DIR/id_rsa"
SSH_PUB_KEY_FILE="$DOWNLOAD_DIR/id_rsa.pub"
KUBEADMIN_PASS_FILE="$OPENSHIFT_INSTALL_DIR/auth/kubeadmin-password"

CLUSTER_CERT_PREFIX="$DOWNLOAD_DIR/$CLUSTER_NAME-cluster"
CLUSTER_CERT_FILE="$CLUSTER_CERT_PREFIX.crt"
CLUSTER_PRIVATE_KEY_FILE="$CLUSTER_CERT_PREFIX-key.pem"
CLUSTER_FULLCHAIN_FILE="$CLUSTER_CERT_PREFIX-fullchain.crt"

VIRT_CERT_PREFIX="$DOWNLOAD_DIR/$CLUSTER_NAME-virt"
VIRT_CERT_FILE="$VIRT_CERT_PREFIX.crt"
VIRT_PRIVATE_KEY_FILE="$VIRT_CERT_PREFIX-key.pem"
VIRT_FULLCHAIN_FILE="$VIRT_CERT_PREFIX-fullchain.crt"

INSTRUCTOR_CERT_PREFIX="$DOWNLOAD_DIR/$CLUSTER_NAME-instructor"
INSTRUCTOR_CERT_FILE="$INSTRUCTOR_CERT_PREFIX.crt"
INSTRUCTOR_PRIVATE_KEY_FILE="$INSTRUCTOR_CERT_PREFIX-key.pem"
INSTRUCTOR_FULLCHAIN_FILE="$INSTRUCTOR_CERT_PREFIX-fullchain.crt"

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
export AWS_AMIS

export VIRT_CLUSTER_COUNT
export METAL_CLUSTER_COUNT
export INFRA_ENV
export LAB_INFRA_INTERFACE
export LAB_INFRA_IP
export LAB_INFRA_NETWORK
export LAB_WAN_NM_CONN
export METAL_INSTANCE_NIC

export DEFAULT_MAC_ADDRESS
export METAL_MAC_ADDRESSES

export PROJECT_DIR
export DOWNLOAD_DIR
export VENV
export OPENSHIFT_INSTALL_DIR
export ACME_DIR
export ANSIBLE_DIR
export ACME_EMAIL
export ZEROSSL_CREDS_FILE
if [ -f "$ZEROSSL_CREDS_FILE" ]; then
    # shellcheck disable=1090
    source "$ZEROSSL_CREDS_FILE"
fi

export KUBECONFIG
export SSH_PRIV_KEY_FILE
export SSH_PUB_KEY_FILE
if [ -f "$SSH_PUB_KEY_FILE" ]; then
    SSH_PUB_KEY="$(cat "$SSH_PUB_KEY_FILE")"
    export SSH_PUB_KEY
fi
export KUBEADMIN_PASS_FILE
if [ -f "$KUBEADMIN_PASS_FILE" ]; then
    KUBEADMIN_PASS="$(cat "$KUBEADMIN_PASS_FILE")"
    export KUBEADMIN_PASS
fi

export CLUSTER_CERT_PREFIX
export CLUSTER_CERT_FILE
export CLUSTER_PRIVATE_KEY_FILE
export CLUSTER_FULLCHAIN_FILE

export VIRT_CERT_PREFIX
export VIRT_CERT_FILE
export VIRT_PRIVATE_KEY_FILE
export VIRT_FULLCHAIN_FILE

export INSTRUCTOR_CERT_PREFIX
export INSTRUCTOR_CERT_FILE
export INSTRUCTOR_PRIVATE_KEY_FILE
export INSTRUCTOR_FULLCHAIN_FILE

export OPENSHIFT_INSTALL
export OC
export OC_MIRROR

export PIP
export AWS
export ANSIBLE_PLAYBOOK
export ANSIBLE_GALAXY

export INFRA_ENV_LOCS

# Randomly generate a password
if [ -f "$DOWNLOAD_DIR/lab-user-password" ]; then
    LAB_USER_PASSWORD="$(cat "$DOWNLOAD_DIR/lab-user-password")"
else
    LAB_USER_PASSWORD="$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)"
    echo "$LAB_USER_PASSWORD" > "$DOWNLOAD_DIR/lab-user-password"
fi
export LAB_USER_PASSWORD

function set_hosted_zone {
    # Set the hosted zone ID for our expected cluster domain
    HOSTED_ZONE="$("$AWS" route53 list-hosted-zones | jq -r '.HostedZones[] | select(.Name == "'"$BASE_DOMAIN"'.") | .Id' | rev | cut -d/ -f1 | rev)"
    export HOSTED_ZONE
}

function metal_cluster_ip {
    num="$1"
    last_octet="$(( 200 + num ))"
    IFS=. read -r o1 o2 o3 o4 <<< "$LAB_INFRA_NETWORK"
    ip="$o1.$o2.$o3.$last_octet"
    IFS=/ read -r _ cidr <<< "$o4"
    ipcalc -c "$ip/$cidr" || fail Cluster number "$num" puts IP outside of network range
    echo "$ip"
}

if [ ! -f "$HOME/.docker/config.json" ]; then
    mkdir -p "$HOME/.docker"
    cp "$HOME/.pull-secret.json" "$HOME/.docker/config.json"
fi

set -x
