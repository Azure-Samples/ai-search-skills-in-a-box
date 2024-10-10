param location string
param userPrincipalId string
param userIpAddress string
param openaiName string
param subnetId string
param tags object = {}

resource openai 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: openaiName
  location: location
  tags: tags
  sku: {
    name: 'S0'
  }
  kind: 'OpenAI'
  properties: {
    customSubDomainName: openaiName
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
  parent: openai
  name: 'gpt-4o'
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4o'
      version: '2024-05-13'
    }
  }
  sku: {
    capacity: 20
    name: 'Standard'
  }
}

resource openaiContributorRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: 'a001fd3d-188f-4b5d-821b-7da978bf7442'
}

resource openaiRBAC 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(userPrincipalId, openai.id, openaiContributorRole.id)
  scope: openai
  properties: {
    roleDefinitionId: openaiContributorRole.id
    principalId: userPrincipalId
    principalType: 'User'
  }
}

output openaiName string = openai.name
output endpoint string = openai.properties.endpoint
output deploymentName string = gptDeployment.name
