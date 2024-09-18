param searchName string
param storageName string
param location string
param tags object = {}

resource search 'Microsoft.Search/searchServices@2024-06-01-preview' = {
  name: searchName
  location: location
  tags: tags
  sku: {
    name: 'standard'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    disableLocalAuth: true
    hostingMode: 'default'
    partitionCount: 1
    publicNetworkAccess: 'enabled'
    replicaCount: 1
  }
}

resource storage 'Microsoft.Storage/storageAccounts@2023-04-01' existing = {
  name: storageName
}

resource storageBlobDataContributor 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
}

resource contributorAccess 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(search.id, storage.id, storageBlobDataContributor.id)
  scope: storage
  properties: {
    roleDefinitionId: storageBlobDataContributor.id
    principalId: search.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

output searchID string = search.id
output searchName string = search.name
output searchPrincipalId string = search.identity.principalId
