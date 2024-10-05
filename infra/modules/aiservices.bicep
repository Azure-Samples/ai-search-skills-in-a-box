param location string
param userPrincipalId string
param userIpAddress string
param aiServicesName string
param subnetId string
param tags object = {}

resource aiServices 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: aiServicesName
  location: location
  tags: tags
  sku: {
    name: 'S0'
  }
  kind: 'AIServices'
  properties: {
    customSubDomainName: aiServicesName
    disableLocalAuth: true
    publicNetworkAccess: (userIpAddress != '') ? 'Enabled' : 'Disabled'
    networkAcls:  {
      defaultAction: 'Deny'
      ipRules: (userIpAddress != '') ? [
          {
            value: userIpAddress
          }
      ] : []
      virtualNetworkRules: [
        {
          id: subnetId
        }
      ]
    }
  }
}

resource gptDeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: aiServices
  name: 'gpt-4o'
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4o'
      version: '2024-05-13'
    }
  }
  sku: {
    capacity: 10
    name: 'Standard'
  }
}

resource openaiServiceContributorRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: 'a001fd3d-188f-4b5d-821b-7da978bf7442'
}

resource openaiServiceRBAC 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(userPrincipalId, aiServices.id, openaiServiceContributorRole.id)
  scope: aiServices
  properties: {
    roleDefinitionId: openaiServiceContributorRole.id
    principalId: userPrincipalId
    principalType: 'User'
  }
}

output aiServicesName string = aiServices.name
output endpoint string = aiServices.properties.endpoint
output deploymentName string = gptDeployment.name
