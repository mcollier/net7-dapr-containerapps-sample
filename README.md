# .NET 7, Dapr, and Azure Container Apps Sample

:construction:This project is under development.:construction:
This is a bit messy at the moment.  :(

## Getting Started

### Run locally

1. Run the app
    ```
    dapr run --app-id myapp --components-path ./source/components/ --app-port 5000 -- dotnet run --project ./source/
    ```

### Deploy Azure resources
1. Open the project dev container in VS Code.
1. Create the Azure Container Registry.
    ```bash
    az deployment sub create \
                  --location eastus \
                  --template-file ./infra/registry.bicep \
                  --parameters name=myacasample location=eastus
    ```
1. Run `azd provision` to provision the remaining Azure resources.


### Resources
- Dev container inspired by https://github.com/microsoft/vscode-dev-containers/tree/main/containers/dapr-dotnet (used Dapr setup script).
