using './main.bicep'

param namingPrefix = 'aurora'
param projectName = 'project-aurora'

param location = 'westus2'
param foundryLocation = 'westus3'

param searchSkuName = 'basic'
param semanticSearch = 'free'

param gpt5MiniModelVersion = '2025-08-07'
param gpt5MiniDeploymentSku = 'GlobalStandard'
param gpt5MiniCapacity = 10

param embeddingModelVersion = '1'
param embeddingDeploymentSku = 'GlobalStandard'
param embeddingCapacity = 10
param storageAllowedIpAddress = '162.233.6.221'

param tags = {
  workload: 'foundry-hackathon'
  environment: 'demo'
  purpose: 'customer-hackathon'
}
