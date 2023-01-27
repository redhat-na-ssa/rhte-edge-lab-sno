#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
cd "$SCRIPT_DIR" || fail Unable to cd into the script directory
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common.sh"

rm -rf "$PROJECT_DIR/90-facilitator-laptop/lab/content/"{_data/login.yml,_data/passwords.yml,_site,.jekyll-metadata,Gemfile.lock}
for cluster in $(seq "$METAL_CLUSTER_COUNT"); do
    name="dev$cluster"
    echo "$name: fakepassword$cluster" >> lab/content/_data/passwords.yml
done
< lab/content/_data/login.yml.tpl envsubst '$KUBEADMIN_PASS $LAB_USER_PASSWORD $CLUSTER_NAME $BASE_DOMAIN $INFRA_ENV' > lab/content/_data/login.yml

podman build lab -t labguide:dev -f Containerfile.dev --build-arg BUILD_REVISION="$(git rev-parse HEAD)"
podman run --rm -itp 8080:8080 -v ./lab/content:/app --security-opt=label=disable --privileged labguide:dev
