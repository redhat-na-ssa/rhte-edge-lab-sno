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
    METAL_NODE_NAME="node$cluster"
    export METAL_NODE_NAME
    cluster_dir="$DOWNLOAD_DIR/$METAL_CLUSTER_NAME"
    if [ -d "$cluster_dir" ]; then
        rm -rf "$cluster_dir"
    fi
    mkdir -p "$cluster_dir"
    METAL_INSTANCE_IP="$(metal_cluster_ip "$cluster")"
    export METAL_INSTANCE_IP
    METAL_INSTANCE_CIDR="$(ipcalc -p "$LAB_INFRA_NETWORK" --no-decorate)"
    export METAL_INSTANCE_CIDR
    METAL_INSTANCE_MAC="${METAL_MAC_ADDRESSES[$METAL_CLUSTER_NAME]:-$DEFAULT_MAC_ADDRESS}"
    export METAL_INSTANCE_MAC
    < install-config.yaml.tpl envsubst '$METAL_CLUSTER_NAME $BASE_DOMAIN $LAB_INFRA_NETWORK $PULL_SECRET $SSH_PUB_KEY' > "$cluster_dir/install-config.yaml"
    < agent.config.yaml.tpl envsubst '$METAL_CLUSTER_NAME $METAL_NODE_NAME $METAL_INSTANCE_NIC $METAL_INSTANCE_IP $METAL_INSTANCE_CIDR $LAB_INFRA_IP $METAL_INSTANCE_MAC' > "$cluster_dir/agent.config.yaml.tpl"

    "$metal_install" agent create image --dir="$cluster_dir"
done
