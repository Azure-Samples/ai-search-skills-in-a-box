targetScope = 'subscription'

// Common configurations
@description('Name of the environment')
param environmentName string
@description('Resource group name for the AI services. Defauts to rg-<environmentName>')
param resourceGroupName string = ''
@description('Tags for all AI resources created. JSON object')
param tags object = {}

@description('User\'s principal id')
param userPrincipalId string

// AI Services configurations
@description('Name of the AI Search Service. Automatically generated if left blank')
param searchName string = ''
@description('Name of the Storage Account. Automatically generated if left blank')
@maxLength(24)
param storageName string = ''
@description('AI Services resource name')
param aiServicesName string = ''

@description('User IP address to allow for SQL Server connection')
param userIpAddress string = ''

var location = deployment().location
var abbrs = loadJsonContent('abbreviations.json')
var uniqueSuffix = substring(uniqueString(subscription().id, environmentName), 1, 5)

var names = {
  resourceGroupName: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  search: !empty(searchName) ? searchName : '${abbrs.searchSearchServices}${environmentName}-${uniqueSuffix}'
  searchSkill: !empty(searchName) ? '${searchName}-skill' : '${abbrs.searchSearchServices}${environmentName}-${uniqueSuffix}-skill'
  searchAppPrivateLinkName: '${abbrs.networkPrivateLinkServices}${environmentName}-${uniqueSuffix}'
  aiServicesName: !empty(aiServicesName) ? aiServicesName : '${abbrs.cognitiveServicesAzureAI}${environmentName}-${uniqueSuffix}'
  vnetName: '${abbrs.networkVirtualNetworks}${environmentName}-${uniqueSuffix}'
  storage: !empty(storageName)
    ? storageName
    : take(replace(replace('${abbrs.storageStorageAccounts}${environmentName}${uniqueSuffix}', '-', ''), '_', ''), 24)
}

var searchContainer = 'search-container'
var deployContainer = 'deploy-container'
var serviceName = 'web_api'

// 1. Create resource group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: names.resourceGroupName
  location: location
  tags: tags
}

module m_vnet 'modules/vnet.bicep' = {
  name: 'deploy_vnet'
  scope: resourceGroup
  params: {
    vnetName: names.vnetName
    location: location
    tags: tags
  }
}

module m_aiservices 'modules/aiservices.bicep' = {
  name: 'deploy_openai'
  scope: resourceGroup
  params: {
    location: location
    userPrincipalId: userPrincipalId
    userIpAddress: userIpAddress
    subnetId: m_vnet.outputs.subnetId
    aiServicesName: names.aiServicesName
    tags: tags
  }
}

module m_storage 'modules/storage.bicep' = {
  name: 'deploy_storage'
  scope: resourceGroup
  params: {
    storageName: names.storage
    location: location
    tags: tags
    searchContainerName: searchContainer
    deployContainerName: deployContainer
    userPrincipalId: userPrincipalId
    subnetId: m_vnet.outputs.subnetId
    userIpAddress: userIpAddress
  }
}

// 4. Setup search
module m_search 'modules/search.bicep' = {
  name: 'deploy_search'
  scope: resourceGroup
  params: {
    searchName: names.search
    storageName: m_storage.outputs.storageName
    location: location
    userIpAddress: userIpAddress
    userPrincipalId: userPrincipalId
    tags: tags
  }
}

// 5. Setup web api
module m_web_api 'modules/functionapp.bicep' = {
  name: 'deploy_web_api'
  scope: resourceGroup
  params: {
    location: location
    environmentName: environmentName
    servicePlanName: '${m_search.outputs.searchName}-service-plan'
    appName: '${m_search.outputs.searchName}-app'
    storageName: m_storage.outputs.storageName
    aiServicesName: m_aiservices.outputs.aiServicesName
    deployContainerName: deployContainer
    serviceName: serviceName
    subnetId: m_vnet.outputs.subnetId
    userIpAddress: userIpAddress
    tags: tags
  }
}

// 5. Setup network
module m_network 'modules/network.bicep' = {
  name: 'deploy_networking'
  scope: resourceGroup
  params: {
    searchName: m_search.outputs.searchName
    appName: m_web_api.outputs.appName
    searchAppPrivateLinkName: names.searchAppPrivateLinkName
  }
}

output AZURE_RESOURCE_GROUP string = resourceGroup.name
output STORAGE_NAME string = m_storage.outputs.storageName
output SEARCH_SERVICE_NAME string = m_search.outputs.searchName
output SEARCH_DATA_SOURCE_CONNECTION string = 'ResourceId=${m_storage.outputs.storageId};'
output SEARCH_DATA_SOURCE_CONTAINER string = searchContainer
output AZURE_OPENAI_CHAT_DEPLOYMENT_NAME string = m_aiservices.outputs.deploymentName
output AZURE_OPENAI_ENDPOINT string = m_aiservices.outputs.endpoint
output WEB_API_URL string = m_web_api.outputs.appUrl
output WEB_API_NAME string = m_web_api.outputs.appName
output SEARCH_APP_SHARED_PRIVATE_LINK_NAME string = m_network.outputs.searchAppSharedPrivateLinkName
