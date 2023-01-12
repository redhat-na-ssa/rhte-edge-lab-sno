[metal]
${INSTANCE_NAME}.${BASE_DOMAIN}

[metal:vars]
ansible_user = ec2-user
ansible_ssh_private_key_file = "${DOWNLOAD_DIR}/id_rsa"
base_domain = ${BASE_DOMAIN}
cluster_count = ${VIRT_CLUSTER_COUNT}
