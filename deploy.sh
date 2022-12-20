#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

LOCATION=eastus
DEPLOYMENT_NAME="deploy-$(date +%Y%m%d_%H%m%s%N)"

# az deployment sub create \
#     --name "$DEPLOYMENT_NAME" \
#     --location "$LOCATION" \
#     --template-file ./infra/main.bicep \
#     --parameters name=mcdot7dapraca1 location=eastus



outputs=$(az deployment sub create --name "$DEPLOYMENT_NAME" --location eastus --template-file ./infra/main.bicep  --parameters name=mcdot7dapraca1 location=eastus)

echo "Capturing outputs . . ."
echo $outputs | jq -c '.properties.outputs | to_entries[] | [.key, .value.value]' |
    while IFS=$"\n" read -r c; do
        outputname=$(echo "$c" | jq -r '.[0]')
        outputvalue=$(echo "$c" | jq -r '.[1]')
        echo "##vso[task.setvariable variable=$outputname;isOutput=true]$outputvalue"
    done