#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common.sh"
cd "$PROJECT_DIR" || fail Unable to cd into the project directory

function set_hosted_zone {
    # Set the hosted zone ID for our expected cluster domain
    hosted_zone="$("$AWS" route53 list-hosted-zones | jq -r '.HostedZones[] | select(.Name == "'"$BASE_DOMAIN"'.") | .Id' | rev | cut -d/ -f1 | rev)"
}

function validate_subdomain_delegation {
    # Ensure that the edgelab.dev AWS account has the subdomain delegated
    hosted_zone_nameservers="$("$AWS" route53 get-hosted-zone --id "$hosted_zone" | jq -r '.DelegationSet.NameServers[]')"
    export hosted_zone_nameservers
    (
        set -eux
        function generate_resource_record_set {
            action="${1}"
            record="${2}"
            echo -n '{
                "HostedZoneId": "Z0870591EV5SVIJ5YVFG",
                "ChangeBatch": {
                    "Comment": "Update '"$record"' with new nameservers",
                    "Changes": [
                        {
                            "Action": "'"$action"'",
                            "ResourceRecordSet": {
                                "Name": "'"$record"'.",
                                "Type": "NS",
                                "TTL": 300,
                                "ResourceRecords": [
'
            # To be clear, I hate this. I should have written this in Python.
            for nameserver in $hosted_zone_nameservers; do
                echo '              {
                                        "Value": "'"$nameserver"'"
                                    },'
            done | head -n -1; echo '}'
            echo '
                                ]
                            }
                        }
                    ]
                }
            }'
        }

        # We need the edgelab AWS credentials in this subshell
        { set +x ; } &>/dev/null
        # shellcheck disable=SC1090
        source ~/.edgelab.aws
        set -x

        record_set="$("$AWS" route53 list-resource-record-sets --hosted-zone-id Z0870591EV5SVIJ5YVFG | jq '.ResourceRecordSets[] | .Name')"
        if echo "$record_set" | grep -qF "$BASE_DOMAIN."; then
            # The record exists and we must make sure it's valid
            record="$("$AWS" route53 list-resource-record-sets --hosted-zone-id Z0870591EV5SVIJ5YVFG | jq -r '.ResourceRecordSets[] | select(.Name == "'"$BASE_DOMAIN"'.")')"
            record_type="$(echo "$record" | jq -r '.Type')"
            record_values="$(echo "$record" | jq -r '.ResourceRecords[] | .Value')"
            if [ "$record_type" != "NS" ] || [ "$record_values" != "$hosted_zone_nameservers" ]; then
                # It doesn't match
                "$AWS" route53 change-resource-record-sets --cli-input-json "$(generate_resource_record_set UPSERT "$BASE_DOMAIN")"
            fi
        else
            # The record doesn't exist and it must be created
            "$AWS" route53 change-resource-record-sets --cli-input-json "$(generate_resource_record_set CREATE "$BASE_DOMAIN")"
        fi
    )
}

set_hosted_zone
if [ -z "$hosted_zone" ]; then
    "$AWS" route53 create-hosted-zone --name "$BASE_DOMAIN" --caller-reference "$(date +'%s')"
    set_hosted_zone
fi

validate_subdomain_delegation
