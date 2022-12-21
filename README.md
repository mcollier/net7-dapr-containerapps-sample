# .NET 7, Dapr, and Azure Container Apps Sample

:construction:This project is under development.:construction:
This is a bit messy at the moment.  :(

## Getting Started

### Run locally

#### Signal Generator

This is a .NET Console application.

1. Move to the ./source/signal-generator directory.
1. Set the connection string to the Event Hub as a user secret.
1. Run the application
    ```bash
    dotnet run
    ```

#### Signal Receiver

1. Move to the ./source/signal-receiver directory.
1. Run the app
    ```bash
    dapr run --app-id signal-receiver --components-path ../components/ --app-port 5000 --log-level info -- dotnet run .
    ```
1. Build the container
    ```bash
    dotnet publish --os linux --arch x64 -p:PublishProfile=DefaultContainer -c Release
    ```
1. Tag
    ```bash
    docker tag signal-receiver:1.0.0 crcp2brzfgohm3o.azurecr.io/sample/signal-receiver:1.0.0
    ```
1. Push to ACR
    ```bash
    docker push crcp2brzfgohm3o.azurecr.io/sample/signal-receiver:1.0.0
    ```

#### Cron Publisher

1. Move to the ./source/cron-publisher directory
1. Run the app
    ```bash
    dapr run --app-id cron-publisher --components-path ../components/ --app-port 5050 --log-level info -- dotnet run .
    ```
1. Build the container
    ```bash
    dotnet publish --os linux --arch x64 -p:PublishProfile=DefaultContainer -c Release
    ```
1. Tag
    ```bash
    docker tag cron-publisher:1.0.0 crcp2brzfgohm3o.azurecr.io/sample/cron-publisher:1.0.0
    ```
1. Push to ACR
    ```bash
    docker push crcp2brzfgohm3o.azurecr.io/sample/cron-publisher:1.0.0
    ```
<!-- 
az deployment group create -g rg-mscacasample --template-file ./infra/event-publisher-app.bicep --parameters imageTag=1.0.0
 -->

 #### Subscriber

1. Move to the ./source/subscriber directory
1. Run the app
    ```bash
    dapr run --app-id subscriber --components-path ../components/ --app-port 5000 --log-level info -- dotnet run .
    ```
1. Build the container
    ```bash
    dotnet publish --os linux --arch x64 -p:PublishProfile=DefaultContainer -c Release
    ```
1. Tag
    ```bash
    docker tag subscriber:1.0.0 crcp2brzfgohm3o.azurecr.io/sample/subscriber:1.0.0
    ```
1. Push to ACR
    ```bash
    docker push crcp2brzfgohm3o.azurecr.io/sample/subscriber:1.0.0
    ```
<!-- 
az deployment group create -g rg-mscacasample --template-file ./infra/event-subscriber-app.bicep --parameters imageTag=1.0.0
 -->

### Deploy Azure resources
1. Open the project dev container in VS Code.
1. Create the Azure Container Registry.
    ```bash
    az deployment sub create \
                  --location eastus \
                  --template-file ./infra/registry.bicep \
                  --parameters name=myacasample location=eastus
    ```
~~1. Run `azd provision` to provision the remaining Azure resources.~~


### Resources
- Dev container inspired by https://github.com/microsoft/vscode-dev-containers/tree/main/containers/dapr-dotnet (used Dapr setup script).
