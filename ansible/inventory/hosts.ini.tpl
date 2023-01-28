[all:vars]
download_dir = "${DOWNLOAD_DIR}"
base_domain = ${BASE_DOMAIN}
aws_region = ${AWS_REGION}
infra_env = ${INFRA_ENV}

[metal]
${INSTANCE_NAME}.${BASE_DOMAIN}

[metal:vars]
ansible_user = ec2-user
ansible_ssh_private_key_file = "{{ download_dir }}/id_rsa"
cluster_count = ${VIRT_CLUSTER_COUNT}

[hub]
127.0.0.1

[hub:vars]
ansible_connection = local
ansible_python_interpreter = "{{ download_dir }}/../venv/bin/python"
kubeconfig = "{{ download_dir }}/install/auth/kubeconfig"
acme_email = "${ACME_EMAIL}"
zerossl_kid = "${ZEROSSL_KID}"
zerossl_hmac = "${ZEROSSL_HMAC}"
