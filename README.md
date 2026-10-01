# Microsoft Foundry Hackathon Infrastructure

This Bicep project deploys into an existing, clean Azure resource group:

- A Microsoft Foundry (`AIServices`) account with local/key authentication disabled.
- A default Foundry project with a system-assigned managed identity.
- `gpt-5-mini` and `text-embedding-3-large` model deployments.
- Azure AI Search with a system-assigned managed identity and API keys disabled.
- A StorageV2 account with shared-key authentication disabled.
- A private `project-aurora` blob container.
- A Network Security Perimeter with an enforced Storage association.
- An inbound `/32` NSP access rule for `162.233.6.221`.
- A subscription inbound rule so Azure AI Search can continue reading Storage with managed identity.
- A system-assigned Storage identity to satisfy NSP identity configuration requirements.
- Foundry account access for the Search managed identity through `Cognitive Services OpenAI User` and `Cognitive Services User`.
- A Log Analytics workspace with 30-day retention.
- A workspace-based Application Insights resource with local authentication disabled.
- A shared Foundry monitoring connection to Application Insights, exposed at both account and project scopes.
- A project-scoped Azure AI Search connection that uses Microsoft Entra ID.
- RBAC assignments that allow Search to read blobs and Foundry to manage/query Search.

Public endpoints remain available for the Foundry and Search resources. Storage public endpoint access is governed by the Network Security Perimeter. Authentication and authorization among services use Microsoft Entra ID and managed identities only.

The Storage account's NSP association is in `Enforced` mode. NSP rules become the top-level network gate: the configured client IP and resources from this subscription can reach the public Storage endpoint, but data-plane access still requires Microsoft Entra authorization.

The Storage identity is enabled for NSP intra-perimeter identity compliance. It has no role assignments because Storage does not initiate access to another service in this architecture.

The Search system identity is authorized on the Foundry account for model inference and Cognitive Services access. These role assignments are scoped directly to the Foundry account.

Foundry server-side tracing uses the project managed identity to publish telemetry to Application Insights. The account-level connection is shared to the project and uses `ProjectManagedIdentity`; Foundry exposes the same connection through the project connection path. The project identity has `Monitoring Metrics Publisher`, `Log Analytics Reader`, and `Privileged Monitoring Data Reader` scoped directly to the Application Insights resource.

## Structure

```text
.
|-- .azure/
|   |-- insights.json
|   `-- infrastructure-plan.json
|-- infra/
|   |-- main.bicep
|   |-- main.bicepparam
|   `-- modules/
|       |-- foundry.bicep
|       |-- monitoring.bicep
|       |-- network-security-perimeter.bicep
|       |-- rbac.bicep
|       |-- search.bicep
|       `-- storage.bicep
`-- README.md
```

## Prerequisites

- Azure CLI with Bicep support.
- Permission to create resources and role assignments in the target resource group.
- Model quota and availability for `gpt-5-mini` and `text-embedding-3-large` in the selected model location.
- Registered resource providers: `Microsoft.CognitiveServices`, `Microsoft.Search`, `Microsoft.Storage`, and `Microsoft.Authorization`.

## Configure

Edit `infra/main.bicepparam`. Search and Storage use `location`, which defaults to the resource group's location. Foundry, the project, and model deployments use `foundryLocation`. The supplied parameter file keeps Search and Storage in `westus2` and places Foundry in `westus3`, where both requested models are available.

Resource names are derived from `namingPrefix` and a deterministic suffix based on the subscription and resource group. Model versions, deployment SKUs, capacities, Search SKU, and Semantic Search plan are parameters.

## Validate

```powershell
az bicep build --file .\infra\main.bicep
```

## Preview

```powershell
az deployment group what-if `
  --resource-group <resource-group-name> `
  --template-file .\infra\main.bicep `
  --parameters .\infra\main.bicepparam
```

## Deploy

```powershell
az deployment group create `
  --name foundry-hackathon `
  --resource-group <resource-group-name> `
  --template-file .\infra\main.bicep `
  --parameters .\infra\main.bicepparam
```

## Create an Azure AI Search Blob data source without keys

The Search service identity receives `Storage Blob Data Reader` on the Storage account. When creating the Search data source, use the Storage resource ID rather than an account key:

```json
{
  "name": "project-aurora",
  "type": "azureblob",
  "credentials": {
    "connectionString": "ResourceId=/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.Storage/storageAccounts/<storage-account-name>;"
  },
  "container": {
    "name": "project-aurora"
  }
}
```

Role assignments can take several minutes to propagate after deployment.
