# Terraform State and GitHub OIDC Bootstrap

This independent configuration creates the minimum Azure state backend and the
GitHub deployment identity. Its local state must remain separate from the root
landing-zone state that depends on these resources.

## Managed resources

- one resource group;
- one Standard LRS StorageV2 account with shared keys disabled;
- one private blob container with versioning and seven-day soft deletion;
- one Microsoft Entra application and service principal;
- federated credentials for the `demo-plan` and `demo-apply` GitHub environments;
- `Storage Blob Data Contributor` for the GitHub service principal;
- optional `Storage Blob Data Contributor` for the identity running bootstrap.

No application password or client secret is created. GitHub exchanges its OIDC
token directly with Microsoft Entra ID. Entra objects, federated credentials,
and RBAC assignments do not have a separate service charge; the small LRS
storage account is the only material new backend cost.

## Authentication and permissions

Run bootstrap interactively with Azure CLI authentication:

```powershell
az login
az account set --subscription <subscription-id>
```

The current identity is discovered with `data.azurerm_client_config.current`;
no user object ID belongs in tfvars. It needs permission to create the backend
resources and Azure role assignments. It must also be allowed to register Entra
applications; tenants that disable ordinary app registration require an
Application Administrator to run this bootstrap.

## One-time bootstrap

Copy the example and set only environment configuration:

```powershell
Copy-Item terraform/bootstrap-state/terraform.tfvars.example terraform/bootstrap-state/terraform.tfvars
terraform -chdir=terraform/bootstrap-state init
terraform -chdir=terraform/bootstrap-state fmt -check
terraform -chdir=terraform/bootstrap-state plan -out=tfplan
# Run only when intentionally creating the backend and GitHub identity:
terraform -chdir=terraform/bootstrap-state apply tfplan
```

After apply, retrieve the non-secret configuration:

```powershell
terraform -chdir=terraform/bootstrap-state output
terraform -chdir=terraform/bootstrap-state output -raw github_oidc_client_id
terraform -chdir=terraform/bootstrap-state output -raw github_service_principal_object_id
```

Configure GitHub once from the outputs:

| Bootstrap output | GitHub setting |
|---|---|
| `github_oidc_client_id` | Secret `AZURE_CLIENT_ID` |
| `tenant_id` | Secret `AZURE_TENANT_ID` |
| `subscription_id` | Secret `AZURE_SUBSCRIPTION_ID` |
| `github_service_principal_object_id` | Variable `AZURE_PRINCIPAL_OBJECT_ID` |
| `backend_resource_group_name` | Variable `TFSTATE_RESOURCE_GROUP` |
| `backend_storage_account_name` | Variable `TFSTATE_STORAGE_ACCOUNT` |
| `backend_container_name` | Variable `TFSTATE_CONTAINER` |
| `backend_state_key` | Variable `TFSTATE_KEY` |

`AZURE_PRINCIPAL_OBJECT_ID` is used for the deployment identity's AKS Azure
RBAC assignment; it is not used to configure backend access. Backend RBAC
references the managed service principal directly.

The deployment identity still needs appropriately scoped Azure management-plane
roles for the resources deployed by the root configuration. Those roles are a
separate one-time authorization decision and are not broadened by this backend
bootstrap.

Keep the bootstrap's small local state secured and backed up. It cannot use the
backend whose creation it records. Migrate only the landing-zone root state to
the new container.
