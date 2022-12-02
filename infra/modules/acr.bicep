@minLength(1)
@description('Primary location for all resources.')
param location string = resourceGroup().location

param tags object

param registryName string

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' = {
  name: registryName
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
