targetScope = 'subscription'

@minLength(1)
@maxLength(50)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param name string

@minLength(1)
@description('Primary location for all resources.')
param location string

@description('Id of the user or app to assign app roles')
param principalId string = '363a0986-6ba9-4b2d-8455-1d95d2086ca1'

var abbrs = loadJsonContent('abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, name))
var tags = {
  'azd-env-name': name
}
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${abbrs.resourcesResourceGroups}${name}'
  location: location
}

module resources 'resources.bicep' = {
  name: 'resources-${resourceToken}'
  scope: rg
  params: {
    tags: tags
    location: location
    resourceToken: resourceToken
    eventHubSku: 'Standard'
    eventHubConsumerGroupName: 'myapp'
    applicationId: 'myapp'
    storageAccountType: 'Standard_RAGZRS'
    principalId: principalId
  }
}

output AZURE_LOCATION string = location
