#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
cd "$SCRIPT_DIR" || fail Unable to cd into the script directory
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common.sh"

{ set +x ; } &>/dev/null
PULL_SECRET="$(< ~/.pull-secret.json tr '\n' ' ' | sed 's/\s\+//g')"
set -x
export PULL_SECRET

podman pull quay.io/coreos/coreos-installer:release
function coreos-installer {
    cluster_dir="$1"
    shift
    podman run --privileged --rm \
        -v /dev:/dev \
        -v /run/udev:/run/udev \
        -v "$cluster_dir:/data" \
        -w /data \
        quay.io/coreos/coreos-installer:release "${@}" rhcos-live.iso
}

rhcos_live="$DOWNLOAD_DIR/rhcos-live.iso"
if [ ! -f "$rhcos_live" ]; then
    curl -L "$("$OPENSHIFT_INSTALL" coreos print-stream-json | grep location | grep x86_64 | grep iso | cut -d\" -f4)" -o "$rhcos_live"
fi

for cluster in $(seq "$METAL_CLUSTER_COUNT"); do
    METAL_CLUSTER_NAME="metal$cluster"
    export METAL_CLUSTER_NAME
    cluster_dir="$DOWNLOAD_DIR/$METAL_CLUSTER_NAME"
    if [ -d "$cluster_dir" ]; then
        rm -rf "$cluster_dir"
    fi
    mkdir -p "$cluster_dir"
    METAL_INSTANCE_IP="$(metal_cluster_ip "$cluster")"
    export METAL_INSTANCE_IP
    METAL_INSTANCE_NETMASK="$(ipcalc -m "$LAB_INFRA_NETWORK" --no-decorate)"
    export METAL_INSTANCE_NETMASK
    METAL_DISK="${METAL_DISK_QUIRKS[$METAL_CLUSTER_NAME]:-$DEFAULT_METAL_DISK}"
    export METAL_DISK
    < install-config.yaml.tpl envsubst '$METAL_CLUSTER_NAME $BASE_DOMAIN $METAL_DISK $LAB_INFRA_NETWORK $PULL_SECRET $SSH_PUB_KEY' > "$cluster_dir/install-config.yaml"

    kargs_network="ip=$METAL_INSTANCE_IP::$LAB_INFRA_IP:$METAL_INSTANCE_NETMASK:$METAL_CLUSTER_NAME.$BASE_DOMAIN:$METAL_INSTANCE_NIC:none nameserver=$LAB_INFRA_IP"
    kargs_blacklist="modprobe.blacklist=iwlwifi"
    "$OPENSHIFT_INSTALL" --dir="$cluster_dir" create manifests
    cat << EOF > "$cluster_dir/openshift/99-openshift-machineconfig-master-kargs.yaml"
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: master
  name: 99-openshift-machineconfig-master-kargs
spec:
  kernelArguments:
  - $kargs_blacklist
EOF
    "$OPENSHIFT_INSTALL" --dir="$cluster_dir" create single-node-ignition-config
    metal_iso="$cluster_dir/rhcos-live.iso"
    cp "$rhcos_live" "$metal_iso"
    coreos-installer "$cluster_dir" iso ignition embed -fi bootstrap-in-place-for-live-iso.ign
    coreos-installer "$cluster_dir" iso customize --live-karg-append "$kargs_network"
    coreos-installer "$cluster_dir" iso customize --live-karg-append "$kargs_blacklist"
    coreos-installer "$cluster_dir" iso customize --dest-karg-append "$kargs_blacklist"
done
