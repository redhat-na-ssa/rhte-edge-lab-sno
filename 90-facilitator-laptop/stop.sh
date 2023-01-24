#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
cd "$SCRIPT_DIR" || fail Unable to cd into the script directory
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common.sh"

changed=false
if [ "$(sudo nmcli c show "$LAB_WAN_NM_CONN" | awk '/^connection\.zone/{print $2}')" != "--" ]; then
    sudo nmcli c mod "$LAB_WAN_NM_CONN" connection.zone ""
    changed=true
fi
if sudo nmcli c | grep -F rhte; then
    sudo nmcli c down rhte
    sudo nmcli c del rhte
    changed=true
fi
if $changed; then
    sudo systemctl restart NetworkManager
fi
for service in https dns dhcp; do
    sudo firewall-cmd --remove-service=$service --permanent --zone=internal
done
sudo firewall-cmd --reload

sudo podman kube down pod.yml ||:
