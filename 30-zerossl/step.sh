#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common.sh"
cd "$DOWNLOAD_DIR" || fail Unable to change to the download dir

acme_issue() {
    domains=()
    args=(--dns dns_aws)
    { set +x ; } &>/dev/null
    while [ "${#}" -gt 0 ]; do
        case "$1" in
            --)
                shift
                while [ "${#}" -gt 0 ]; do
                    args+=("$1")
                    shift
                done
                ;;
            -f)
                shift
                args+=(
                    --cert-file "$1.crt"
                    --key-file "$1-key.pem"
                    --fullchain-file "$1-fullchain.crt"
                )
                shift
                ;;
            *)
                domains+=("$1")
                args+=(-d "$1")
                shift
                ;;
        esac
    done
    set -x

    if ( for domain in "${domains[@]}"; do "${acme[@]}" --list | grep -qF "$domain" || exit 1; done; ); then
        "${acme[@]}" --renew-all
        if ! "${acme[@]}" --install-cert "${args[@]}"; then
            "${acme[@]}" --renew "${args[@]}" --force || fail Unable to renew certificate for "${domains[@]}"
        fi
    else
        "${acme[@]}" --issue "${args[@]}" || fail Unable to issue certificate for "${domains[@]}"
    fi
}

if [ -d "$ACME_DIR" ]; then
    pushd acme.sh || fail Unable to change into acme directory
    git pull
    popd || fail Unable to return from the acme directory
else
    git clone https://github.com/acmesh-official/acme.sh
fi

acme=(
    "$ACME_DIR/acme.sh" --home "$ACME_DIR/home"
)

api_endpoint="api.$FULL_CLUSTER_NAME"
router_endpoint="*.apps.$FULL_CLUSTER_NAME"

virt_domain="$CLUSTER_NAME-virt.$BASE_DOMAIN"

"${acme[@]}" --register-account -m "$ACME_EMAIL"
acme_issue "$api_endpoint" "$router_endpoint" -f "$CLUSTER_CERT_PREFIX"
acme_issue "$virt_domain" -f "$VIRT_CERT_PREFIX"
