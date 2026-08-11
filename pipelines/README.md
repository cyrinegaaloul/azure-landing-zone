# CI/CD Pipelines

The repository uses two GitHub Actions workflows. Image publication is part of
validation, so an image cannot bypass the checks that evaluated it.

## Workflows

| Workflow | Trigger | Function |
|---|---|---|
| `validate-build-publish` | Pull request and push to `main` | Validate code/configuration, build once, scan, generate an SBOM, and publish the exact SHA image only on `main`. |
| `controlled-demo-deployment` | Manual dispatch from `main` | Plan against persistent state, optionally apply the reviewed plan, render deployment values, deploy, and smoke-test. |

### CI gate

The validation order is Terraform formatting/validation, Terraform Trivy scan,
Python tests, Kustomize/kubeconform, Kubernetes Trivy scan, YAML/JSON parsing,
Docker build, image scan, SBOM generation, and conditional push.

The image is tagged `ghcr.io/<owner>/landing-zone-demo-app:<git-sha>`. It is
built once and scanned locally before `docker push`. Pull requests have no
publish step. HIGH/CRITICAL vulnerabilities are reported; fixable
HIGH/CRITICAL vulnerabilities fail the image gate. Terraform and Kubernetes
HIGH/CRITICAL misconfigurations fail their gates.

### Controlled deployment

Workflow concurrency prevents simultaneous state operations. `plan` produces a
saved plan and a readable plan artifact. `apply` and `destroy` generate the
saved plan in the same run, pause at the protected `demo-apply` environment,
then apply that exact binary plan. Pull requests never deploy.

Full/secure apply also:

- pulls the image for the selected commit and resolves its registry digest;
- reads AKS, identity, network, Key Vault, and edge Terraform outputs;
- renders an untracked manifest with `scripts/render-kubernetes.ps1`;
- installs `kube-prometheus-stack` chart `86.0.1` and applies monitoring config;
- applies the rendered application, waits for rollout, and smoke-tests
  `http://<application-gateway-ip>/demo/health`.

## GitHub configuration

Create protected environments `demo-plan` and `demo-apply`. Require a reviewer
for `demo-apply`.

Repository/environment secrets:

| Name | Value |
|---|---|
| `AZURE_CLIENT_ID` | Application/client ID of the GitHub OIDC identity. |
| `AZURE_TENANT_ID` | Microsoft Entra tenant ID. |
| `AZURE_SUBSCRIPTION_ID` | Target Azure subscription ID. |

Repository/environment variables:

| Name | Required | Value |
|---|---:|---|
| `TFSTATE_RESOURCE_GROUP` | Yes | Backend resource group name. |
| `TFSTATE_STORAGE_ACCOUNT` | Yes | Backend storage account name. |
| `TFSTATE_CONTAINER` | Yes | `tfstate`. |
| `TFSTATE_KEY` | Yes | `development/azure-landing-zone.tfstate`. |
| `AZURE_PRINCIPAL_OBJECT_ID` | Full profile | Object ID, not client ID, of the GitHub OIDC service principal for AKS RBAC. |
| `PLATFORM_ADMIN_GROUP_OBJECT_ID` | Optional | Platform administrators Entra group object ID. |
| `NETWORK_OPERATOR_GROUP_OBJECT_ID` | Optional | Network operators Entra group object ID. |
| `SECURITY_READER_GROUP_OBJECT_ID` | Optional | Security readers Entra group object ID. |
| `KEY_VAULT_BOOTSTRAP_PRINCIPAL_OBJECT_ID` | Bootstrap only | Human object ID temporarily granted Key Vault Secrets Officer. |

The bootstrap configuration creates the GitHub Entra application, service
principal, `demo-plan`/`demo-apply` federated credentials, and its `Storage Blob
Data Contributor` backend assignment. Copy the bootstrap outputs once into the
settings above. No client secret or `AZURE_CREDENTIALS` is required.

For the first landing-zone deployment, the automation principal needs
`Contributor` to create resources and `Role Based Access Control Administrator`
to create the scoped role assignments represented in Terraform. Scope these as
narrowly as the bootstrap process permits and reduce them to the three managed
resource groups after those groups exist. It never needs Owner. The two GitHub
environment-specific OIDC trusts are already owned by bootstrap Terraform.

After the bootstrap profile is applied and RBAC has propagated, the designated
human creates `demo-secret` directly in the Azure portal. Do not pass the value
through Terraform, GitHub, shell history, or a committed file. Then apply
`full`; Terraform removes the temporary Secrets Officer assignment, creates the
private endpoint, and disables public vault access.

## Profiles and lifecycle

- `core`: non-billable optional application components off.
- `key-vault-bootstrap`: Key Vault only, temporarily public for secret creation.
- `full`: complete private-vault application path, WAF Detection, locks off.
- `secure`: same path, WAF Prevention, network/security RG locks on.

To destroy after the secure profile, first apply `full` to remove locks, then
dispatch `destroy` with `full`. GitHub token permissions are limited to content
read, OIDC token creation, GHCR read during deploy, and GHCR write only in CI.
