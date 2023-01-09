#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
cd "$SCRIPT_DIR" || fail Unable to cd into the script directory
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common.sh"

set_hosted_zone

INSTANCE_NAME="$CLUSTER_NAME-virt"
export INSTANCE_NAME

# Randomly generate a password
if [ -f "$DOWNLOAD_DIR/lab-user-password" ]; then
    LAB_USER_PASSWORD="$(cat "$DOWNLOAD_DIR/lab-user-password")"
else
    LAB_USER_PASSWORD="$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)"
    echo "$LAB_USER_PASSWORD" > "$DOWNLOAD_DIR/lab-user-password"
fi
export LAB_USER_PASSWORD

< metal.cf.yaml envsubst \
    '$HOSTED_ZONE $BASE_DOMAIN $INSTANCE_NAME $LAB_USER_PASSWORD $SSH_PUB_KEY' \
    > "$DOWNLOAD_DIR/metal.cf.yaml"
"$AWS" cloudformation deploy \
    --template-file "$DOWNLOAD_DIR/metal.cf.yaml" \
    --stack-name "$CLUSTER_NAME" \
    --region "$AWS_REGION" \
    --no-fail-on-empty-changeset