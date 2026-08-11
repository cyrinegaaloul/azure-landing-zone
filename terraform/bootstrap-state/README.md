# Terraform State and GitHub OIDC Bootstrap

This independent configuration creates the minimum Azure state backend and the
GitHub deployment identity. Its local state must remain separate from the root
landing-zone state that depends on these resources.

## Managed resources

- one resource group;
- one Standard LRS StorageV2 account with shared keys disabled;
- one private blob container with versioning and seven-day soft deletion;
- one dedicated user-assigned managed identity for GitHub Actions;
- two federated credentials for the `demo-plan` and `demo-apply` environments;
- `Storage Blob Data Contributor` for the GitHub managed identity;
- `Contributor` and `Role Based Access Control Administrator` for the GitHub
  managed identity at this subscription only;
- optional `Storage Blob Data Contributor` for the identity running bootstrap.

No app registration, application password, or client secret is created. The
user-assigned managed identity avoids tenant-level application-registration
permissions while retaining workload identity federation. Managed identities,
federated credentials, and RBAC assignments have no separate service charge;
the small LRS storage account is the only material backend cost.

## Authentication and permissions

Run bootstrap interactively with Azure CLI authentication:

```powershell
az login
az account set --subscription <subscription-id>
```

The current identity is discovered with `data.azurerm_client_config.current`;
no user object ID belongs in tfvars. It needs permission to create the backend
resources, managed identity, federated credentials, and Azure role assignments.
It does not need permission to register Microsoft Entra applications.

The GitHub identity receives `Contributor` because the root configuration
creates resource groups and Azure resources. It receives `Role Based Access
Control Administrator` because the root creates scoped assignments for AKS,
Key Vault, networking, and optional human groups. Subscription scope is the
narrowest practical initial scope because those resource groups do not exist
before the first root deployment. It is never granted `Owner`.

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
terraform -chdir=terraform/bootstrap-state output -raw github_managed_identity_principal_id
```

Configure GitHub once from the outputs:

| Bootstrap output | GitHub setting |
|---|---|
| `github_oidc_client_id` | Secret `AZURE_CLIENT_ID` |
| `tenant_id` | Secret `AZURE_TENANT_ID` |
| `subscription_id` | Secret `AZURE_SUBSCRIPTION_ID` |
| `github_managed_identity_principal_id` | Variable `AZURE_PRINCIPAL_OBJECT_ID` |
| `backend_resource_group_name` | Variable `TFSTATE_RESOURCE_GROUP` |
| `backend_storage_account_name` | Variable `TFSTATE_STORAGE_ACCOUNT` |
| `backend_container_name` | Variable `TFSTATE_CONTAINER` |
| `backend_state_key` | Variable `TFSTATE_KEY` |

`AZURE_PRINCIPAL_OBJECT_ID` is used for the GitHub managed identity's AKS Azure
RBAC assignment; it is not used to configure backend access. Backend RBAC
references the managed identity directly.

The GitHub-hosted runner uses this authentication path:

```text
GitHub OIDC token
  -> federated credential on the GitHub deployment UAMI
  -> Azure access token
  -> Azure RBAC
```

This GitHub UAMI is separate from the application UAMI in `04-workloads`. The
application identity trusts the AKS OIDC issuer and can read Key Vault secrets;
the GitHub identity trusts GitHub and runs Terraform deployment operations.

The existing resource group and storage-account Terraform addresses are
unchanged. If an earlier bootstrap apply created only those resources, the next
plan reconciles them in place and proposes only the missing container, managed
identity, federated credentials, and assignments. Review that plan before apply.
RBAC propagation can take several minutes; retry a failed container operation
after propagation rather than enabling shared-key authentication.

Before the next plan, verify the active state rather than assuming the backup is
current:

```powershell
terraform -chdir=terraform/bootstrap-state state list
```

The expected partial state contains `azurerm_resource_group.state` and
`azurerm_storage_account.state`. If Azure contains those resources but the
active state does not, import those two existing resources at their unchanged
addresses before planning. Do not delete or recreate them. Keep
`terraform.tfstate.backup` untouched until reconciliation has been verified.

Keep the bootstrap's small local state secured and backed up. It cannot use the
backend whose creation it records. Migrate only the landing-zone root state to
the new container.
