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

# We need a temporary directory that gets cleaned up
tmp_dir="$(mktemp -d)"
cd "$tmp_dir" || fail Unable to create temporary directory

# Download  things we'll need to check the version
curl -LO "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$OPENSHIFT_VERSION/release.txt"

openshift_version_z="$(awk '/^Name:/{print $2}' release.txt)"
openshift_install_tarball="openshift-install-linux-${openshift_version_z}.tar.gz"

if [ ! -f "$PROJECT_DIR/downloads/$openshift_install_tarball" ]; then
    # We need to validate the GPG signature on the checksums of the downloads
    curl -Lo rh_key.txt https://www.redhat.com/security/fd431d51.txt
    if ! gpg --list-keys |& grep -qF security@redhat.com; then
        gpg --import rh_key.txt || fail Unable to import GPG key
    fi
    if ! gpg --list-keys |& grep -q 'ultimate.*security@redhat\.com'; then
        trust_key || fail Unable to establish key trust for Red Hat Security
    fi
    curl -LO "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$OPENSHIFT_VERSION/sha256sum.txt"
    curl -LO "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$OPENSHIFT_VERSION/sha256sum.txt.gpg"
    sig_verification="$(gpg --verify sha256sum.txt.gpg 2>&1)"
    echo "$sig_verification" | grep -qF 'Good signature from "Red Hat' || fail Unable to validate the signature on the checksums

    # Download the installer
    curl -LO "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$OPENSHIFT_VERSION/$openshift_install_tarball"
    grep -F "$openshift_install_tarball" sha256sum.txt | sha256sum -c -
    mv "$openshift_install_tarball" "$PROJECT_DIR/downloads"
fi

cd "$PROJECT_DIR/downloads" || fail Unable to change into the download directory

if [ ! -x openshift-install ]; then
    tar xvzf "$openshift_install_tarball"
    chmod +x openshift-install
fi

if [ ! -f install/auth/kubeconfig ]; then
    mkdir -p install
    cd install || fail Unable to change to install directory
    cp "$SCRIPT_DIR/install-config.yaml" ./
    ../openshift-install create cluster
fi
