param location string = resourceGroup().location

param imageTag string
param containerRegistryName string = 'crcp2brzfgohm3o'
param containerAppEnvironmentName string = 'cae-cp2brzfgohm3o'
param managedIdentityName string = 'id-myapp'
param eventHubNamespaceName string = 'evhns-cp2brzfgohm3o'
param eventHubName string = 'orders'

var applicationName = 'event-subscriber'

resource acr 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' existing = {
  name: containerRegistryName
}

module eventSubscriber 'modules/container-app.bicep' = {
  name: 'event-subscriber-deploy'
  params: {
    containerAppName: applicationName
    containerImage: '${acr.properties.loginServer}/sample/subscriber:${imageTag}'
    containerPort: 80
    containerRegistryName: acr.name
    containerAppsEnvironmentName: containerAppEnvironmentName
    location: location
    managedIdentityName: managedIdentityName
    environmentVars: [
    ]
  }
}

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2021-11-01' existing = {
  name: eventHubNamespaceName
}

resource eventHub 'Microsoft.EventHub/namespaces/eventhubs@2021-11-01' existing = {
  name: eventHubName
  parent: eventHubNamespace
}

resource eventHubConsumerGroup 'Microsoft.EventHub/namespaces/eventhubs/consumergroups@2021-11-01' = {
  name: applicationName
  parent: eventHub
}
