param location string = resourceGroup().location

param containerRegistryName string
param imageTag string
param applicationName string
param containerAppEnvironmentName string
param managedIdentityName string

param eventHubNamespace string
param eventHub string
param storageName string

resource acr 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' existing = {
  name: containerRegistryName
}

resource storage 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageName
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
            consumerGroup: 'signal-receiver'
            eventHubNamespace: ehns.name
            eventHubName: ehns::eh.name
            unprocessedEventThreshold: '64'
            activationUnprocessedEventThreshold: '0'
            blobContainer: 'event-hub-checkpoints'
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
