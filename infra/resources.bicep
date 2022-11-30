@minLength(1)
@description('Primary location for all resources.')
param location string = resourceGroup().location

@description('Specifies the messaging tier for Event Hub Namespace.')
@allowed([
  'Basic'
  'Standard'
])
param eventHubSku string = 'Standard'

// @minLength(1)
// param eventHubNamespaceName string

// @minLength(1)
// param eventHubName string

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

// param storageAccountName string

param resourceToken string
param tags object

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
}
