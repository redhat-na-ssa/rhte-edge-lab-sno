#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
cd "$SCRIPT_DIR" || fail Unable to cd into the script directory
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common.sh"

rm -rf "$PROJECT_DIR/90-facilitator-laptop/lab/content/"{_data/login.yml,_config.yml,_data/passwords.yml,_site,.jekyll-metadata,Gemfile.lock}
for cluster in $(seq "$METAL_CLUSTER_COUNT"); do
    name="metal$cluster"
    echo "$name: fakepassword$cluster" >> lab/content/_data/passwords.yml
done
METAL_CLUSTER_STR="$(seq "$METAL_CLUSTER_COUNT")"
export METAL_CLUSTER_STR
VIRT_CLUSTER_STR="$(seq "$VIRT_CLUSTER_COUNT")"
export VIRT_CLUSTER_STR
< lab/content/_data/login.yml.tpl envsubst '$KUBEADMIN_PASS $LAB_USER_PASSWORD $CLUSTER_NAME $BASE_DOMAIN $INFRA_ENV $METAL_CLUSTER_COUNT $METAL_CLUSTER_STR $VIRT_CLUSTER_COUNT $VIRT_CLUSTER_STR' > lab/content/_data/login.yml
< lab/content/_config.yml.tpl envsubst '$BASE_DOMAIN' > lab/content/_config.yml

podman build lab -t labguide:dev -f Containerfile.dev --build-arg BUILD_REVISION="$(git rev-parse HEAD)"
podman run --rm -itp 8080:8080 -v ./lab/content:/app --security-opt=label=disable --privileged labguide:dev
