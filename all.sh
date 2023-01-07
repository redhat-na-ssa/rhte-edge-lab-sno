#!/bin/bash

set -e

steps=(
    00-validate
    10-environment-prep
    20-dns-setup
    30-zerossl
    40-cloud-ocp-install
    50-acm-hub-setup
    60-infra-env-setup
)

for step in "${steps[@]}"; do
    "$step/step.sh"
done
