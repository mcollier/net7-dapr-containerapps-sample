targetScope = 'subscription'

@minLength(1)
@maxLength(50)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param name string

@minLength(1)
@description('Primary location for all resources.')
param location string

var tags = {}
var abbrs = loadJsonContent('abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, name))

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${abbrs.resourcesResourceGroups}${name}'
  location: location
}

module acr 'modules/acr.bicep' = {
  name: 'acr-${resourceToken}'
  scope: rg
  params: {
    tags: tags
    location: location
    registryName: '${abbrs.containerRegistryRegistries}${resourceToken}'
  }
}
