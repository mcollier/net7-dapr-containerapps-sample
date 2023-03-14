#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

# https://devblogs.microsoft.com/dotnet/announcing-builtin-container-support-for-the-dotnet-sdk/?WT.mc_id=DT-MVP-10160#image-name-and-version
dotnet publish --os linux --arch x64 -p:PublishProfile=DefaultContainer ./source/

docker tag slimy-crawdad:1.0.0 crhvscur5mtnsxq.azurecr.io/collier/net7-dapr-aca-sample:latest

docker push crhvscur5mtnsxq.azurecr.io/collier/net7-dapr-aca-sample:latest

# az containerapp update --name ca-hvscur5mtnsxq -g rg-sample --image crhvscur5mtnsxq.azurecr.io/collier/net7-dapr-aca-sample:latest

# Need to set a new image tag.
az containerapp restart -name ca-hvscur5mtnsxq -g rg-sample