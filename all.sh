#!/bin/bash

set -e

steps=(
    00-validate
    10-environment-prep
    20-cloud-ocp-install
    30-acm-hub-setup
    40-local-mirror-setup
)

for step in "${steps[@]}"; do
    "$step/step.sh"
done
