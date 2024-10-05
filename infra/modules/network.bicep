param searchName string
param appName string
param searchAppPrivateLinkName string

resource search 'Microsoft.Search/searchServices@2024-06-01-preview' existing = {
  name: searchName
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

output searchAppSharedPrivateLinkName string = functionAppSharedPrivateLink.name
