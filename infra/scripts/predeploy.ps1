$STORAGE_NAME = (azd env get-value STORAGE_NAME)
$DATA_SOURCE_CONTAINER = (azd env get-value SEARCH_DATA_SOURCE_CONTAINER)

az storage blob upload-batch -d $DATA_SOURCE_CONTAINER -s ./assets/index_files --account-name $STORAGE_NAME --auth-mode login --overwrite
