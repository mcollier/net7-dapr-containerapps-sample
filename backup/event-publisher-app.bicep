param location string = resourceGroup().location

param imageTag string
param containerRegistryName string = 'crcp2brzfgohm3o'
param containerAppEnvironmentName string = 'cae-cp2brzfgohm3o'
param managedIdentityName string = 'id-myapp'

var applicationName = 'event-publisher'

resource acr 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' existing = {
  name: containerRegistryName
}

module eventPublisher 'modules/container-app.bicep' = {
  name: 'event-publisher-deploy'
  params: {
    containerAppName: applicationName
    containerImage: '${acr.properties.loginServer}/sample/cron-publisher:${imageTag}'
    containerPort: 80
    containerRegistryName: acr.name
    containerAppsEnvironmentName: containerAppEnvironmentName
    location: location
    managedIdentityName: managedIdentityName
    environmentVars: [
      {
        name: 'TopicName'
        value: 'orders'
      }
      {
        name: 'PubSubName'
        value: 'orders-pubsub'
      }
    ]
  }
}
