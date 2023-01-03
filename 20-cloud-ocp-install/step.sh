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

if [ ! -f "$PROJECT_DIR/tmp/$openshift_install_tarball" ]; then
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
    mv "$openshift_install_tarball" "$PROJECT_DIR/tmp"
fi

cd "$PROJECT_DIR/tmp" || fail Unable to change into the download directory

# Ensure downloaded and unpacked
if [ ! -x openshift-install ] || [ "$(./openshift-install version | head -1 | cut -d' ' -f2)" != "$openshift_version_z" ]; then
    tar xvzf "$openshift_install_tarball"
    chmod +x openshift-install
fi
./openshift-install version

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

if [ ! -f install/auth/kubeconfig ]; then
    if [ -d install ]; then
        mv install "install-$(date --iso-8601=seconds)"
    fi
    mkdir install
    cd install || fail Unable to change to install directory
    < "$SCRIPT_DIR/install-config.tpl" envsubst '$BASE_DOMAIN $CLUSTER_NAME $AWS_REGION $SSH_PUB_KEY $PULL_SECRET' > install-config.yaml
    ../openshift-install create cluster
fi
