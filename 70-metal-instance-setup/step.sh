#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
cd "$SCRIPT_DIR" || fail Unable to cd into the script directory
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common.sh"

set_hosted_zone

INSTANCE_NAME="$CLUSTER_NAME-virt"
export INSTANCE_NAME

COCKPIT_CERT="$(base64 -w0 "$VIRT_FULLCHAIN_FILE")"
COCKPIT_KEY="$(base64 -w0 "$VIRT_PRIVATE_KEY_FILE")"
export COCKPIT_CERT
export COCKPIT_KEY

if [ "$VIRT_CLUSTER_COUNT" -gt 20 ] || [ "$AWS_REGION" = sa-east-1 ]; then
    instance_type=r5d.metal
else
    instance_type=z1d.metal
fi

< metal.cf.yaml envsubst \
    '$HOSTED_ZONE $BASE_DOMAIN $INSTANCE_NAME $LAB_USER_PASSWORD $SSH_PUB_KEY $COCKPIT_CERT $COCKPIT_KEY' \
    > "$DOWNLOAD_DIR/metal.cf.yaml"
"$AWS" cloudformation deploy \
    --template-file "$DOWNLOAD_DIR/metal.cf.yaml" \
    --stack-name "$CLUSTER_NAME" \
    --region "$AWS_REGION" \
    --no-fail-on-empty-changeset \
    --parameter-overrides \
    "AmiId=${AWS_AMIS[$AWS_REGION]}" \
    "InstanceType=$instance_type"

instance_up=(
    ssh
    -o identitiesonly=yes
    -o stricthostkeychecking=no
    -o userknownhostsfile=/dev/null
    -i "$DOWNLOAD_DIR/id_rsa"
    ec2-user@"$INSTANCE_NAME.$BASE_DOMAIN"
    whoami
)
while ! "${instance_up[@]}" &>/dev/null; do
    sleep 5;
done
cd "$ANSIBLE_DIR" || fail Unable to change into the ansible directory
< "$ANSIBLE_DIR/inventory/hosts.ini.tpl" envsubst '$INSTANCE_NAME $BASE_DOMAIN $DOWNLOAD_DIR $VIRT_CLUSTER_COUNT $METAL_CLUSTER_COUNT $INFRA_ENV $ACME_EMAIL $AWS_REGION $ZEROSSL_KID $ZEROSSL_HMAC' > "$ANSIBLE_DIR/inventory/hosts.ini"
