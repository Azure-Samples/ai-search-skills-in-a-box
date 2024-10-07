# AI-in-a-Box Accelerator Name

<!-- <div style="display: flex;">
  <div style="width: 70%;">
    This solution is part of the the AI-in-a-Box framework developed by the team of Microsoft Customer Engineers and Architects to accelerate the deployment of AI and ML solutions. Our goal is to simplify the adoption of AI technologies by providing ready-to-use accelerators that ensure quality, efficiency, and rapid deployment.
  </div>
  <div style="width: 30%;">
    <img src="./media/ai-in-a-box.png" alt="AI-in-a-box Project Logo: Description" style="width: 10%">
  </div>
</div> -->
**This part of the template is the base README for your AI in a Box solution, including user story, deployment, customizations, etc. Fill in the appropriate info for each subheading. For an example, see the [README-example](README-example.md) in this template. Don't forget to delete this paragraph :)**
|||
|:---| ---:|
|This solution is part of the the AI-in-a-Box framework developed by the team of Microsoft Customer Engineers and Architects to accelerate the deployment of AI and ML solutions. Our goal is to simplify the adoption of AI technologies by providing ready-to-use accelerators that ensure quality, efficiency, and rapid deployment.| <img src="./media/ai-in-a-box.png" alt="AI-in-a-box Logo: Description" style="width: 70%"> |

## User Story
<FRANKLIN - TODO>
This is the WHY

Insert a image here that tells an interesting story about the solution being delivered

Describe how this solution can help a user's organization, including  examples on how this solution could help specific industries

Describe what makes this solution and other reasons why someone would want to deploy this. Here's some ideas that you may wish to consider:

- **Speed and Efficiency**: How does this solution accelerate the deployment of AI/ML solutions?
- **Cost-Effectiveness**: In what ways does it help save on development costs?
- **Quality and Reliability**: What measures are in place to ensure the high quality and reliability of your solution?
- **Competitive Edge**: How does it give users a competitive advantage in their domain?

## What's in the Box
<img src="./architecture/ai_search_custom_skill_architecture.png" />

- Deployment templates of all resources needed, which includes:
  - [Azure Function App](https://learn.microsoft.com/en-us/azure/azure-functions/functions-overview)
  - [OpenAI Service and Deployment](https://azure.microsoft.com/en-us/products/ai-services/openai-service)
  - [Azure Storage](https://learn.microsoft.com/en-us/azure/storage/common/storage-introduction)
  - [AI Search](https://learn.microsoft.com/en-us/azure/search/search-what-is-azure-search)
  - [Virtual Network](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview)
- Resources are deployed and used with security best practices in mind
  - Azure Storage, AI Search, and OpenAI only supports identity authentication (no keys supported)
  - Azure Storage and OpenAI service can only be accessed through the virtual network service endpoint (no public access)
  - Azure Function App can only be accessed through a private endpoint (no public access)
  - Required RBAC roles are assigned so services can communicate with each other with the least privilege
- Python application that sets up Azure AI Search:
  - Setup data store
  - Setup skill set
  - Setup index
  - Setup indexer
- Python application that runs in Azure Function App:
  - Called by Azure AI Search when the indexer runs
  - Receives a text content as input
  - Sends the input to Azure OpenAI
  - Sends the response to Azure AI Search

## Thinking Outside of the Box
<FRANKLIN - TODO>

This is a WHY and a WHAT

Describe ways users can customize and enahance the solution for use inside their organization

## Deploy the Solution

### Deploy Pre-requisites
1. An [Azure subscription](https://azure.microsoft.com/en-us/free/)
2. Install [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows?view=azure-cli-latest)
3. Install [Bicep](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install)
4. Install [Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd)

### Azd Deploy
1. Clone this repository locally

    `git clone https://github.com/Azure-Samples/ai-search-skills-in-a-box/`  
2. Deploy resources

    `az login`

    `azd auth login`

    `azd up`

You will be prompted for:
- environment name
- azure subscription
- azure region (we suggest using `eastus2`)

### Setup AI Search
This step is required to set up the AI Search service with:
- Data store
- Index
- Skill set
- Indexer

1. Install requirements

    `pip install -r aisearch/requirements.txt`
2. Run the setup script

    `python aisearch/setup.py`

### Clean up
To remove all resources created by this solution, run:
    
`azd down`

## Run the Solution
<FRANKLIN - TODO>

Include instructions on how they can run and test the solution

## Customize the Solution
<FRANKLIN - TODO>

Describe different ideas on how to enhance or customize for their use cases

## How to Contribute

This project welcomes contributions and suggestions. Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit <https://cla.opensource.microsoft.com>

When you submit a pull request, a CLA bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq) or contact <opencode@microsoft.com> with any additional questions or comments.

## Key Contacts & Contributors

| Contact            | GitHub ID           | Email                    |
|--------------------|---------------------|--------------------------|
| Franklin Guimaraes | @franklinlindemebrg | fguimaraes@microsoft.com |

## License

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft trademarks or logos is subject to and must follow [Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general). Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship. Any use of third-party trademarks or logos are subject to those third-party's policies.

---

This project is part of the AI-in-a-Box series, aimed at providing the technical community with tools and accelerators to implement AI/ML solutions efficiently and effectively.
