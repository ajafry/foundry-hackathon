@description('Microsoft Foundry account name.')
param accountName string

@description('Azure region for the Foundry account and project.')
param location string

@description('Name of the default Foundry project.')
param projectName string

@description('Name of the project connection to Azure AI Search.')
param searchConnectionName string

@description('Name of the Application Insights monitoring connection.')
param applicationInsightsConnectionName string

@description('Resource ID of the Application Insights monitoring resource.')
param applicationInsightsId string

@description('Name of the Application Insights monitoring resource.')
param applicationInsightsName string

@description('Resource ID of Azure AI Search.')
param searchServiceId string

@description('Endpoint of Azure AI Search.')
param searchServiceEndpoint string

@description('Region of Azure AI Search.')
param searchServiceLocation string

@description('Model version for gpt-5-mini.')
param gpt5MiniModelVersion string

@description('Deployment SKU for gpt-5-mini.')
param gpt5MiniDeploymentSku string

@description('Deployment capacity for gpt-5-mini.')
param gpt5MiniCapacity int

@description('Model version for text-embedding-3-large.')
param embeddingModelVersion string

@description('Deployment SKU for text-embedding-3-large.')
param embeddingDeploymentSku string

@description('Deployment capacity for text-embedding-3-large.')
param embeddingCapacity int

@description('Tags applied to Foundry resources.')
param tags object

resource account 'Microsoft.CognitiveServices/accounts@2025-06-01' = {
  // checkov:skip=CKV_AZURE_134:Public networking is an explicit hackathon requirement; local authentication is disabled.
  name: accountName
  location: location
  tags: tags
  kind: 'AIServices'
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'S0'
  }
  properties: {
    allowProjectManagement: true
    customSubDomainName: accountName
    defaultProject: projectName
    disableLocalAuth: true
    dynamicThrottlingEnabled: false
    publicNetworkAccess: 'Enabled'
    restrictOutboundNetworkAccess: false
  }
}

resource project 'Microsoft.CognitiveServices/accounts/projects@2025-06-01' = {
  parent: account
  name: projectName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: projectName
    description: 'Default project for the Microsoft Foundry hackathon environment.'
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
}

resource gpt5MiniDeployment 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' = {
  parent: account
  name: 'gpt-5-mini'
  sku: {
    name: gpt5MiniDeploymentSku
    capacity: gpt5MiniCapacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-5-mini'
      version: gpt5MiniModelVersion
    }
    versionUpgradeOption: 'OnceNewDefaultVersionAvailable'
  }
  dependsOn: [
    project
  ]
}

resource embeddingDeployment 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' = {
  parent: account
  name: 'text-embedding-3-large'
  sku: {
    name: embeddingDeploymentSku
    capacity: embeddingCapacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'text-embedding-3-large'
      version: embeddingModelVersion
    }
    versionUpgradeOption: 'OnceNewDefaultVersionAvailable'
  }
  dependsOn: [
    gpt5MiniDeployment
  ]
}

resource searchConnection 'Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01' = {
  parent: project
  name: searchConnectionName
  properties: {
    category: 'CognitiveSearch'
    target: searchServiceEndpoint
    authType: 'AAD'
    useWorkspaceManagedIdentity: true
    isSharedToAll: true
    metadata: {
      ApiType: 'Azure'
      ResourceId: searchServiceId
      location: searchServiceLocation
    }
  }
  dependsOn: [
    embeddingDeployment
  ]
}

resource accountApplicationInsightsConnection 'Microsoft.CognitiveServices/accounts/connections@2025-06-01' = {
  parent: account
  name: applicationInsightsConnectionName
  properties: {
    category: 'AppInsights'
    target: applicationInsightsId
    #disable-next-line BCP036
    authType: 'ProjectManagedIdentity'
    useWorkspaceManagedIdentity: true
    isSharedToAll: true
    metadata: {
      ApiType: 'Azure'
      ApplicationInsightsConnectionString: applicationInsights.properties.ConnectionString
      ResourceId: applicationInsightsId
    }
  }
  dependsOn: [
    searchConnection
  ]
}

output accountName string = account.name
output accountId string = account.id
output accountPrincipalId string = account.identity.principalId
output projectName string = project.name
output projectPrincipalId string = project.identity.principalId
output projectEndpoint string = 'https://${account.name}.services.ai.azure.com/api/projects/${project.name}'
output gpt5MiniDeploymentName string = gpt5MiniDeployment.name
output embeddingDeploymentName string = embeddingDeployment.name
output searchConnectionId string = searchConnection.id
output accountApplicationInsightsConnectionId string = accountApplicationInsightsConnection.id
output projectApplicationInsightsConnectionId string = resourceId(
  'Microsoft.CognitiveServices/accounts/projects/connections',
  account.name,
  project.name,
  applicationInsightsConnectionName
)
