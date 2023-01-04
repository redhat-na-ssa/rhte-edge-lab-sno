#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
cd "$SCRIPT_DIR" || fail Unable to change into script directory
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common.sh"

trust_key() {
    # Marks a GPG key for ultimate trust
    echo -e '5\ny\n' | gpg --command-fd 0 --edit-key security@redhat.com trust || return 1
    gpg --update-trustdb || return 2
}

raw_download() {
    if [ ! -f "$1" ]; then
        curl -LO "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$OPENSHIFT_VERSION/$1"
    fi
}

download_is_valid() {
    grep -F "$1" "$DOWNLOAD_DIR/sha256sum.txt" | sha256sum -c || return 1
}

download() {
    if [ ! -f "$1" ] || ! download_is_valid "$1"; then
        pushd "$tmp_dir" || fail Unable to cd into the temp directory
        raw_download "$1"
        download_is_valid "$1"
        popd || fail Unable to return from temp directory
        mv "$tmp_dir/$1" ./
    fi
}

# We need a temporary directory that gets cleaned up
tmp_dir="$(mktemp -d)"
cd "$DOWNLOAD_DIR" || fail Unable to change into the download directory

# Download  things we'll need to check the version
raw_download release.txt

openshift_version_z="$(awk '/^Name:/{print $2}' release.txt)"
openshift_install_tarball="openshift-install-linux-${openshift_version_z}.tar.gz"
oc_tarball="openshift-client-linux-${openshift_version_z}.tar.gz"

# We need to validate the GPG signature on the checksums of the downloads
if [ ! -f rh_key.txt ]; then
    curl -Lo rh_key.txt https://www.redhat.com/security/fd431d51.txt
fi
if ! gpg --list-keys |& grep -qF security@redhat.com; then
    gpg --import rh_key.txt || fail Unable to import GPG key
fi
if ! gpg --list-keys |& grep -q 'ultimate.*security@redhat\.com'; then
    trust_key || fail Unable to establish key trust for Red Hat Security
fi
raw_download sha256sum.txt
raw_download sha256sum.txt.gpg
if ! gpg --verify sha256sum.txt.gpg |& grep -qF 'Good signature from "Red Hat'; then
    rm -rf sha256sum.txt{,.gpg}
    fail Unable to validate the signature on the checksums
fi

# Ensure installer and cli are downloaded and unpacked
download "$openshift_install_tarball"
download "$oc_tarball"
if [ ! -x "$OPENSHIFT_INSTALL" ] || [ "$("$OPENSHIFT_INSTALL" version | head -1 | cut -d' ' -f2)" != "$openshift_version_z" ]; then
    tar xvzf "$openshift_install_tarball"
    chmod +x "$OPENSHIFT_INSTALL"
fi
"$OPENSHIFT_INSTALL" version
if [ ! -x "$OC" ] || [ "$("$OC" version --client | head -1 | cut -d' ' -f3)" != "$openshift_version_z" ]; then
    tar xvzf "$oc_tarball"
    chmod +x "$OC"
fi
"$OC" version --client

# Ensure that SSH keys are generated
if [ ! -f id_rsa ] || [ ! -f id_rsa.pub ]; then
    ssh-keygen -t rsa -b 4096 -C 'admin@edgelab.dev' -N '' -f ./id_rsa
fi
SSH_PUB_KEY="$(cat id_rsa.pub)"
export SSH_PUB_KEY

# Grab and format our pull secret
{ set +x ; } &>/dev/null
PULL_SECRET="$(< ~/.pull-secret.json tr '\n' ' ' | sed 's/\s\+//g')"
set -x
export PULL_SECRET

if [ ! -f "$KUBECONFIG" ]; then
    if [ -d install ]; then
        mv install "install-$(date --iso-8601=seconds)"
    fi
    mkdir install
    cd install || fail Unable to change to install directory
    < "$SCRIPT_DIR/install-config.tpl" envsubst '$BASE_DOMAIN $CLUSTER_NAME $AWS_REGION $SSH_PUB_KEY $PULL_SECRET' > install-config.yaml
    "$OPENSHIFT_INSTALL" create cluster
    cd .. || fail Unable to return from the install directory
fi

"$OC" whoami --show-server
"$OC" whoami
