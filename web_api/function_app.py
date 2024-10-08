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
system_message = '''Please classify the text into one of the following categories: 
- Politics
- Sports 
- Entertainment
- Technology
- Business
- Health

Below are some example texts for classification:

Text: The new healthcare reform bill has sparked debate in Congress.
Class: Politics

Text: A recent election has led to significant changes in the government.
Class: Politics

Text: The championship game ended with a thrilling last-minute goal.
Class: Sports

Text: The underdog team won the rugby final in a historic upset.
Class: Sports

Text: The latest blockbuster movie has broken box office records.
Class: Entertainment

Text: A popular music festival drew record crowds this weekend.
Class: Entertainment

Text: A breakthrough in AI research promises new advancements.
Class: Technology

Text: Quantum computing is set to revolutionize various industries.
Class: Technology

Text: A major acquisition in the tech industry has been announced.
Class: Business

Text: The retail giant launched an innovative sustainability initiative.
Class: Business

Text: A new vaccine shows promise in fighting infectious diseases.
Class: Health

Text: Researchers have developed a new therapy for cancer treatment.
Class: Health

Below the text you should classify:
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
