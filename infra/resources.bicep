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

// param principalId string

var abbrs = loadJsonContent('abbreviations.json')

// Azure built-in roles (https://learn.microsoft.com/azure/role-based-access-control/built-in-roles)
//Storage Blob Data Contributor built-in role
var storageBlobDataContributorRoleId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'

// Event Hub Receiver built-in role
var eventHubReceiverRoleId = 'a638d3c7-ab3a-418d-83e6-5f17a39d4fde'

// Event Hub Sender built-in role
var eventHubSenderRoleId = '2b629674-e913-4c01-ae53-ef4638d8f975'

// ACR Pull built-in role
var acrPullRoleId = '7f951dda-4ed3-4680-a7ca-43fe172d538d'

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

  resource sensorsEventHub 'eventhubs' = {
    // name: '${abbrs.eventHubNamespacesEventHubs}${resourceToken}'
    name: 'sensors'
    properties: {
      messageRetentionInDays: 7
      partitionCount: 3
    }

    resource consumerGroup 'consumergroups' = {
      name: eventHubConsumerGroupName
      properties: {
      }
    }

    // resource authorizationRule 'authorizationRules' = {
    //   // name: 'ListenSendRule'
    //   name: 'ListenRule'
    //   properties: {
    //     rights: [
    //       'Listen'
    //       // 'Send'
    //     ]
    //   }
    // }

  }

  resource ordersEventHub 'eventhubs' = {
    name: 'orders'
    properties: {
      messageRetentionInDays: 7
      partitionCount: 2
    }

    resource consumerGroup 'consumergroups' = {
      name: 'subscriber'
    }

    // resource authorizationRule 'authorizationRules' = {
    //   name: 'ListenSendRule'
    //   properties: {
    //     rights: [
    //       'Listen'
    //       'Send'
    //     ]
    //   }
    // }
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

// resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
//   name: '${abbrs.keyVaultVaults}${resourceToken}'
//   location: location
//   properties: {
//     enabledForTemplateDeployment: true
//     sku: {
//       family: 'A'
//       name: 'standard'
//     }
//     tenantId: subscription().tenantId
//     accessPolicies: [
//       {
//         objectId: principalId
//         permissions: {
//           secrets: [
//             'list'
//             'get'
//           ]
//         }
//         tenantId: subscription().tenantId
//       }
//     ]
//   }

//   resource eventHubConnectionStringSecret 'secrets' = {
//     name: 'eventHubConnectionStringSecret'
//     properties: {
//       value: eventHubNamespace::eventHub::authorizationRule.listKeys().primaryConnectionString
//     }
//   }
// }

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: '${abbrs.managedIdentityUserAssignedIdentities}${applicationId}'
  location: location
}

module eventHubSenderRoleAssignment 'modules/role-assignment.bicep' = {
  name: 'EventHubSenderRoleAssignment'
  params: {
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: eventHubSenderRoleId
  }
}

module eventHubReceiverRoleAssignment 'modules/role-assignment.bicep' = {
  name: 'EventHubReceiverRoleAssignment'
  params: {
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: eventHubReceiverRoleId
  }
}

module storageRoleAssignment 'modules/role-assignment.bicep' = {
  name: 'StorageRoleAssignment'
  params: {
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: storageBlobDataContributorRoleId
  }
}

module acrRoleAssignment 'modules/role-assignment.bicep' = {
  name: 'AcrRoleAssignment'
  params: {
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: acrPullRoleId
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
          name: 'azureClientId'
          value: managedIdentity.properties.clientId
        }
        {
          name: 'eventHubNamespace'
          value: eventHubNamespace.name
        }
        {
          name: 'eventHub'
          value: eventHubNamespace::sensorsEventHub.name
        }
        {
          name: 'consumerGroup'
          value: 'signal-receiver'
          // value: eventHubConsumerGroupName
        }
        {
          name: 'storageAccountName'
          value: storageAccount.name
        }
        {
          name: 'storageContainerName'
          value: storageAccount::blob::container.name
        }
      ]
      scopes: [
        // applicationId
      ]
    }
  }

  resource daprCronComponent 'daprComponents' = {
    name: 'cron'
    properties: {
      version: 'v1'
      componentType: 'bindings.cron'
      metadata: [
        {
          name: 'schedule'
          value: '@every 15s'
        }
        {
          name: 'route'
          value: '/scheduled'
        }
      ]
    }
  }

  resource daprPubSubComponent 'daprComponents' = {
    name: 'orders-pubsub'
    properties: {
      version: 'v1'
      componentType: 'pubsub.azure.eventhubs'
      metadata: [
        {
          name: 'azureClientId'
          value: managedIdentity.properties.clientId
        }
        {
          name: 'eventHubNamespace'
          value: eventHubNamespace.name
        }
        {
          name: 'storageAccountName'
          value: storageAccount.name
        }
        {
          name: 'storageContainerName'
          value: 'event-hub-checkpoints'
        }
      ]
      scopes: [

      ]
    }
  }
}
