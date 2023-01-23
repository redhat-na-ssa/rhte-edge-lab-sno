#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
cd "$SCRIPT_DIR" || fail Unable to cd into the script directory
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common.sh"

for service in https dns dhcp; do
    sudo firewall-cmd --add-service=$service --permanent
done
sudo firewall-cmd --reload

rm -rf "$PROJECT_DIR/90-facilitator-laptop/lab/content/"{_data/login.yml,_site,.jekyll-metadata,Gemfile.lock}
< lab/content/_data/login.yml.tpl envsubst '$KUBEADMIN_PASS $LAB_USER_PASSWORD $CLUSTER_NAME $BASE_DOMAIN $INFRA_ENV' > lab/content/_data/login.yml

cp "$INSTRUCTOR_FULLCHAIN_FILE" proxy/server.crt
cp "$INSTRUCTOR_PRIVATE_KEY_FILE" proxy/server.key

rm -rf dnsmasq/{hosts.d,dnsmasq.conf}
mkdir -p dnsmasq/hosts.d
< dnsmasq/dnsmasq.conf.tpl envsubst '$LAB_INFRA_INTERFACE $LAB_INFRA_IP' > dnsmasq/dnsmasq.conf
for cluster in $(seq 15); do
    echo "address=/apps.metal${cluster}.rhte.edgelab.dev/192.168.99.$(( 200 + cluster ))" >> dnsmasq/dnsmasq.conf
    echo "addn-hosts=/etc/hosts.d/metal${cluster}" >> dnsmasq/dnsmasq.conf
    echo "192.168.99.$(( 200 + cluster )) api.metal${cluster}.rhte.edgelab.dev api-int.metal${cluster}.rhte.edgelab.dev" > "dnsmasq/hosts.d/metal${cluster}"
done

sudo podman build lab -t rhte-labguide --build-arg BUILD_REVISION="$(git rev-parse HEAD)"
sudo podman build cache -t rhte-cache
sudo podman build proxy -t rhte-proxy
sudo podman build dnsmasq -t rhte-dnsmasq

if ! [ "$(sudo podman volume ls | grep -c 'rhte-sno-\(image\|registry\)-data')" -eq 2 ]; then
    sudo podman play kube pvcs.yml
fi

sudo podman kube play --replace --network=host pod.yml
