param location string
// param principalId string
// param ipAddress string
param aiServicesName string
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
//     apiProperties: {
//       statisticsEnabled: false
//     }
    disableLocalAuth: true // do not support api key authentication
    publicNetworkAccess: 'Enabled' //(ipAddress != '') ? 'Enabled' : 'Disabled'
//     networkAcls: (ipAddress != '') ? {
//       defaultAction: 'Deny'
//       ipRules: [
//           {value: ipAddress}
//       ]
//     } : null
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
    capacity: 2
    name: 'Standard'
  }
}

output aiServicesName string = aiServices.name
output endpoint string = aiServices.properties.endpoint
output deploymentName string = gptDeployment.name
