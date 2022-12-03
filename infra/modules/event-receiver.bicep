@minLength(1)
@description('Primary location for all resources.')
param location string = resourceGroup().location

param name string
param image string
param containerAppName string
param port int = 80
@description('Identifier for the application.')
param daprAppId string
param consumerGroupName string

var tags = { 'azd-env-name': name }
var abbrs = loadJsonContent('../abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, name))

resource env 'Microsoft.App/managedEnvironments@2022-03-01' existing = {
  name: '${abbrs.appManagedEnvironments}${resourceToken}'
}

resource acr 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' existing = {
  name: '${abbrs.containerRegistryRegistries}${resourceToken}'
}

resource storage 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name: '${abbrs.storageStorageAccounts}${resourceToken}'
}

resource ai 'Microsoft.Insights/components@2020-02-02' existing = {
  name: '${abbrs.insightsComponents}${resourceToken}'
}

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2021-11-01' existing = {
  name: '${abbrs.eventHubNamespaces}${resourceToken}'

  resource eventHub 'eventhubs' existing = {
    name: '${abbrs.eventHubNamespacesEventHubs}${resourceToken}'

    resource consumerGroup 'consumergroups' existing = {
      name: consumerGroupName
    }

    resource listenAuthorizationRule 'authorizationRules' existing = {
      name: 'listen'
    }
  }
}

resource app 'Microsoft.App/containerApps@2022-03-01' = {
  name: '${abbrs.appContainerApps}${resourceToken}'
  location: location
  tags: union(tags, { 'azd-service-name': containerAppName })
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: env.id
    configuration: {
      activeRevisionsMode: 'Single'
      secrets: [
        {
          name: 'registry-password'
          value: acr.listCredentials().passwords[0].value
        }
        {
          name: 'eventhub-connection'
          value: eventHubNamespace::eventHub::listenAuthorizationRule.listKeys().primaryConnectionString
        }
        {
          name: 'storage-connection'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storage.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storage.listKeys().keys[0].value}'
        }
      ]
      registries: [
        {
          server: '${acr.name}.azurecr.io'
          username: acr.name
          passwordSecretRef: 'registry-password'
        }
      ]
      dapr: {
        enabled: true
        appId: daprAppId
        appProtocol: 'http'
        appPort: port
      }
    }
    template: {
      containers: [
        {
          image: image
          name: containerAppName
          env: [
            {
              name: 'ASPNETCORE_ENVIRONMENT'
              value: 'Development'
            }
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              // TODO: Move to Key Vault
              value: ai.properties.ConnectionString
            }
          ]
          resources: {
            cpu: 1
            memory: '2.0Gi'
          }
        }
      ]
      scale: {
        maxReplicas: 3
        minReplicas: 1

        // How do I know if this is right? 
        // I don't think this is right . . . each new revision seems to reply the full event stream. 
        // Checkpoints don't seem to be set correctly.  Why?
        //   rules: [
        //     {
        //       name: 'eventhub-trigger'
        //       custom: {
        //         type: 'azure-eventhub'
        //         metadata: {
        //           consumerGroup: eventHubConsumerGroupName
        //           unprocessedEventThreshold: '64' // default
        //           activationUnprocessedEventThreshold: '0' // default
        //           blobContainer: storage::blob::container.name
        //           cloud: 'AzurePublicCloud' // default
        //           checkpointStrategy: 'goSdk' // use goSdk for Dapr
        //         }
        //         auth: [
        //           {
        //             secretRef: 'eventhub-connection'
        //             triggerParameter: 'connection'
        //           }
        //           {
        //             secretRef: 'storage-connection'
        //             triggerParameter: 'storageConnection'
        //           }
        //         ]
        //       }
        //     }
        //   ]
        // }
      }
    }
  }
}
