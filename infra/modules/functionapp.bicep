param location string
param environmentName string
param servicePlanName string
param appName string
param storageName string
param aiServicesName string
param deployContainerName string
param serviceName string
param subnetId string
param userIpAddress string
param tags object = {}

resource storage 'Microsoft.Storage/storageAccounts@2023-04-01' existing = {
  name: storageName
}

resource servicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: servicePlanName
  location: location
  kind: 'linux'
  sku: {
    name: 'FC1'
    tier: 'FlexConsumption'
  }
  properties: {
    reserved: true
  }
}

resource functionApp 'Microsoft.Web/sites@2023-12-01' = {
  name: appName
  location: location
  tags: union(tags, { 'azd-service-name': serviceName,  'azd-env-name': environmentName})
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    reserved: true
    httpsOnly: true
    serverFarmId: servicePlan.id
    publicNetworkAccess: (userIpAddress != '') ? 'Enabled' : 'Disabled'
    virtualNetworkSubnetId: subnetId
    vnetRouteAllEnabled: false
    functionAppConfig: {
      deployment: {
        storage: {
          type: 'blobContainer'
          value: '${storage.properties.primaryEndpoints.blob}${deployContainerName}'
          authentication: {
            type: 'SystemAssignedIdentity'
          }
        }
      }
      runtime: {
        name: 'python'
        version: '3.10'
      }
      scaleAndConcurrency: {
        instanceMemoryMB: 2048
        maximumInstanceCount: 40
      }
    }
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage__accountName'
          value: storageName
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
      ]
      ipSecurityRestrictions: (userIpAddress != '') ? [
        {
          action: 'Allow'
          description: 'my local ip'
          ipAddress: '${userIpAddress}/32'
          name: 'myLocalIp'
          priority: 300
        }
      ] : []
      ipSecurityRestrictionsDefaultAction: 'Deny'
      scmIpSecurityRestrictions: (userIpAddress != '') ? [
        {
          action: 'Allow'
          description: 'my local ip'
          ipAddress: '${userIpAddress}/32'
          name: 'myLocalIp'
          priority: 300
        }
      ] : []
      scmIpSecurityRestrictionsDefaultAction: 'Deny'
    }
  }
}

resource storageBlobDataContributor 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
}

resource storageContributorAccess 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(functionApp.id, storage.id, storageBlobDataContributor.id)
  scope: storage
  properties: {
    roleDefinitionId: storageBlobDataContributor.id
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource aiServices 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: aiServicesName
}

resource openaiServiceUserRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
}

resource openaiServiceRBAC 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(functionApp.id, aiServices.id, openaiServiceUserRole.id)
  scope: aiServices
  properties: {
    roleDefinitionId: openaiServiceUserRole.id
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

output appName string = functionApp.name
output appPrincipalId string = functionApp.identity.principalId
output appUrl string = functionApp.properties.hostNames[0]
