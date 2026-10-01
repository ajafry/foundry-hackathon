targetScope = 'resourceGroup'

@description('Short workload prefix used to derive resource names. Use lowercase letters, numbers, and hyphens.')
@minLength(2)
@maxLength(16)
param namingPrefix string = 'aurora'

@description('Optional deterministic suffix. Defaults to a value unique to the subscription and resource group.')
@minLength(3)
@maxLength(12)
param resourceSuffix string = substring(uniqueString(subscription().subscriptionId, resourceGroup().id), 0, 6)

@description('Location for the Foundry account, project, Search service, and Storage account.')
param location string = resourceGroup().location

@description('Location for the Foundry account, project, and model deployments. Defaults to the main resource location.')
param foundryLocation string = location

@description('Name of the default Microsoft Foundry project.')
@minLength(2)
@maxLength(64)
param projectName string = 'project-aurora'

@description('Azure AI Search SKU.')
@allowed([
  'basic'
  'standard'
  'standard2'
  'standard3'
])
param searchSkuName string = 'basic'

@description('Semantic Search billing plan.')
@allowed([
  'disabled'
  'free'
  'standard'
])
param semanticSearch string = 'free'

@description('Model version for the gpt-5-mini deployment.')
param gpt5MiniModelVersion string = '2025-08-07'

@description('SKU for the gpt-5-mini deployment.')
param gpt5MiniDeploymentSku string = 'GlobalStandard'

@description('Capacity for the gpt-5-mini deployment, expressed in thousands of tokens per minute.')
@minValue(1)
param gpt5MiniCapacity int = 10

@description('Model version for the text-embedding-3-large deployment.')
param embeddingModelVersion string = '1'

@description('SKU for the text-embedding-3-large deployment.')
param embeddingDeploymentSku string = 'GlobalStandard'

@description('Capacity for the text-embedding-3-large deployment, expressed in thousands of tokens per minute.')
@minValue(1)
param embeddingCapacity int = 10

@description('Tags applied to all supported resources.')
param tags object = {
  workload: 'foundry-hackathon'
  environment: 'demo'
}

@description('Public IPv4 address allowed through the Storage network security perimeter.')
param storageAllowedIpAddress string = '162.233.6.221'

var normalizedPrefix = toLower(namingPrefix)
var storagePrefix = replace(normalizedPrefix, '-', '')
var foundryAccountName = '${normalizedPrefix}-foundry-${resourceSuffix}'
var searchServiceName = '${normalizedPrefix}-search-${resourceSuffix}'
var storageAccountName = take('${storagePrefix}st${resourceSuffix}', 24)
var searchConnectionName = 'search-${resourceSuffix}'
var applicationInsightsConnectionName = 'appinsights-${resourceSuffix}'
var networkSecurityPerimeterName = '${normalizedPrefix}-nsp-${resourceSuffix}'
var logAnalyticsWorkspaceName = '${normalizedPrefix}-law-${resourceSuffix}'
var applicationInsightsName = '${normalizedPrefix}-appi-${resourceSuffix}'

module storage './modules/storage.bicep' = {
  name: 'storage-${resourceSuffix}'
  params: {
    location: location
    storageAccountName: storageAccountName
    containerName: 'project-aurora'
    tags: tags
  }
}

module search './modules/search.bicep' = {
  name: 'search-${resourceSuffix}'
  params: {
    location: location
    searchServiceName: searchServiceName
    searchSkuName: searchSkuName
    semanticSearch: semanticSearch
    tags: tags
  }
}

module monitoring './modules/monitoring.bicep' = {
  name: 'monitoring-${resourceSuffix}'
  params: {
    location: location
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    applicationInsightsName: applicationInsightsName
    retentionInDays: 30
    tags: tags
  }
}

module foundry './modules/foundry.bicep' = {
  name: 'foundry-${resourceSuffix}'
  params: {
    accountName: foundryAccountName
    location: foundryLocation
    projectName: projectName
    searchConnectionName: searchConnectionName
    applicationInsightsConnectionName: applicationInsightsConnectionName
    applicationInsightsId: monitoring.outputs.applicationInsightsId
    applicationInsightsName: monitoring.outputs.applicationInsightsName
    searchServiceId: search.outputs.searchServiceId
    searchServiceEndpoint: search.outputs.searchServiceEndpoint
    searchServiceLocation: search.outputs.searchServiceLocation
    gpt5MiniModelVersion: gpt5MiniModelVersion
    gpt5MiniDeploymentSku: gpt5MiniDeploymentSku
    gpt5MiniCapacity: gpt5MiniCapacity
    embeddingModelVersion: embeddingModelVersion
    embeddingDeploymentSku: embeddingDeploymentSku
    embeddingCapacity: embeddingCapacity
    tags: tags
  }
}

module networkSecurityPerimeter './modules/network-security-perimeter.bicep' = {
  name: 'network-security-perimeter-${resourceSuffix}'
  params: {
    location: location
    networkSecurityPerimeterName: networkSecurityPerimeterName
    profileName: 'storage'
    storageAssociationName: 'storage-${resourceSuffix}'
    storageAccountId: storage.outputs.storageAccountId
    allowedIpAddress: storageAllowedIpAddress
    allowedSubscriptionId: subscription().id
    tags: tags
  }
}

module rbac './modules/rbac.bicep' = {
  name: 'rbac-${resourceSuffix}'
  params: {
    storageAccountName: storage.outputs.storageAccountName
    storageAccountId: storage.outputs.storageAccountId
    searchServiceName: search.outputs.searchServiceName
    searchServiceId: search.outputs.searchServiceId
    searchPrincipalId: search.outputs.searchPrincipalId
    foundryAccountName: foundry.outputs.accountName
    foundryAccountId: foundry.outputs.accountId
    foundryAccountPrincipalId: foundry.outputs.accountPrincipalId
    foundryProjectPrincipalId: foundry.outputs.projectPrincipalId
    applicationInsightsName: monitoring.outputs.applicationInsightsName
    applicationInsightsId: monitoring.outputs.applicationInsightsId
  }
}

output foundryAccountName string = foundry.outputs.accountName
output foundryProjectName string = foundry.outputs.projectName
output foundryProjectEndpoint string = foundry.outputs.projectEndpoint
output gpt5MiniDeploymentName string = foundry.outputs.gpt5MiniDeploymentName
output embeddingDeploymentName string = foundry.outputs.embeddingDeploymentName
output searchServiceName string = search.outputs.searchServiceName
output searchServiceEndpoint string = search.outputs.searchServiceEndpoint
output searchConnectionId string = foundry.outputs.searchConnectionId
output logAnalyticsWorkspaceName string = monitoring.outputs.logAnalyticsWorkspaceName
output logAnalyticsWorkspaceId string = monitoring.outputs.logAnalyticsWorkspaceId
output applicationInsightsName string = monitoring.outputs.applicationInsightsName
output applicationInsightsId string = monitoring.outputs.applicationInsightsId
output accountApplicationInsightsConnectionId string = foundry.outputs.accountApplicationInsightsConnectionId
output projectApplicationInsightsConnectionId string = foundry.outputs.projectApplicationInsightsConnectionId
output storageAccountName string = storage.outputs.storageAccountName
output blobContainerName string = storage.outputs.containerName
output blobContainerUrl string = storage.outputs.containerUrl
output networkSecurityPerimeterName string = networkSecurityPerimeter.outputs.networkSecurityPerimeterName
output networkSecurityPerimeterProfileId string = networkSecurityPerimeter.outputs.profileId
output storagePerimeterAssociationId string = networkSecurityPerimeter.outputs.storageAssociationId
