apiVersion: v1
baseDomain: ${BASE_DOMAIN}
compute:
- name: worker
  replicas: 0 
controlPlane:
  name: master
  replicas: 1 
metadata:
  name: ${METAL_CLUSTER_NAME}
networking: 
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  machineNetwork:
  - cidr: "${LAB_INFRA_NETWORK}"
  networkType: OVNKubernetes
  serviceNetwork:
  - 172.30.0.0/16
platform:
  none: {}
bootstrapInPlace:
  installationDisk: ${METAL_DISK}
pullSecret: '${PULL_SECRET}'
sshKey: |
  ${SSH_PUB_KEY}
