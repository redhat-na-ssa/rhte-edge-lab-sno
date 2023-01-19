#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

all=false

while (( ${#} >0 )); do
    case "$1" in
        --all)
            all=true
            ;;
        *)
            fail Unknown arg, "$1"
            ;;
    esac; shift
done

if [ -d "$DOWNLOAD_DIR/install" ]; then
    "$OPENSHIFT_INSTALL" destroy cluster --dir "$DOWNLOAD_DIR/install"
    rm -rf "$DOWNLOAD_DIR/install"
fi

if [ -f "$DOWNLOAD_DIR/metal.cf.yaml" ]; then
    "$AWS" cloudformation delete-stack --stack-name "$CLUSTER_NAME" --region "$AWS_REGION"
    rm -f "$DOWNLOAD_DIR/metal.cf.yaml"
fi

if $all; then
    find "$DOWNLOAD_DIR" -mindepth 1 -maxdepth 1 ! -name '.gitkeep' -exec rm -rf {} \;
    find "$ANSIBLE_DIR/collections" -mindepth 1 -maxdepth 1 ! -name '.gitkeep' ! -name '.gitignore' -exec rm -rf {} \;
    rm -rf "$ANSIBLE_DIR/inventory/"{hosts.ini,group_vars/metal/isos.yml}
    rm -rf "$PROJECT_DIR/90-lab-guides/content/"{_data/login.yml,_site,.jekyll-metadata,Gemfile.lock}
    rm -rf venv
fi
