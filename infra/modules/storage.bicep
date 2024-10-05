param storageName string
param location string
param tags object = {}
param searchContainerName string
param deployContainerName string
param userPrincipalId string
param subnetId string
param userIpAddress string

resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    isLocalUserEnabled: false
    accessTier: 'Hot'
    allowSharedKeyAccess: false
    encryption: {
      keySource: 'Microsoft.Storage'
      services: {
        blob: {
          enabled: true
          keyType: 'Account'
        }
      }
    }
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    publicNetworkAccess: (userIpAddress != '') ? 'Enabled' : 'Disabled'
    networkAcls: {
      defaultAction: 'Deny'
      ipRules: (userIpAddress != '') ? [
        {
          value: userIpAddress
          action: 'Allow'
        }
      ] : []
      virtualNetworkRules: [
        {
          action: 'Allow'
          id: subnetId
        }
      ]
    }
  }
}

resource blob 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  name: 'default'
  parent: storage
}

resource searchContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: searchContainerName
  parent: blob
}

resource deployContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: deployContainerName
  parent: blob
}

resource storageBlobDataContributor 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
}

resource userContributorAccess 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(userPrincipalId, storage.id, storageBlobDataContributor.id)
  scope: storage
  properties: {
    roleDefinitionId: storageBlobDataContributor.id
    principalId: userPrincipalId
    principalType: 'User'
  }
}

output storageId string = storage.id
output storageName string = storage.name
