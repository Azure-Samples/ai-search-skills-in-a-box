param searchName string
param storageName string
param userIpAddress string
param userPrincipalId string
param appName string
param searchAppPrivateLinkName string
param location string
param tags object = {}

resource search 'Microsoft.Search/searchServices@2024-06-01-preview' = {
  name: searchName
  location: location
  tags: tags
  sku: {
    name: 'standard2'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    disableLocalAuth: true
    hostingMode: 'default'
    partitionCount: 1
    publicNetworkAccess: (userIpAddress != '') ? 'Enabled' : 'Disabled'
    networkRuleSet: {
      bypass: 'AzureServices'
      ipRules: (userIpAddress != '') ? [
        {
          value: userIpAddress
        }
      ] : []
    }
    replicaCount: 1
  }
}

resource functionApp 'Microsoft.Web/sites@2023-12-01' existing = {
  name: appName
}

resource functionAppSharedPrivateLink 'Microsoft.Search/searchServices/sharedPrivateLinkResources@2024-03-01-preview' = {
  name: searchAppPrivateLinkName
  parent: search
  properties: {
    groupId: 'sites'
    privateLinkResourceId: functionApp.id
    requestMessage: 'search needs access to functionapp'
  }
}

resource searchDataIndexContributor 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '8ebe5a00-799e-43f5-93ac-243d3dce84a7'
}

resource userContributorAccess 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(userPrincipalId, search.id, searchDataIndexContributor.id)
  scope: search
  properties: {
    roleDefinitionId: searchDataIndexContributor.id
    principalId: userPrincipalId
    principalType: 'User'
  }
}

resource storage 'Microsoft.Storage/storageAccounts@2023-04-01' existing = {
  name: storageName
}

resource storageBlobDataContributor 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
}

resource storageContributorAccess 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
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
output searchAppSharedPrivateLinkName string = functionAppSharedPrivateLink.name
