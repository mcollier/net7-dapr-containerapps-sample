#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

LOCATION=northcentralus
RESOURCE_GROUP=rg-mcdot7dapraca02-northcentralus
REGISTRY_NAME=crdycgupzlntjfg
CONTAINER_ENV_NAME=cae-dycgupzlntjfg
MANAGED_IDENTITY_NAME=id-dycgupzlntjfg
# DEPLOYMENT_NAME="deploy-$(date +%Y%m%d_%H%m%s%N)"
IMAGE_TAG=1.0.1

# Build the app
pushd ./source/signal-receiver
dotnet publish --os linux --arch x64 -p:PublishProfile=DefaultContainer -c Release

popd

# Push image to ACR
docker tag signal-receiver:1.0.0 $REGISTRY_NAME.azurecr.io/signal-receiver:$IMAGE_TAG
docker push $REGISTRY_NAME.azurecr.io/signal-receiver:$IMAGE_TAG

# Update Azure Container App
az containerapp update \
    --name signal-receiver \
    --resource-group $RESOURCE_GROUP \
    --image $REGISTRY_NAME.azurecr.io/signal-receiver:$IMAGE_TAG