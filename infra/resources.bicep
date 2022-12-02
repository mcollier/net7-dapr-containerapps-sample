@minLength(1)
@description('Primary location for all resources.')
param location string = resourceGroup().location

@description('Specifies the messaging tier for Event Hub Namespace.')
@allowed([
  'Basic'
  'Standard'
])
param eventHubSku string = 'Standard'

@description('Name of the Event Hub consumer group to be created.')
param eventHubConsumerGroupName string

@description('Storage Account type')
@allowed([
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GRS'
  'Standard_GZRS'
  'Standard_LRS'
  'Standard_RAGRS'
  'Standard_RAGZRS'
  'Standard_ZRS'
])
param storageAccountType string = 'Standard_LRS'

@description('Value used in name of Azure resources.')
param resourceToken string

@description('Tags to be applied to Azure resources.')
param tags object

@description('Identifier for the application.')
param applicationId string

var abbrs = loadJsonContent('abbreviations.json')

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2021-11-01' = {
  name: '${abbrs.eventHubNamespaces}${resourceToken}'
  location: location
  tags: tags
  sku: {
    name: eventHubSku
  }
  properties: {
    isAutoInflateEnabled: false
    maximumThroughputUnits: 0
    zoneRedundant: true
  }

  resource eventHub 'eventhubs' = {
    name: '${abbrs.eventHubNamespacesEventHubs}${resourceToken}'
    properties: {
      messageRetentionInDays: 7
      partitionCount: 1
    }

    resource consumerGroup 'consumergroups' = {
      name: eventHubConsumerGroupName
      properties: {
      }
    }

    resource listenAuthorizationRule 'authorizationRules' = {
      name: 'listen'
      properties: {
        rights: [
          'Listen'
        ]
      }
    }
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: '${abbrs.storageStorageAccounts}${resourceToken}'
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: storageAccountType
  }
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
  }

  resource blob 'blobServices' = {
    name: 'default'
    properties: {
    }

    resource container 'containers' = {
      name: 'event-hub-checkpoints'
    }
  }
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${abbrs.insightsComponents}${resourceToken}'
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
  }
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' = {
  name: '${abbrs.containerRegistryRegistries}${resourceToken}'
  location: location
  tags: tags
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
    anonymousPullEnabled: false
    dataEndpointEnabled: false
    encryption: {
      status: 'disabled'
    }
    networkRuleBypassOptions: 'AzureServices'
    publicNetworkAccess: 'Enabled'
    zoneRedundancy: 'Disabled' // Not supported on Basic SKU - https://learn.microsoft.com/azure/container-registry/container-registry-skus.

  }
}

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-03-01' = {
  name: '${abbrs.appManagedEnvironments}${resourceToken}'
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }

  resource daprBindingComponent 'daprComponents' = {
    name: 'events'
    properties: {
      componentType: 'bindings.azure.eventhubs'
      version: 'v1'
      metadata: [
        {
          name: 'connectionString'
          value: eventHubNamespace::eventHub::listenAuthorizationRule.listKeys().primaryConnectionString
        }
        {
          name: 'consumerGroup'
          value: eventHubConsumerGroupName
        }
        {
          name: 'storageAccountName'
          value: storageAccount.name
        }
        {
          name: 'storageAccountKey'
          value: storageAccount.listKeys().keys[0].value
        }
        {
          name: 'storageContainerName'
          value: storageAccount::blob::container.name
        }
      ]
      scopes: [
        applicationId
      ]
    }
  }
}

resource app 'Microsoft.App/containerApps@2022-03-01' = {
  name: '${abbrs.appContainerApps}${resourceToken}'
  location: location
  tags: union(tags, { 'azd-service-name': applicationId })
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    configuration: {
      activeRevisionsMode: 'Single'
      // ingress: {
      //   external: false
      //   targetPort: 80
      //   transport: 'auto'
      // }
      secrets: [
        {
          name: 'registry-password'
          value: containerRegistry.listCredentials().passwords[0].value
        }
        {
          name: 'eventhub-connection'
          value: eventHubNamespace::eventHub::listenAuthorizationRule.listKeys().primaryConnectionString
        }
        {
          name: 'storage-connection'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
      ]
      registries: [
        {
          server: '${containerRegistry.name}.azurecr.io'
          username: containerRegistry.name
          passwordSecretRef: 'registry-password'
        }
      ]
      dapr: {
        enabled: true
        appId: applicationId
        appProtocol: 'http'
        appPort: 80
      }
    }
    template: {
      containers: [
        {
          image: '${containerRegistry.name}.azurecr.io/collier/net7-dapr-aca-sample:latest'
          name: 'main'
          env: [
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              // TODO: Move to Key Vault
              value: applicationInsights.properties.ConnectionString
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
        rules: [
          {
            name: 'eventhub-trigger'
            custom: {
              type: 'azure-eventhub'
              metadata: {
                consumerGroup: eventHubConsumerGroupName
                unprocessedEventThreshold: '64' // default
                activationUnprocessedEventThreshold: '0' // default
                blobContainer: storageAccount::blob::container.name
                cloud: 'AzurePublicCloud' // default
                checkpointStrategy: 'goSdk' // use goSdk for Dapr
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
  }
}
