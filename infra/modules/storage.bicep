@description('Azure region for the Storage account.')
param location string

@description('Globally unique Storage account name.')
@minLength(3)
@maxLength(24)
param storageAccountName string

@description('Blob container name.')
param containerName string

@description('Tags applied to the Storage account.')
param tags object

resource storageAccount 'Microsoft.Storage/storageAccounts@2025-01-01' = {
  // checkov:skip=CKV_AZURE_35:Public networking is an explicit hackathon requirement; blob authorization still requires Entra ID.
  // checkov:skip=CKV_AZURE_59:Public networking is an explicit hackathon requirement; anonymous blob access remains disabled.
  // checkov:skip=CKV_AZURE_43:The parameter is constrained to Storage naming limits and the orchestrator derives lowercase alphanumeric names.
  // checkov:skip=CKV_AZURE_206:Locally redundant storage is intentional for a temporary, cost-conscious hackathon environment.
  name: storageAccountName
  location: location
  tags: tags
  kind: 'StorageV2'
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowCrossTenantReplication: false
    allowSharedKeyAccess: false
    defaultToOAuthAuthentication: true
    minimumTlsVersion: 'TLS1_2'
    publicNetworkAccess: 'SecuredByPerimeter'
    supportsHttpsTrafficOnly: true
    networkAcls: {
      bypass: 'None'
      defaultAction: 'Deny'
    }
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2025-01-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2025-01-01' = {
  parent: blobService
  name: containerName
  properties: {
    publicAccess: 'None'
  }
}

output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name
output containerName string = container.name
output containerUrl string = '${storageAccount.properties.primaryEndpoints.blob}${container.name}'
