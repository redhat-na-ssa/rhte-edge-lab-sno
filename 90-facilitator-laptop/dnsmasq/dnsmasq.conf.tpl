interface=${LAB_INFRA_INTERFACE}
listen-address=${LAB_INFRA_IP}
bind-interfaces

port=53

local=/local.${BASE_DOMAIN}/
domain=local.${BASE_DOMAIN}
no-hosts

address=/internal.${BASE_DOMAIN}/${LAB_INFRA_IP}

dhcp-option=3,${LAB_INFRA_IP}
dhcp-option=6,${LAB_INFRA_IP}
dhcp-range=${DHCP_RANGE}

