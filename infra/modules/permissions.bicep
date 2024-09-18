param grantAccessTo array
param storageName string

resource storage 'Microsoft.Storage/storageAccounts@2023-04-01' existing = {
  name: storageName
}

resource storageBlobDataContributor 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
}

resource contributorAccess 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for principal in grantAccessTo: if (!empty(principal.id)) {
    name: guid(principal.id, storage.id, storageBlobDataContributor.id)
    scope: storage
    properties: {
      roleDefinitionId: storageBlobDataContributor.id
      principalId: principal.id
      principalType: principal.type
    }
  }
]