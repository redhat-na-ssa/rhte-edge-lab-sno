#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
cd "$SCRIPT_DIR" || fail Unable to cd into the script directory
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common.sh"

for service in https dns dhcp; do
    sudo firewall-cmd --remove-service=$service --permanent
done
sudo firewall-cmd --reload

sudo podman kube down pod.yml
