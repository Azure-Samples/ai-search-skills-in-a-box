import os
import json
from pathlib import Path

from dotenv import load_dotenv
from azure.identity import DefaultAzureCredential
from azure.search.documents.indexes import SearchIndexerClient, SearchIndexClient
from azure.search.documents.indexes.models import (
    SearchIndexerSkillset,
    SearchIndexerDataSourceConnection,
    SearchIndexerDataContainer,
    SearchIndex,
    SearchIndexer
)

load_dotenv()


search_service_name = os.getenv('SEARCH_SERVICE_NAME')
search_data_source_connection = os.getenv('SEARCH_DATA_SOURCE_CONNECTION')
search_container = os.getenv('SEARCH_DATA_SOURCE_CONTAINER')
web_api_endpoint = 'https://{}/api/classify'.format(os.getenv('WEB_API_URL'))


search_endpoint = 'https://{}.search.windows.net'.format(search_service_name)
audience = "https://search.windows.net"

skill_set_name = '{}-skillset'.format(search_service_name)
data_source_name = '{}-datasource'.format(search_service_name)
index_name = '{}-index'.format(search_service_name)
indexer_name = '{}-indexer'.format(search_service_name)


def get_config(filename: str) -> dict:
    path = Path(__file__).parent
    fp = open('{}/config/{}'.format(path, filename))
    return json.load(fp)


class IndexManager:
    def __init__(self, credential: DefaultAzureCredential):
        self.index_client = SearchIndexClient(endpoint=search_endpoint, credential=credential)
        self.indexer_client = SearchIndexerClient(endpoint=search_endpoint, credential=credential)

    def setup(self):
        self.__setup_data_source()
        self.__setup_index()
        self.__setup_skill_set()
        self.__setup_indexer()

    def __setup_skill_set(self):
        skill_set = get_config('skill_set.json')

        set_custom_skill_url(skill_set['skills'], 'web_api_skill', web_api_endpoint)
        set_projection_index(skill_set['indexProjections'])

        skill_set = SearchIndexerSkillset(
            name=skill_set_name,
            skills=skill_set['skills'],
            description='',
            cognitive_services_account=None,
            knowledge_store=None,
            index_projection=skill_set['indexProjections'],
            e_tag=None,
            encryption_key=None
        )
        self.indexer_client.create_or_update_skillset(skill_set)

    def __setup_data_source(self):
        datasource = SearchIndexerDataSourceConnection(
            name=data_source_name,
            description='',
            type='azureblob',
            connection_string=search_data_source_connection,
            container=SearchIndexerDataContainer(name=search_container),
            data_change_detection_policy=None,
            data_deletion_detection_policy=None,
            e_tag=None,
            encryption_key=None,
        )
        self.indexer_client.create_or_update_data_source_connection(datasource)

    def __setup_index(self):
        index_json = get_config('index.json')
        index = SearchIndex(
            name=index_name,
            fields=index_json['fields'],
            scoring_profiles=index_json.get('scoringProfiles'),
            default_scoring_profile=index_json.get('defaultScoringProfile'),
            cors_options=index_json.get('corsOptions'),
            suggesters=index_json.get('suggesters'),
            analyzers=index_json.get('analyzers'),
            tokenizers=index_json.get('tokenizers'),
            token_filters=index_json.get('tokenFilters'),
            char_filters=index_json.get('charFilters'),
            encryption_key=index_json.get('encryptionKey'),
            similarity=index_json.get('similarity'),
            semantic_search=index_json.get('semanticSearch'),
            vector_search=index_json.get('vectorSearch'),
            e_tag=index_json.get('eTag')
        )

        self.index_client.create_or_update_index(index)

    def __setup_indexer(self):
        indexer_json = get_config('indexer.json')
        indexer = SearchIndexer(
            name=indexer_name,
            data_source_name=data_source_name,
            target_index_name=index_name,
            description=indexer_json.get('description'),
            skillset_name=skill_set_name,
            schedule=indexer_json.get('schedule'),
            parameters=indexer_json.get('parameters'),
            field_mappings=indexer_json.get('fieldMappings'),
            output_field_mappings=indexer_json.get('outputFieldMappings'),
            is_disabled=indexer_json.get('isDisabled'),
            e_tag=indexer_json.get('eTag'),
            encryption_key=indexer_json.get('encryptionKey'),
        )
        self.indexer_client.create_or_update_indexer(indexer)


def set_custom_skill_url(skills: dict, skill_name: str, url: str):
    for skill in skills:
        if skill['@odata.type'] == '#Microsoft.Skills.Custom.WebApiSkill' and skill['name'] == skill_name:
            skill['uri'] = url
            break


def set_projection_index(index_projections: list):
    for selector in index_projections['selectors']:
        selector['targetIndexName'] = index_name


if __name__ == "__main__":
    credential = DefaultAzureCredential()
    manager = IndexManager(credential=credential)

    manager.setup()
