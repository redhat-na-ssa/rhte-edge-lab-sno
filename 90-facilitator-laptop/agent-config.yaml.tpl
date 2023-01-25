apiVersion: v1alpha1
kind: AgentConfig
metadata:
  name: ${METAL_CLUSTER_NAME}
rendezvousIP: ${METAL_INSTANCE_IP}
hosts:
  - hostname: ${METAL_NODE_NAME}
    role: master
    rootDeviceHints:
      minSizeGigabytes: 100
    interfaces:
      - name: ${METAL_INSTANCE_NIC}
        macAddress: ${METAL_INSTANCE_MAC}
    networkConfig:
      interfaces:
        - name: ${METAL_INSTANCE_NIC}
          type: ethernet
          state: up
          mac-address: ${METAL_INSTANCE_MAC}
          ipv4:
            enabled: true
            address:
              - ip: ${METAL_INSTANCE_IP}
                prefix-length: ${METAL_INSTANCE_CIDR}
            dhcp: false
      dns-resolver:
        config:
          server:
            - ${LAB_INFRA_IP}
      routes:
        config:
          - destination: 0.0.0.0/0
            next-hop-address: ${LAB_INFRA_IP}
            next-hop-interface: ${METAL_INSTANCE_NIC}
            table-id: 254
