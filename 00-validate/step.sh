#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
cd "$SCRIPT_DIR" || fail Unable to change into script directory
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common.sh"

{ set +x ; } &>/dev/null
# Make sure our expected AWS environment variables are set
if [ -z "${AWS_ACCESS_KEY_ID:-}" ] || [ -z "${AWS_SECRET_ACCESS_KEY:-}" ]; then
    fail You must set and export AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY from your RHPDS Open Environment
fi
# Make sure we've got the edgelab.dev creds set up
if [ ! -f ~/.edgelab.aws ]; then
    fail You must set AWS keys to manage edgelab.dev in ~/.edgelab.aws
fi
# Make sure we've got a pull secret staged
if [ ! -f ~/.pull-secret.json ]; then
    fail You must place a valid Red Hat pull secret in ~/.pull-secret.json
fi
if [ ! -f ~/.zerossl ] || [ -z "$ZEROSSL_KID" ] || [ -z "$ZEROSSL_HMAC" ]; then
    fail You must have the ZEROSSL_KID and ZEROSSL_HMAC variables exported in ~/.zerossl for the "$ACME_EMAIL" account
fi

# Make sure we've got the binaries we need in the environment
needed_bins=(
    python3
    jq
    gpg
    awk
    curl
    tar
    grep
    ssh-keygen
    envsubst
    podman
    ipcalc
    nmstatectl
)
lacking_bins=()

for bin in "${needed_bins[@]}"; do
    command -v "$bin" &>/dev/null || lacking_bins+=("$bin")
done
if [ "${#lacking_bins[@]}" -ne 0 ]; then
    # shellcheck disable=SC2016
    fail Unable to continue without the following binaries in your '$PATH': "${lacking_bins[@]}"
fi

# Make sure we've got venv in the python stdlib
python3 -m venv --help &>/dev/null || fail Unable to continue without the venv module in the Python stdlib

# Make sure our DNS resolves correctly
hostname_ip="$(dig -4 +short "${HOSTNAME}")" || fail Unable to resolve hostname: "$HOSTNAME"
ip addr | grep -qF "inet $hostname_ip" || fail Unable to identify IP address for "$HOSTNAME" on interfaces

# Make sure we can sudo
sudo whoami | grep -qF root || fail Unable to verify sudo access

echo "Environment validation complete."
set -x
