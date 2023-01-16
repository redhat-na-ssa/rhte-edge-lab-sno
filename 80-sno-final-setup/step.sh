#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
cd "$SCRIPT_DIR" || fail Unable to cd into the script directory
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common.sh"

openshift_version_z="$(awk '/^Name:/{print $2}' "$DOWNLOAD_DIR/release.txt")"
export openshift_version_z

< clusterimageset.tpl envsubst '$openshift_version_z' > "$DOWNLOAD_DIR/clusterimageset.yml"
"$OC" apply -f "$DOWNLOAD_DIR/clusterimageset.yml"

iso_files='isos:
'
for env in "${!INFRA_ENV_LOCS[@]}"; do
    iso_files+="- name: ${env}
  url: '$("$OC" get infraenv -n $env $env -ojsonpath='{.status.isoDownloadURL}')'
"
done

cd "$ANSIBLE_DIR" || fail Unable to change into the ansible directory
echo "$iso_files" > "$ANSIBLE_DIR/inventory/group_vars/metal/isos.yml"

"$ANSIBLE_PLAYBOOK" haproxy.yml
"$ANSIBLE_PLAYBOOK" hypervisor.yml

# need to add argocd deployment
# consider Skupper deployment
# app:
# https://www.youtube.com/watch?v=FOelk2m8r0o
# https://github.com/redhat-developer-demos/quinoa-wind-turbine-manifests
# https://github.com/redhat-developer-demos/quinoa-wind-turbine
# https://docs.google.com/document/d/1eRde9o62sb7e3wHKt2ra8W6tvnBBKGYAxmiE_pV-XM4/edit#
# https://github.com/stefan-bergstein/quinoa-wind-turbine-manifests
# https://github.com/stefan-bergstein/quinoa-wind-turbine
