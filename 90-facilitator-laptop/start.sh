#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
cd "$SCRIPT_DIR" || fail Unable to cd into the script directory
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common.sh"

changed=false
if [ "$(sudo nmcli c show "$LAB_WAN_NM_CONN" | awk '/^connection\.zone/{print $2}')" != "external" ]; then
    sudo nmcli c mod "$LAB_WAN_NM_CONN" connection.zone external
    changed=true
fi
if ! sudo nmcli c | grep -F rhte; then
    IFS=. read -r _ _ _ o4 <<< "$LAB_INFRA_NETWORK"
    IFS=/ read -r _ cidr <<< "$o4"
    sudo nmcli c add type ethernet con-name rhte ifname "${LAB_INFRA_INTERFACE}" ip4 "$LAB_INFRA_IP/$cidr"
    changed=true
fi
if [ "$(sudo nmcli c show rhte | awk '/^ipv4\.dns/{print $2}')" != "$LAB_INFRA_IP" ]; then
    sudo nmcli c mod rhte ipv4.dns "$LAB_INFRA_IP"
    changed=true
fi
if [ "$(sudo nmcli c show rhte | awk '/^connection\.zone/{print $2}')" != "internal" ]; then
    sudo nmcli c mod rhte connection.zone trusted
    changed=true
fi
if $changed; then
    sudo systemctl restart NetworkManager
fi
sudo nmcli c up rhte

# Labguide setup
rm -rf "$PROJECT_DIR/90-facilitator-laptop/lab/content/"{_data/login.yml,_site,.jekyll-metadata,Gemfile.lock}
< lab/content/_data/login.yml.tpl envsubst '$KUBEADMIN_PASS $LAB_USER_PASSWORD $CLUSTER_NAME $BASE_DOMAIN $INFRA_ENV' > lab/content/_data/login.yml

# Proxy setup
cp "$INSTRUCTOR_FULLCHAIN_FILE" proxy/server.crt
cp "$INSTRUCTOR_PRIVATE_KEY_FILE" proxy/server.key
for tpl in proxy/conf.d/*.tpl; do
    conf="$(echo "$tpl" | rev | cut -d. -f2- | rev)"
    < "$tpl" envsubst '$BASE_DOMAIN' > "$conf"
done

# dnsmasq setup
min_addr="$(ipcalc --minaddr "$LAB_INFRA_NETWORK" --no-decorate)"
max_addr="$(ipcalc --maxaddr "$LAB_INFRA_NETWORK" --no-decorate)"
IFS=. read -r o1 o2 o3 o4 <<< "$min_addr"
start="$o1.$o2.$o3.$(( o4 + 49 ))"
ipcalc -c "$start" || fail Unable to work with simple DHCP range math using network "$LAB_INFRA_NETWORK"
IFS=. read -r o1 o2 o3 o4 <<< "$max_addr"
end="$o1.$o2.$o3.$(( o4 - 55 ))"
ipcalc -c "$end" || fail Unable to work with simple DHCP range math using network "$LAB_INFRA_NETWORK"
DHCP_RANGE="$start,$end,12h"
export DHCP_RANGE
rm -rf dnsmasq/{hosts.d,dnsmasq.conf}
mkdir -p dnsmasq/hosts.d
< dnsmasq/dnsmasq.conf.tpl envsubst '$LAB_INFRA_INTERFACE $LAB_INFRA_IP $BASE_DOMAIN $DHCP_RANGE' > dnsmasq/dnsmasq.conf
for cluster in $(seq "$METAL_CLUSTER_COUNT"); do
    METAL_CLUSTER_NAME="metal$cluster"
    METAL_CLUSTER_IP="$(metal_cluster_ip "$cluster")"
    # DNS setup
    echo "address=/apps.$METAL_CLUSTER_NAME.$BASE_DOMAIN/$METAL_CLUSTER_IP" >> dnsmasq/dnsmasq.conf
    echo "addn-hosts=/etc/hosts.d/$METAL_CLUSTER_NAME" >> dnsmasq/dnsmasq.conf
    echo "$METAL_CLUSTER_IP api.$METAL_CLUSTER_NAME.$BASE_DOMAIN api-int.$METAL_CLUSTER_NAME.$BASE_DOMAIN" > "dnsmasq/hosts.d/metal${cluster}"
done

sudo podman build lab -t rhte-labguide --build-arg BUILD_REVISION="$(git rev-parse HEAD)"
sudo podman build cache -t rhte-cache
sudo podman build proxy -t rhte-proxy
sudo podman build dnsmasq -t rhte-dnsmasq

if ! [ "$(sudo podman volume ls | grep -c 'rhte-sno-\(image\|registry\)-data')" -eq 2 ]; then
    sudo podman play kube pvcs.yml
fi

sudo podman kube play --replace --network=host pod.yml

< "$SCRIPT_DIR/imageset-configuration.tpl" envsubst '$OPENSHIFT_VERSION $BASE_DOMAIN' > "$DOWNLOAD_DIR/imageset-configuration.yml"
cd "$DOWNLOAD_DIR" || fail Unable to change to the download directory
"$OC_MIRROR" --config=imageset-configuration.yml "docker://registry.internal.$BASE_DOMAIN"
