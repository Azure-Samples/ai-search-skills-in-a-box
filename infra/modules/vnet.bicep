param vnetName string
param location string
param tags object = {}

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vnetName
  location: location
  properties:{
    addressSpace: {
      addressPrefixes: [
          '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        type: 'Microsoft.Network/virtualNetworks/subnets'
        properties: {
          addressPrefix: '10.0.0.0/24'
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
              locations: [location]
            }
            {
              service: 'Microsoft.CognitiveServices'
              locations: [location]
            }
          ]
          delegations: [
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.App/environments'
              }
            }
          ]
        }
      }
    ]
  }
  tags: tags
}


output subnetId string = vnet.properties.subnets[0].id
