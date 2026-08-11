# Terraform State Bootstrap

This independent configuration creates the minimum Azure resources required by
the root `azurerm` backend. Its state must not be migrated into the landing-zone
state that depends on it.

## Resources

- one resource group;
- one Standard LRS StorageV2 account with shared keys disabled;
- one private blob container;
- optional `Storage Blob Data Contributor` assignments.

Blob versioning and seven-day soft deletion provide low-cost recovery. The
storage account has `prevent_destroy`. Its public data endpoint remains enabled
for GitHub-hosted runners, but access requires Microsoft Entra authorization.

## One-time bootstrap

Copy `terraform.tfvars.example` to ignored `terraform.tfvars`, add the real
subscription and principal object IDs, then authenticate and review a plan:

```powershell
az login
terraform -chdir=terraform/bootstrap-state init
terraform -chdir=terraform/bootstrap-state fmt -check
terraform -chdir=terraform/bootstrap-state plan -out=tfplan
terraform -chdir=terraform/bootstrap-state apply tfplan
```

The apply command is intentionally manual and must be run only when creating
the backend. It is not run by repository validation. Copy the output names into
GitHub variables and an ignored root backend configuration file.

Keep the bootstrap configuration's small local state secured and backed up; it
cannot store its own creation state in the backend it is responsible for
creating. Migrate only the landing-zone root state into the new container.
