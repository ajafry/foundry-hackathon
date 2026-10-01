@description('Azure region for Azure AI Search.')
param location string

@description('Globally unique Azure AI Search service name.')
param searchServiceName string

@description('Azure AI Search SKU.')
param searchSkuName string

@description('Semantic Search billing plan.')
param semanticSearch string

@description('Tags applied to Azure AI Search.')
param tags object

resource searchService 'Microsoft.Search/searchServices@2025-05-01' = {
  // checkov:skip=CKV_AZURE_208:A single replica is intentional for a temporary hackathon; production index-update SLA is out of scope.
  // checkov:skip=CKV_AZURE_209:A single replica is intentional for a temporary hackathon; production query SLA is out of scope.
  name: searchServiceName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: searchSkuName
  }
  properties: {
    disableLocalAuth: true
    encryptionWithCmk: {
      enforcement: 'Disabled'
    }
    hostingMode: 'Default'
    networkRuleSet: {
      bypass: 'None'
      ipRules: []
    }
    partitionCount: 1
    publicNetworkAccess: 'Enabled'
    replicaCount: 1
    semanticSearch: semanticSearch
  }
}

output searchServiceId string = searchService.id
output searchServiceName string = searchService.name
output searchServiceEndpoint string = searchService.properties.endpoint
output searchServiceLocation string = searchService.location
output searchPrincipalId string = searchService.identity.principalId
