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

param principalId string

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

  resource eventHub2 'eventhubs' = {
    name: '${abbrs.eventHubNamespacesEventHubs}${resourceToken}2'
    properties: {
      messageRetentionInDays: 7
      partitionCount: 3
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

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: '${abbrs.keyVaultVaults}${resourceToken}'
  location: location
  properties: {
    enabledForTemplateDeployment: true
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: [
      {
        objectId: principalId
        permissions: {
          secrets: [
            'list'
            'get'
          ]
        }
        tenantId: subscription().tenantId
      }
    ]
  }

  resource eventHubConnectionStringSecret 'secrets' = {
    name: 'eventHubConnectionStringSecret'
    properties: {
      value: eventHubNamespace::eventHub2::listenAuthorizationRule.listKeys().primaryConnectionString
    }
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
          value: eventHubNamespace::eventHub2::listenAuthorizationRule.listKeys().primaryConnectionString
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
