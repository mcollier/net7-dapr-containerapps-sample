#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

LOCATION=northcentralus
RESOURCE_GROUP=rg-mcdot7dapraca02-northcentralus
REGISTRY_NAME=crdycgupzlntjfg
CONTAINER_ENV_NAME=cae-dycgupzlntjfg
MANAGED_IDENTITY_NAME=id-dycgupzlntjfg
DEPLOYMENT_NAME="deploy-$(date +%Y%m%d_%H%m%s%N)"
EVENT_HUB_NAMESPACE=evhns-dycgupzlntjfg
EVENT_HUB=sensors
STORAGE_ACCOUNT_NAME=stdycgupzlntjfg
IMAGE_TAG=1.0.0

# Build the app
pushd ./source/signal-receiver

# Create the container - .NET 7 feature (publish as container - https://learn.microsoft.com/dotnet/core/docker/publish-as-container)
dotnet publish --os linux --arch x64 -p:PublishProfile=DefaultContainer -c Release

popd

# Push image to ACR
docker tag signal-receiver:1.0.0 $REGISTRY_NAME.azurecr.io/signal-receiver:$IMAGE_TAG
docker push $REGISTRY_NAME.azurecr.io/signal-receiver:$IMAGE_TAG

az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --name $DEPLOYMENT_NAME \
    --template-file ./infra/signal-receiver-app.bicep \
    --parameters \
        containerRegistryName=$REGISTRY_NAME \
        imageTag=$IMAGE_TAG \
        applicationName=signal-receiver \
        containerAppEnvironmentName=$CONTAINER_ENV_NAME \
        managedIdentityName=$MANAGED_IDENTITY_NAME \
        eventHubNamespace=$EVENT_HUB_NAMESPACE \
        eventHub=$EVENT_HUB \
        storageName=$STORAGE_ACCOUNT_NAME
