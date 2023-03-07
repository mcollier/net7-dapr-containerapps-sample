@description('Primary location for all resources.')
param location string = resourceGroup().location

param containerAppName string

param containerAppsEnvironmentName string
param containerImage string
param containerPort int
param containerRegistryName string
param managedIdentityName string

param environmentVars array = []

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' existing = {
  name: managedIdentityName
}

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-03-01' existing = {
  name: containerAppsEnvironmentName
}

resource acr 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' existing = {
  name: containerRegistryName
}

resource containerApp 'Microsoft.App/containerApps@2022-03-01' = {
  name: containerAppName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    configuration: {
      activeRevisionsMode: 'Single'
      dapr: {
        enabled: true
        appId: containerAppName
        appPort: containerPort
        appProtocol: 'http'

        //TODO: Submit feedback to get these properties listed in schema - https://github.com/Azure/bicep/issues/784#issuecomment-1341836608
        enableApiLogging: true
        logLevel: 'debug'
      }
      registries: [
        {
          server: acr.properties.loginServer
          identity: managedIdentity.id
        }
      ]
      secrets: [
      ]
    }
    template: {
      containers: [
        {
          image: containerImage
          name: containerAppName
          env: environmentVars
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 3
        rules: [

        ]
      }
    }
  }
}