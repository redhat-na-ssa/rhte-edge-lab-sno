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

last_mirrored_results="$(find "$DOWNLOAD_DIR"/oc-mirror-workspace -mindepth 1 -maxdepth 1 -type d -name 'results*' | sort | tail -1)"
last_mirrored_version="$(head -1 "$last_mirrored_results/mapping.txt" | grep -o 'release:[^-]*' | cut -d: -f2)"
metal_download_dir="$DOWNLOAD_DIR/$last_mirrored_version"
mkdir -p "$metal_download_dir"

release_image="registry.internal.$BASE_DOMAIN/mirror/openshift/release-images:$last_mirrored_version-x86_64"
metal_oc="$metal_download_dir/oc"
metal_install="$metal_download_dir/openshift-install"
rhcos_live="$metal_download_dir/rhcos-live.iso"

if [ ! -f "$metal_oc" ]; then
    pushd "$metal_download_dir" || fail Unable to change to the metal client download dir
    "$OC" adm release extract --command=oc "$release_image"
    popd || fail Unable to return from the metal client download dir
fi
if [ ! -f "$metal_install" ]; then
    pushd "$metal_download_dir" || fail Unable to change to the metal client download dir
    "$OC" adm release extract --command=openshift-install "$release_image"
    popd || fail Unable to return from the metal client download dir
fi

rhcos_iso_json="$("$metal_install" coreos print-stream-json | jq .architectures.x86_64.artifacts.metal.formats.iso)"
rhcos_iso_src="$(echo "$rhcos_iso_json" | jq -r .disk.location)"
rhcos_iso_sha256="$(echo "$rhcos_iso_json" | jq -r .disk.sha256)"
if ! echo "$rhcos_iso_sha256  $rhcos_live" | sha256sum -c; then
    rm -f "$rhcos_live"
    curl -Lo "$rhcos_live" "$rhcos_iso_src"
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
    "$metal_install" --dir="$cluster_dir" create manifests
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
    "$metal_install" --dir="$cluster_dir" create single-node-ignition-config
    metal_iso="$cluster_dir/rhcos-live.iso"
    cp "$rhcos_live" "$metal_iso"
    coreos-installer "$cluster_dir" iso customize -f --live-karg-append "$kargs_network $kargs_blacklist" --dest-karg-append "$kargs_blacklist"
    coreos-installer "$cluster_dir" iso ignition embed -fi bootstrap-in-place-for-live-iso.ign
done
