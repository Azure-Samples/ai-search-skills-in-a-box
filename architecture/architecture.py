from diagrams import Diagram, Cluster
from diagrams.azure.ml import CognitiveServices
from diagrams.azure.network import VirtualNetworks, VirtualNetworkClassic
from diagrams.azure.web import Search
from diagrams.azure.compute import FunctionApps
from diagrams.azure.database import BlobStorage


import os
os.environ["PATH"] += os.pathsep + 'C:\Program Files\Graphviz/bin/'

if __name__ == "__main__":
    with Diagram("AI Search Custom Skill Architecture", show=False):

        with Cluster("Search Managed Virtual Network"):
            search = Search('AI Search')
            searchPL = VirtualNetworkClassic("Private Link")
            search >> searchPL

        with Cluster("Virtual Network"):
            with Cluster("Subnet"):
                app = FunctionApps('FunctionApp')

                storageSE = VirtualNetworks('Service Endpoint')
                openaiSE = VirtualNetworks('Service Endpoint')

                app >> storageSE
                app >> openaiSE

        storage = BlobStorage('Storage')
        openai = CognitiveServices("OpenAI")

        searchPL >> app
        storageSE >> storage
        openaiSE >> openai
