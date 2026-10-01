# Azure Deployment Plan

## 1. Status

**Status:** Deployed

The user explicitly requested deployment to the existing resource group `rg-wus2-im-hackathon-01` in `westus2`.

## 2. Deployment Target

- **Mode:** Deploy existing Bicep infrastructure
- **Recipe:** Bicep with Azure CLI
- **Scope:** Existing resource group
- **Resource group:** `rg-wus2-im-hackathon-01`
- **Search and Storage location:** `westus2`
- **Foundry and model location:** `westus3`
- **Subscription:** Sandbox (`814d43bd-0ce3-41cf-81ef-eef8ea4ddc3f`)

## 3. Infrastructure

- Microsoft Foundry account with system-assigned managed identity
- Default Foundry project with system-assigned managed identity
- `gpt-5-mini` model deployment
- `text-embedding-3-large` model deployment
- Azure AI Search with local authentication disabled
- Storage account with shared-key authentication disabled
- Blob container `project-aurora`
- Foundry-to-Search Entra ID connection
- Managed identity role assignments for Search and Storage

## 4. Deployment Inputs

- Template: `infra/main.bicep`
- Parameters: `infra/main.bicepparam`
- `location`: `westus2`
- `foundryLocation`: `westus3`
- Resource names derived from `namingPrefix` and a deterministic resource-group suffix

## 5. Execution Steps

1. Verify active Azure subscription and resource group location.
2. Verify deployment and role-assignment permissions.
3. Validate Bicep and parameter files.
4. Verify resource providers, regional model availability, and quota.
5. Run resource-group deployment validation and what-if.
6. Deploy incrementally to the existing resource group.
7. Verify provisioning states, identities, role assignments, project connection, and endpoints.

## 6. Risk and Recovery

- Deployment uses incremental resource-group mode and does not delete unrelated resources.
- Model deployment can fail if the selected region lacks model availability or quota.
- Role assignments can require several minutes to propagate.
- Recovery is to correct the failing parameter or permission and rerun the idempotent deployment.

## 7. Validation Proof

Preparation checks completed:

- Active subscription confirmed by the user: Sandbox (`814d43bd-0ce3-41cf-81ef-eef8ea4ddc3f`).
- Existing resource group verified in `westus2`; provisioning state is `Succeeded`.
- Resource group verified empty before deployment.
- Deploying user has `Owner` on the subscription.
- Required resource providers are registered.
- `AIServices` SKU `S0` is available.
- `gpt-5-mini` version `2025-08-07` and `text-embedding-3-large` version `1` with `GlobalStandard` are unavailable in `westus2` but available in `westus3`.
- User approved placing Foundry/models in `westus3` while keeping Search/Storage in `westus2`.

### All validation checks pass

- [x] Core validation: Azure CLI, authentication, Bicep build, ARM validation, and what-if
- [x] Bicep linting
- [x] Azure Policy validation
- [x] Static role assignment verification

### Validation results

Validation completed on 2026-09-30 UTC.

- `validate-deployment.ps1 -Scope group -ResourceGroup rg-wus2-im-hackathon-01 -Template .\infra\main.bicep -Parameters .\infra\main.bicepparam -Subscription 814d43bd-0ce3-41cf-81ef-eef8ea4ddc3f`
  - Azure CLI installed: PASS
  - Authenticated to subscription `Sandbox`: PASS
  - Bicep compilation: PASS
  - ARM resource-group validation: PASS
  - What-if: PASS — Create 10, Modify 0, Delete 0
  - Overall: PASS
- `az bicep lint --file .\infra\main.bicep`
  - Exit code 0; no lint findings.
- `az bicep build --file .\infra\main.bicep --stdout`
  - Exit code 0.
- `az bicep build-params --file .\infra\main.bicepparam --stdout`
  - Exit code 0.
- `az policy assignment list --scope /subscriptions/814d43bd-0ce3-41cf-81ef-eef8ea4ddc3f/resourceGroups/rg-wus2-im-hackathon-01 --disable-scope-strict-match true`
  - No applicable policy assignments returned.
- Static RBAC review:
  - Search system identity receives `Storage Blob Data Reader` scoped to the Storage account.
  - Foundry account and project identities receive `Search Index Data Contributor` and `Search Service Contributor`, scoped to the Search service.
  - All assignments use managed identity service principals and resource-level scopes.

## 8. Deployment Result

- Deployment `foundry-hackathon-20260930-r2` completed successfully on 2026-09-30 UTC.
- An initial attempt encountered a transient Cognitive Services parent-resource conflict because child resources were submitted concurrently. The Foundry module was corrected to serialize project, model, and connection creation before the successful retry.
- Live verification confirmed:
  - Foundry account and project identities are provisioned.
  - Both requested model deployments are `Succeeded` with `GlobalStandard`.
  - Search and Foundry local authentication are disabled.
  - Storage shared-key authentication and blob public access are disabled.
  - The `project-aurora` container exists with public access set to `None`.
  - The Foundry Search connection uses `AAD` with workspace managed identity.
  - Search has `Storage Blob Data Reader` on Storage.
  - Foundry account and project identities have the required Search roles.

## 9. Network Security Perimeter Update

The user approved an incremental update to:

1. Create a Network Security Perimeter in `rg-wus2-im-hackathon-01`.
2. Create an NSP profile and inbound access rule allowing `162.233.6.221/32`.
3. Associate Storage account `aurorasty3gh6n` with the NSP profile.
4. Preserve Microsoft Entra ID-only data access and existing managed-identity integrations.
5. Validate with Bicep build, ARM validation, policy review, and what-if before redeployment.

This update must not delete or recreate the existing Foundry, Search, Storage, model, project, or connection resources.

Implementation detail: the Storage association uses `Enforced` mode. In addition to the requested `162.233.6.221/32` rule, the profile includes an inbound subscription rule for `/subscriptions/814d43bd-0ce3-41cf-81ef-eef8ea4ddc3f` so the existing Azure AI Search managed-identity indexer path is not blocked. Storage still requires Entra ID authorization and grants Blob read access only to the Search identity.

### NSP update validation

- [x] 1. Core Validation (CLI, auth, build, validate, what-if)
- [x] 2. Linting
- [x] 3. Azure Policy Validation

### NSP update validation proof

Validation completed on 2026-09-30 UTC.

- `validate-deployment.ps1 -Scope group -ResourceGroup rg-wus2-im-hackathon-01 -Template .\infra\main.bicep -Parameters .\infra\main.bicepparam -Subscription 814d43bd-0ce3-41cf-81ef-eef8ea4ddc3f`
  - Azure CLI installed: PASS
  - Authenticated to subscription `Sandbox`: PASS
  - Bicep compilation: PASS
  - ARM resource-group validation: PASS
  - What-if execution: PASS
- Resource-ID-only what-if:
  - Creates exactly five NSP resources: perimeter, profile, two inbound rules, and the Storage association.
  - Existing declared resources are redeployed incrementally.
  - Deletes: 0
  - Five existing role assignments are reported as `Unsupported` because their IDs depend on managed-identity principal IDs resolved during deployment; their definitions and deterministic names are unchanged.
- `az bicep build`, `az bicep build-params`, and `az bicep lint`: PASS.
  - Bicep reports `BCP081` warnings because local type definitions for the `2025-09-01` NSP API are not yet included; Azure Resource Manager validation accepted all resource schemas.
- Azure Policy assignments applicable to the resource group: none.
- Static RBAC verification:
  - Search retains `Storage Blob Data Reader` scoped to Storage.
  - Foundry account and project identities retain Search data and service contributor roles scoped to Search.
  - No role uses resource-group or subscription scope.

### NSP update deployment result

- Deployment `foundry-hackathon-nsp-20260930-095740` completed successfully on 2026-09-30 UTC.
- Created Network Security Perimeter `aurora-nsp-y3gh6n` in `westus2`.
- Created profile `storage`.
- Created inbound IP rule `allow-client-ip` with exactly `162.233.6.221/32`; provisioning state is `Succeeded`.
- Created inbound subscription rule `allow-workload-subscription` for `/subscriptions/814d43bd-0ce3-41cf-81ef-eef8ea4ddc3f`; provisioning state is `Succeeded`.
- Associated Storage account `aurorasty3gh6n` in `Enforced` mode; provisioning state is `Succeeded` and `hasProvisioningIssues` is `no`.
- Storage now reports:
  - `publicNetworkAccess: SecuredByPerimeter`
  - `allowSharedKeyAccess: false`
  - `defaultToOAuthAuthentication: true`
  - Network ACL default action `Deny` with no trusted-service bypass
- Live RBAC verification:
  - Search identity `f96a6a65-9095-4023-9630-949c1f191b73` has `Storage Blob Data Reader` scoped to Storage.
  - Foundry account identity has `Search Service Contributor` and `Search Index Data Contributor` scoped to Search.
  - Foundry project identity has `Search Service Contributor` and `Search Index Data Contributor` scoped to Search.
- Existing resources remain healthy:
  - Foundry provisioning state `Succeeded`; local authentication disabled.
  - Search state `running`; local authentication disabled.
  - `gpt-5-mini` and `text-embedding-3-large` provisioning states `Succeeded`.

## 10. Storage Managed Identity Remediation

The user approved an incremental update to enable a system-assigned managed identity on Storage account `aurorasty3gh6n`.

1. Add `identity.type: SystemAssigned` to the Storage account Bicep resource.
2. Preserve the existing enforced NSP association, IP rule, subscription rule, and Storage security settings.
3. Do not grant roles to the Storage identity because the Storage account does not initiate access to another protected service.
4. Validate with Bicep build, ARM validation, policy review, and a deletion-safe what-if.
5. Redeploy incrementally and verify:
   - Storage has a system-assigned principal ID.
   - NSP association remains `Enforced` and `Succeeded`.
   - The `MissingIdentityConfiguration` diagnostic clears after Azure reevaluates the association.
   - Search-to-Storage and Foundry-to-Search RBAC remains unchanged.

### Storage identity validation

- [x] 1. Core Validation (CLI, auth, build, validate, what-if)
- [x] 2. Linting
- [x] 3. Azure Policy Validation

### Storage identity validation proof

Validation completed on 2026-09-30 UTC.

- Azure CLI authentication, Bicep compilation, ARM resource-group validation, and what-if: PASS.
- Full-payload what-if confirms the only concrete Storage account change is:
  - Create `identity` with `type: SystemAssigned`.
- Resource-ID-only what-if reports no resource deletions or creations.
- Bicep build, parameter build, and lint: PASS.
- Existing `BCP081` warnings remain limited to missing local type definitions for the accepted NSP `2025-09-01` API.
- Applicable Azure Policy assignments: none.
- RBAC review: existing Search and Foundry assignments are unchanged; no role is assigned to the new Storage identity because it does not access another service.

### Storage identity deployment result

- Deployment `foundry-hackathon-storage-identity-20260930-101312` completed successfully on 2026-09-30 UTC.
- Storage account `aurorasty3gh6n` now has a system-assigned identity:
  - Principal ID: `2f11cbaa-6c0b-439b-8ece-37e581532951`
  - Tenant ID: `6bce265c-0737-497f-91eb-3bb05906ec9d`
- Storage remains `SecuredByPerimeter` with shared-key authentication disabled.
- Storage-side NSP configuration reports `Succeeded`.
- NSP association remains `Enforced`, `Succeeded`, and reports no provisioning issues.
- Both inbound rules remain unchanged and `Succeeded`.
- Search retains `Storage Blob Data Reader` scoped to Storage.
- Foundry account and project identities retain the required Search roles.
- The portal-computed `MissingIdentityConfiguration` issue should clear after refreshing the associated-resource view and allowing diagnostic propagation.

## 11. Search-to-Foundry RBAC Update

The user approved an incremental RBAC update for Azure AI Search identity `f96a6a65-9095-4023-9630-949c1f191b73`.

1. Grant `Cognitive Services OpenAI User` to the Search managed identity, scoped to Foundry account `aurora-foundry-y3gh6n`.
2. Grant `Cognitive Services User` to the Search managed identity at the same Foundry account scope.
3. Use deterministic role-assignment names and built-in role definition IDs.
4. Preserve all existing Foundry, Search, Storage, NSP, model, connection, and RBAC configuration.
5. Validate with Bicep build, ARM validation, policy review, and a deletion-safe what-if.
6. Redeploy incrementally and verify both roles exist for the live Search principal.

### Search-to-Foundry RBAC validation

- [x] 1. Core Validation (CLI, auth, build, validate, what-if)
- [x] 2. Linting
- [x] 3. Azure Policy Validation

### Search-to-Foundry RBAC validation proof

Validation completed on 2026-09-30 UTC.

- Azure CLI authentication, Bicep compilation, ARM validation, and what-if: PASS.
- Resource-ID-only what-if reports no deletions.
- The two new Foundry-scoped assignments appear as expected what-if `Unsupported` entries because their deterministic names include the Search principal ID resolved during deployment:
  - `Cognitive Services OpenAI User` (`5e0bd9bd-7b93-4f28-af87-19fc36ad61bd`)
  - `Cognitive Services User` (`a97b65f3-24c7-4388-baec-2e87135dc908`)
- Live predeployment check confirms the Search identity currently has no roles on the Foundry account.
- Bicep build, parameter build, and lint: PASS.
- Applicable Azure Policy assignments: none.
- Static RBAC verification confirms both new assignments:
  - Use `principalType: ServicePrincipal`.
  - Target the Search system identity.
  - Are scoped directly to the Foundry account.
- Existing role assignments and resource configuration remain unchanged.

### Search-to-Foundry RBAC deployment result

- Deployment `foundry-hackathon-search-foundry-rbac-20260930-125528` completed successfully on 2026-09-30 UTC.
- Search system identity `f96a6a65-9095-4023-9630-949c1f191b73` now has the following roles scoped directly to Foundry account `aurora-foundry-y3gh6n`:
  - `Cognitive Services OpenAI User`
  - `Cognitive Services User`
- Live role verification confirms both assignments and their expected built-in role definition IDs.
- Foundry remains `Succeeded`, public network access remains enabled, and local authentication remains disabled.
- Search remains `running` with local authentication disabled.
- The Storage NSP association remains `Enforced`, `Succeeded`, and reports no provisioning issues.
