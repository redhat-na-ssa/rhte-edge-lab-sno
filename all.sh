#!/bin/bash

set -e

steps=(
    00-validate
    10-environment-prep
    20-cloud-ocp-install
)

for step in "${steps[@]}"; do
    "$step/step.sh"
done
