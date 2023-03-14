param location string = resourceGroup().location

param containerRegistryName string
param imageTag string
param applicationName string
param containerAppEnvironmentName string
param managedIdentityName string

param eventHubNamespace string
param eventHub string

param storageName string
param checkpointContainerName string

resource acr 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' existing = {
  name: containerRegistryName
}

resource storage 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageName

  resource blob 'blobServices' existing = {
    name: 'default'

    resource container 'containers' existing = {
      name: checkpointContainerName
    }
  }
}

resource ehns 'Microsoft.EventHub/namespaces@2022-10-01-preview' existing = {
  name: eventHubNamespace

  resource eh 'eventhubs' existing = {
    name: eventHub
  }

  resource authRule 'authorizationRules' existing = {
    name: 'RootManageSharedAccessKey'
  }
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' existing = {
  name: managedIdentityName
}

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-03-01' existing = {
  name: containerAppEnvironmentName

  resource daprBindingComponent 'daprComponents' = {
    name: 'events'
    properties: {
      componentType: 'bindings.azure.eventhubs'
      version: 'v1'
      metadata: [
        {
          name: 'azureClientId'
          value: managedIdentity.properties.clientId
        }
        {
          name: 'eventHubNamespace'
          value: ehns.name
        }
        {
          name: 'eventHub'
          value: ehns::eh.name
        }
        {
          name: 'consumerGroup'
          value: applicationName
        }
        {
          name: 'storageAccountName'
          value: storage.name
        }
        {
          name: 'storageContainerName'
          value: storage::blob::container.name
        }
      ]
      scopes: [
        applicationName
      ]
    }
  }
}

module signalReceiver 'modules/container-app.bicep' = {
  name: 'signal-receiver-deploy'
  params: {
    containerAppName: applicationName
    containerImage: '${acr.properties.loginServer}/signal-receiver:${imageTag}'
    containerPort: 80
    containerRegistryName: acr.name
    containerAppsEnvironmentName: containerAppEnvironmentName
    location: location
    managedIdentityName: managedIdentityName
    environmentVars: []
    secrets: [
      {
        name: 'eventhub-connection'
        //value: ehns::eh::authorizationRule.listKeys().primaryConnectionString
        value: ehns::authRule.listKeys().primaryConnectionString
      }
      {
        name: 'storage-connection'
        value: 'DefaultEndpointsProtocol=https;AccountName=${storage.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storage.listKeys().keys[0].value}'
      }
    ]
    scaleRules: [
      {
        name: 'azure-eventhub-scale-rule'
        custom: {
          type: 'azure-eventhub'
          metadata: {
            consumerGroup: applicationName
            eventHubNamespace: ehns.name
            eventHubName: ehns::eh.name
            unprocessedEventThreshold: '64'
            activationUnprocessedEventThreshold: '0'
            blobContainer: storage::blob::container.name
            storageAccountName: storage.name
            checkpointStrategy: 'dapr'
          }
          auth: [
            {
              secretRef: 'eventhub-connection'
              triggerParameter: 'connection'
            }
            {
              secretRef: 'storage-connection'
              triggerParameter: 'storageConnection'
            }
          ]
        }
      }
    ]
  }
}
