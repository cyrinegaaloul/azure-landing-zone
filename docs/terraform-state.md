# Terraform State

The landing-zone root uses Azure Blob Storage through the `azurerm` backend.
Azure Blob leasing supplies state locking. Blob versions and soft deletion
provide recovery, while Microsoft Entra data-plane RBAC replaces account keys.

## Authentication

The bootstrap discovers the current `az login` identity automatically and can
grant it `Storage Blob Data Contributor`. It also creates the GitHub Entra
application, service principal, two environment-scoped federated credentials,
and the GitHub principal's backend role assignment. No object IDs are supplied
through bootstrap tfvars.

After bootstrap, initialize the root with:

```powershell
Copy-Item terraform/root/backend.dev.hcl.example terraform/root/backend.dev.hcl
terraform -chdir=terraform/root init -migrate-state -backend-config=backend.dev.hcl
```

GitHub Actions uses the Terraform-managed federated OIDC credentials through
`azure/login` and the backend's `use_oidc` and `use_azuread_auth` settings. The
same state key, `development/azure-landing-zone.tfstate`, is used locally and in
automation. Bootstrap outputs provide the GitHub client ID, tenant,
subscription, service-principal object ID, and backend names.

The first root initialization must use `-migrate-state` to copy the existing
local state. Verify `terraform state list` against the remote backend before
archiving the local state and backup files. Do not use `-reconfigure` for that
first migration because it would select an empty backend without copying state.

Do not commit storage keys, state files, binary plans, or the local backend
file. The bootstrap stack is separate because a backend cannot reliably create
the storage on which its own state depends.

## Cost and network boundary

Standard LRS storage for a small state blob is low/negligible cost. The
resource group, container, and RBAC assignments have no meaningful independent
charge. GitHub-hosted runners require a publicly reachable blob endpoint; the
container remains private, shared-key authentication is disabled, and Entra
RBAC is required. A future private runner could justify a storage private
endpoint, but it is outside this internship scope.
