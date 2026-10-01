@description('Azure region for the Network Security Perimeter.')
param location string

@description('Network Security Perimeter name.')
param networkSecurityPerimeterName string

@description('Network Security Perimeter profile name.')
param profileName string

@description('Name of the Storage resource association.')
param storageAssociationName string

@description('Resource ID of the Storage account protected by the perimeter.')
param storageAccountId string

@description('Public IPv4 address allowed to access Storage through the perimeter.')
param allowedIpAddress string

@description('Subscription ARM ID allowed for Azure service-to-service traffic to Storage.')
param allowedSubscriptionId string

@description('Tags applied to the Network Security Perimeter.')
param tags object

resource networkSecurityPerimeter 'Microsoft.Network/networkSecurityPerimeters@2025-09-01' = {
  name: networkSecurityPerimeterName
  location: location
  tags: tags
  properties: {}
}

resource profile 'Microsoft.Network/networkSecurityPerimeters/profiles@2025-09-01' = {
  parent: networkSecurityPerimeter
  name: profileName
  properties: {}
}

resource allowedIpRule 'Microsoft.Network/networkSecurityPerimeters/profiles/accessRules@2025-09-01' = {
  parent: profile
  name: 'allow-client-ip'
  properties: {
    direction: 'Inbound'
    addressPrefixes: [
      '${allowedIpAddress}/32'
    ]
  }
}

resource subscriptionRule 'Microsoft.Network/networkSecurityPerimeters/profiles/accessRules@2025-09-01' = {
  parent: profile
  name: 'allow-workload-subscription'
  properties: {
    direction: 'Inbound'
    subscriptions: [
      {
        id: allowedSubscriptionId
      }
    ]
  }
}

resource storageAssociation 'Microsoft.Network/networkSecurityPerimeters/resourceAssociations@2025-09-01' = {
  parent: networkSecurityPerimeter
  name: storageAssociationName
  properties: {
    accessMode: 'Enforced'
    privateLinkResource: {
      id: storageAccountId
    }
    profile: {
      id: profile.id
    }
  }
  dependsOn: [
    allowedIpRule
    subscriptionRule
  ]
}

output networkSecurityPerimeterName string = networkSecurityPerimeter.name
output profileId string = profile.id
output storageAssociationId string = storageAssociation.id
