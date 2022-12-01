# .NET 7, Dapr, and Azure Container Apps Sample

## Getting Started

1. Open the project dev container in VS Code.
1. Run `azd provision` to provision the Azure resources.
1. Run the app
    ```
    dapr run --app-id myapp --components-path ./source/components/ --app-port 5000 -- dotnet run --project ./source/
    ```

### Resources
- Dev container inspired by https://github.com/microsoft/vscode-dev-containers/tree/main/containers/dapr-dotnet (used Dapr setup script).
