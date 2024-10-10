$RESOURCE_GROUP = (azd env get-value AZURE_RESOURCE_GROUP)
$WEB_API_NAME =  (azd env get-value WEB_API_NAME)
$SEARCH_APP_SHARED_PRIVATE_LINK_NAME = (azd env get-value SEARCH_APP_SHARED_PRIVATE_LINK_NAME)
$SITES_TYPE = "Microsoft.Web/sites"

$PRIVATE_LINK_NAME = (az network private-endpoint-connection list -g $RESOURCE_GROUP -n $WEB_API_NAME --type $SITES_TYPE --query "[?contains(name, '$SEARCH_APP_SHARED_PRIVATE_LINK_NAME')].name" -o tsv)

az network private-endpoint-connection approve -g $RESOURCE_GROUP -n $PRIVATE_LINK_NAME --resource-name $WEB_API_NAME --type $SITES_TYPE --description "Approved"

azd env get-values > .env && azd env get-values > ./web_api/.env
