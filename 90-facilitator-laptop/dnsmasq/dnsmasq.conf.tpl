interface=${LAB_INFRA_INTERFACE}
listen-address=${LAB_INFRA_IP}

port=53

local=/local.rhte.edgelab.dev/
domain=local.rhte.edgelab.dev
no-hosts

address=/internal.rhte.edgelab.dev/${LAB_INFRA_IP}

# Route through me
dhcp-option=3,${LAB_INFRA_IP}
# I am DNS
dhcp-option=6,${LAB_INFRA_IP}
dhcp-range=192.168.99.50,192.168.99.199,12h
