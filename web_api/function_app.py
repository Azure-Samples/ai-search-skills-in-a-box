import logging
import json
import os

import azure.functions as func
from azure.identity import DefaultAzureCredential, get_bearer_token_provider
from openai import AzureOpenAI
from dotenv import load_dotenv

load_dotenv()

credential = DefaultAzureCredential()
client = AzureOpenAI(
    api_version="2024-02-01",
    azure_ad_token_provider=get_bearer_token_provider(DefaultAzureCredential(), "https://cognitiveservices.azure.com/.default"),
    azure_endpoint=os.getenv('AZURE_OPENAI_ENDPOINT')
)

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

deployment_name = os.getenv('AZURE_OPENAI_CHAT_DEPLOYMENT_NAME')
system_message = '''You are an assistant that needs to classify the user input into the following categories
- Public
- Private
- Unknown
'''

@app.route(route="classify", methods=['POST'])
def classify(req: func.HttpRequest) -> func.HttpResponse:
    try:
        payload = req.get_json()

        logging.info('Python HTTP trigger function processed a request.')

        values = []
        for value in payload['values']:
            response = client.chat.completions.create(
                model=deployment_name,
                messages=[
                    {'role': 'system', 'content': system_message},
                    {'role': 'user', 'content': value['data']['text']}
                ])

            values.append({
                'recordId': value['recordId'],
                'data': {
                    'classification': response.choices[0].message.content
                }
            })

        return func.HttpResponse(body=json.dumps({'values': values}), mimetype='application/json')
    except Exception as ex:
        return func.HttpResponse(body=str(ex), status_code=500)
