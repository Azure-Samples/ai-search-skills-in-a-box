targetScope = 'subscription'

// Common configurations
@description('Name of the environment')
param environmentName string
@description('Resource group name for the AI services. Defauts to rg-<environmentName>')
param resourceGroupName string = ''
@description('Tags for all AI resources created. JSON object')
param tags object = {}

@description('User\'s principal id')
param principalId string
// @description('IP address to allow for local access')
// param ipAddress string = ''

// AI Services configurations
@description('Name of the AI Search Service. Automatically generated if left blank')
param searchName string = ''
@description('Name of the Storage Account. Automatically generated if left blank')
param storageName string = ''
@description('AI Services resource name')
param aiServicesName string = ''

var location = deployment().location
var abbrs = loadJsonContent('abbreviations.json')
var uniqueSuffix = substring(uniqueString(subscription().id, environmentName), 1, 5)

var names = {
  resourceGroupName: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  search: !empty(searchName) ? searchName : '${abbrs.searchSearchServices}${environmentName}-${uniqueSuffix}'
  searchSkill: !empty(searchName) ? '${searchName}-skill' : '${abbrs.searchSearchServices}${environmentName}-${uniqueSuffix}-skill'
  storage: !empty(storageName)
    ? storageName
    : replace(replace('${abbrs.storageStorageAccounts}${environmentName}${uniqueSuffix}', '-', ''), '_', '')
    aiServicesName: !empty(aiServicesName) ? aiServicesName : '${abbrs.cognitiveServicesAzureAI}${environmentName}-${uniqueSuffix}'
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

// 2. Create OpenAI
module m_aiservices 'modules/aiservices.bicep' = {
  name: 'deploy_openai'
  scope: resourceGroup
  params: {
    location: location
    //principalId: principalId
    // ipAddress: ipAddress
    aiServicesName: names.aiServicesName
    tags: tags
  }
}

// 3. Setup storage
module m_storage 'modules/storage.bicep' = {
  name: 'deploy_storage'
  scope: resourceGroup
  params: {
    storageName: names.storage
    location: location
    tags: tags
    searchContainerName: searchContainer
    deployContainerName: deployContainer
    userPrincipalId: principalId
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
    tags: tags
  }
}

output STORAGE_NAME string = m_storage.outputs.storageName
output SEARCH_SERVICE_NAME string = m_search.outputs.searchName
output SEARCH_DATA_SOURCE_CONNECTION string = 'ResourceId=${m_storage.outputs.storageId};'
output SEARCH_DATA_SOURCE_CONTAINER string = searchContainer
output AZURE_OPENAI_CHAT_DEPLOYMENT_NAME string = m_aiservices.outputs.deploymentName
output AZURE_OPENAI_ENDPOINT string = m_aiservices.outputs.endpoint
