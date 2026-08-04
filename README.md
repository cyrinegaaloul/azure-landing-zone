# Azure Landing Zone with AKS

This repository implements a modular Azure landing zone with conditional AKS,
Application Gateway WAF_v2, Azure Key Vault integration, API Management, an
example application, in-cluster monitoring, and DevSecOps validation.

Terraform configuration is declarative and does not deploy resources until an
operator runs an apply operation.

## Architecture

```text
Internet
  -> Azure API Management
  -> Application Gateway WAF_v2
  -> managed AGIC add-on
  -> Kubernetes Ingress
  -> ClusterIP Service
  -> application pods

application pods
  -> Microsoft Entra Workload Identity
  -> Key Vault Secrets Store CSI provider
  -> Azure Key Vault

application /metrics
  -> ServiceMonitor
  -> Prometheus
  -> Grafana
```

APIM, Application Gateway, AKS, and Key Vault are independently conditional.
APIM requires the edge stack because Application Gateway is its configured
backend. AGIC is enabled only when both AKS and the edge stack are enabled.

## Repository Layout

| Path | Purpose |
|---|---|
| `terraform/` | Reusable infrastructure modules and the root composition. |
| `app/` | Python application, Dockerfile, OpenAPI contract, and Kubernetes manifests. |
| `monitoring/` | Prometheus, Grafana, ServiceMonitor, and dashboard configuration. |
| `docs/` | Detailed edge, APIM, and network-security design documents. |
| `pipelines/` | GitHub Actions workflow reference. |
| `tests/resilience/` | Post-deployment Kubernetes resilience scripts. |
| `.github/workflows/` | Validation, image publication, and manual Terraform workflows. |

## Terraform Modules

| Module | Purpose | Primary resources |
|---|---|---|
| `00-foundation` | Naming, tags, and resource-group structure. | Resource groups |
| `01-networking` | Virtual network, subnets, NSGs, and data-driven NSG rules. | VNet, subnets, NSGs |
| `02-security-baseline` | Resource-group RBAC, management locks, and optional Key Vault. | Role assignments, locks, Key Vault |
| `03-edge` | Conditional public ingress and WAF. | Public IP, WAF policy, Application Gateway |
| `04-workloads` | Conditional AKS, workload identity, Key Vault access, and AGIC. | AKS, managed identity, federated credential, role assignment |
| `05-apim` | Conditional API gateway and OpenAPI publication. | APIM service, API, API policy |
| `root` | Composes modules and connects their inputs and outputs. | Environment-level orchestration |

The root module is the supported entry point. Child modules contain their own
provider constraints but receive environment configuration from root.

## Configuration

Copy the example file and supply environment-specific identifiers:

```powershell
Copy-Item terraform/root/terraform.tfvars.example terraform/root/terraform.tfvars
```

Core inputs:

| Input | Default | Description |
|---|---|---|
| `subscription_id` | Required | Azure subscription used by the provider. |
| `tenant_id` | Required | Microsoft Entra tenant for Key Vault and identity resources. |
| `location` | `francecentral` | Deployment region. |
| `project_name` | `alz` | Short resource-name component. |
| `environment` | `dev` | Environment name: `dev`, `test`, or `prod`. |
| `vnet_address_space` | `10.10.0.0/16` | Landing-zone VNet CIDR. |
| `subnets` | See example file | Logical subnet definitions. |

Conditional features:

| Input | Default | Effect when enabled |
|---|---|---|
| `enable_key_vault` | `false` | Creates the landing-zone Key Vault. |
| `enable_aks_demo` | `false` | Creates AKS and the application workload identity. |
| `enable_edge_stack` | `false` | Creates Application Gateway WAF_v2 and enables AGIC integration. |
| `enable_apim` | `false` | Creates Developer-tier APIM; requires the edge stack. |
| `enable_management_access` | `false` | Adds the internal management-to-AKS administration rule. |

Additional inputs configure NSG rules, RBAC assignments, management locks, WAF
mode, APIM SKU, and AKS node sizing. See
[`terraform/root/variables.tf`](terraform/root/variables.tf) and
[`terraform/root/terraform.tfvars.example`](terraform/root/terraform.tfvars.example).

## Terraform Outputs

The root module exposes aggregate objects for:

- `foundation`: resource groups, location, naming prefix, and common tags;
- `networking`: VNet, subnets, NSGs, and NSG rules;
- `security_baseline`: RBAC assignments, locks, and optional Key Vault;
- `edge`: Application Gateway, public IP, and WAF policy when enabled;
- `workloads`: AKS, workload identity, Key Vault role assignment, and AGIC
  identity when enabled;
- `apim`: APIM service, API, gateway URL, and backend when enabled.

Conditional outputs return `null` when their corresponding feature is disabled.

## Local Terraform Workflow

Initialize and validate from the repository root:

```powershell
terraform -chdir=terraform/root init
terraform fmt -check -recursive
terraform -chdir=terraform/root validate
```

Review an environment plan:

```powershell
terraform -chdir=terraform/root plan -var-file=terraform.tfvars
```

Apply only after reviewing the plan and enabling the required conditional
features:

```powershell
terraform -chdir=terraform/root apply -var-file=terraform.tfvars
```

Terraform state may contain infrastructure identifiers. Store state in an
approved backend and do not commit local state or variable files.

## Application Deployment

After Terraform has created the required AKS, identity, Key Vault, and edge
resources:

1. Replace the workload identity, Key Vault, and tenant markers under
   `app/k8s`.
2. Add the required secret value directly to Key Vault.
3. Replace the application image's `latest` tag with an immutable GHCR SHA tag.
4. Render and review the Kustomize output.
5. Apply the manifests and verify the Deployment rollout.

See [`app/k8s/README.md`](app/k8s/README.md) for exact dependencies and commands.

## Security Controls

- Data-driven NSG rules with explicit ports, priorities, subnet keys, and Azure
  service tags.
- Application Gateway WAF_v2 with Microsoft Default Rule Set 2.2.
- Microsoft Entra Workload Identity without stored Azure credentials in pods.
- Key Vault RBAC with a scoped `Key Vault Secrets User` assignment.
- Secrets Store CSI mounting without Kubernetes Secret synchronization.
- Non-root containers, dropped Linux capabilities, read-only root filesystem,
  seccomp, resource limits, and health probes.
- APIM rate limiting and correlation-ID propagation.
- CI security gates for Terraform, Kubernetes, monitoring, and container images.

Detailed networking and ownership boundaries are documented in:

- [`docs/network-security.md`](docs/network-security.md)
- [`docs/edge.md`](docs/edge.md)
- [`docs/apim.md`](docs/apim.md)

## CI/CD

| Workflow | Purpose |
|---|---|
| `validate.yml` | Terraform, source, image, Kubernetes, monitoring, and security validation. |
| `build-image.yml` | Publishes SHA-tagged application images to GHCR. |
| `demo-deploy.yml` | Runs an operator-selected Terraform plan, apply, or destroy action. |

The validation workflow does not authenticate to Azure or contact a Kubernetes
cluster. See [`pipelines/README.md`](pipelines/README.md) for triggers, inputs,
permissions, security gates, and required secrets.

## Monitoring and Resilience

The monitoring assets install Prometheus and Grafana inside AKS and keep both
Services internal. See [`monitoring/README.md`](monitoring/README.md) for
installation, verification, access, persistence, and removal procedures.

The PowerShell scripts under `tests/resilience` validate pod recovery, replica
scaling, and rollout rollback behavior after deployment. See
[`tests/resilience/README.md`](tests/resilience/README.md) for prerequisites and
expected results.
