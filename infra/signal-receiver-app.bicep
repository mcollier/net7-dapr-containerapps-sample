param location string = resourceGroup().location

param eventHubNamespaceName string
param eventHubName string

param containerRegistryName string
param imageTag string
var applicationName = 'signal-receiver'

param containerAppEnvironmentName string = 'cae-cp2brzfgohm3o'
param managedIdentityName string = 'id-myapp'

resource acr 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' existing = {
  name: containerRegistryName
}

module eventPublisher 'modules/container-app.bicep' = {
  name: 'signal-receiver-deploy'
  params: {
    containerAppName: applicationName
    containerImage: '${acr.properties.loginServer}/sample/signal-receiver:${imageTag}'
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
