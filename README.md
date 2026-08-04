## Azure Landing Zone

**Design and Implementation of a Secure Azure Landing Zone with AKS within a DevSecOps Approach**.

This repository contains the infrastructure, application, and workflow assets for the project. The implementation is organized in phases so the platform can be assembled progressively and deployed when required.

## Project Context

The project is being developed on an **Azure for Students** subscription with a limited **$100 USD credit** budget. Resource selection and deployment timing must therefore be controlled carefully.

Working rules for the repository:

- use Terraform workflows such as `fmt`, `init`, `validate`, and `plan` during development
- avoid creating continuously billed services until they are required
- review cloud-facing changes before running `apply`

## Repository Scope

The repository currently includes:

- `terraform/00-foundation`
- `terraform/01-networking`
- `terraform/02-security-baseline`
- `terraform/03-edge`
- `terraform/04-workloads`
- `terraform/05-apim`
- `terraform/root`
- `app/`
- `monitoring/`
- `tests/resilience/`
- `.github/workflows/`

## Repository Structure

```text
azure-landing-zone/
|-- .github/
|   `-- workflows/
|       |-- build-image.yml
|       |-- demo-deploy.yml
|       `-- validate.yml
|-- app/
|   |-- .dockerignore
|   |-- Dockerfile
|   |-- README.md
|   |-- openapi.yaml
|   |-- server.py
|   `-- k8s/
|       |-- configmap.yaml
|       |-- deployment.yaml
|       |-- ingress.yaml
|       |-- kustomization.yaml
|       |-- namespace.yaml
|       |-- secretproviderclass.yaml
|       |-- serviceaccount.yaml
|       `-- service.yaml
|-- monitoring/
|   |-- grafana-dashboard.json
|   |-- kube-prometheus-stack-values.yaml
|   |-- servicemonitor.yaml
|   `-- README.md
|-- docs/
|   |-- apim.md
|   |-- edge.md
|   `-- network-security.md
|-- pipelines/
|   `-- README.md
|-- tests/
|   `-- resilience/
|       |-- pod-recovery.ps1
|       |-- rollout-rollback.ps1
|       |-- scale-test.ps1
|       `-- README.md
|-- terraform/
|   |-- 00-foundation/
|   |-- 01-networking/
|   |-- 02-security-baseline/
|   |-- 03-edge/
|   |-- 04-workloads/
|   |-- 05-apim/
|   `-- root/
`-- README.md
```

## Phase Summary

### 1. Foundation

- creates the resource group structure
- standardizes naming and shared tags
- establishes the base landing zone layout

### 2. Networking

- creates the VNet
- reserves subnets for future services
- creates one NSG per subnet
- creates maintainable NSG rules from logical subnet keys and Azure service tags
- keeps optional management SSH/RDP access disabled by default

The approved traffic matrix, priorities, stateful NSG behavior, default-deny
decision, and private-networking considerations for Application Gateway/APIM
are documented in
[`docs/network-security.md`](docs/network-security.md). The rules are prepared in
Terraform but have not been applied to Azure.

### 3. Security Baseline

- supports resource-group scoped RBAC assignments
- supports optional management locks
- supports an optional Azure Key Vault for landing zone secret management
- uses Azure RBAC authorization for the vault and stores no secrets in Terraform
- keeps Key Vault disabled by default to protect the student credit budget
- defers Key Vault private networking and secret creation to controlled future
  deployment work

### 4. Edge Ingress

- conditionally creates a Standard static Public IP, WAF policy, and traditional
  Application Gateway WAF_v2 in the dedicated `appgw` subnet
- uses Microsoft Default Rule Set 2.2 in `Detection` mode initially
- passes the existing gateway ID to the AKS-managed AGIC add-on only when both
  edge and AKS are explicitly enabled
- prepares a temporary HTTP port 80 demo path without committing certificates
- remains disabled by default because WAF_v2 is continuously billed

The architecture, bootstrap listener, AGIC identity roles, selective Terraform
drift handling, future Key Vault TLS work, and deployment sequence are documented
in [`docs/edge.md`](docs/edge.md). Nothing in this stage is currently deployed.

### 5. Workloads

- defines a real conditional AKS resource
- keeps AKS disabled by default
- consumes the AKS subnet output from the networking module
- enables the AKS OIDC issuer, Microsoft Entra Workload Identity, and the Azure
  Key Vault Secrets Provider add-on when the conditional cluster is created
- creates one conditional user-assigned identity for the demo application and
  federates it only with the `demo/landing-zone-demo` Kubernetes service account
- assigns only `Key Vault Secrets User` at the optional vault scope when both AKS
  and Key Vault are enabled
- conditionally enables the managed AGIC add-on against the explicitly created
  WAF_v2 gateway; it never asks AKS to create a second Standard_v2 gateway

### Workload Identity Secret Flow

The demo pod uses a Kubernetes service-account token instead of a stored Azure
credential. AKS exposes the token through its OIDC issuer, and the federated
identity credential allows only the subject
`system:serviceaccount:demo:landing-zone-demo` to exchange that token for the
application managed identity. Azure RBAC then limits that identity to reading
Key Vault secret contents through the `Key Vault Secrets User` role.

The Secrets Store CSI Driver and Azure provider mount the selected vault object
into `/mnt/secrets-store` as an in-memory pod volume. The configuration does not
sync the value into a Kubernetes Secret. This avoids committing secret values,
Terraform state containing secret values, or long-lived Azure credentials in the
cluster.

Before a future approved deployment, replace the markers in
`app/k8s/serviceaccount.yaml` and `app/k8s/secretproviderclass.yaml` with the
Terraform workload identity `client_id`, Key Vault name, and tenant ID. Insert
`demo-secret` into Key Vault manually, then deploy the manifests only after both
`enable_aks_demo` and `enable_key_vault` have been deliberately enabled.

Both toggles remain `false` in the current configuration. No secret value exists
in Git or Terraform, and this identity integration has not been deployed to
Azure.

### 6. API Management

- conditionally creates a Developer-tier APIM service and one imported OpenAPI
  API
- publishes only `/health`, `/api/info`, and `/api/status`; `/metrics` remains
  internal
- applies client-IP rate limiting and correlation-ID propagation
- derives its backend from the conditional Application Gateway output instead
  of using a placeholder address
- remains disabled by default because APIM is continuously billed

See [`docs/apim.md`](docs/apim.md) for the request path, policy, cost controls,
deployment sequence, and deferred production controls.

### 7. Monitoring Assets

- prepares a low-resource `prometheus-community/kube-prometheus-stack` profile
  for the temporary AKS demonstration window
- keeps Prometheus and Grafana inside AKS behind `ClusterIP` Services
- scrapes the application's `/metrics` endpoint through a `ServiceMonitor`
- provides a compact Grafana dashboard for the app and its Kubernetes workload
- uses ephemeral storage, six-hour retention, and no Alertmanager to limit node
  usage and avoid persistent-disk cost
- remains preparation only: the chart and custom resource have not been deployed

Azure Managed Grafana, Azure Monitor managed Prometheus, Log Analytics, and
Container Insights are deliberately out of scope to protect the Azure for
Students credit. See `monitoring/README.md` for the future controlled install,
verification, dashboard import, and uninstall runbook.

### 8. Root Orchestration

- composes the active modules in one Terraform entrypoint
- uses outputs from earlier phases to wire later phases
- centralizes environment-level settings

### 9. Resilience Test Assets

- provides simple, manually invoked PowerShell demonstrations for pod recovery,
  replica scaling, and Deployment rollout/rollback
- targets the existing `demo/landing-zone-demo-app` workload naming
- remains post-deployment only and is never executed by CI

See `tests/resilience/README.md` for prerequisites and expected results.

## Local Usage

For day-to-day development, work from `terraform/root`.

The `terraform/root` module is the source of truth for shared settings such as:

- subscription ID
- location
- environment
- project name
- owner
- subnet plan
- approved NSG traffic rules and the disabled-by-default management access toggle
- edge-stack toggle and WAF policy mode
- APIM toggle and fixed Developer-tier SKU
- RBAC and lock settings
- AKS toggle and node sizing

The numbered modules are reusable child modules. Avoid maintaining separate live `terraform.tfvars` values in each child module, because that can cause configuration drift between phases.

Initialize:

```powershell
terraform -chdir=terraform/root init
```

Plan the current root configuration:

```powershell
terraform -chdir=terraform/root plan -var-file=terraform.tfvars
```

Apply and destroy only when you are ready to create and later remove Azure resources:

```powershell
terraform -chdir=terraform/root apply -var-file=terraform.tfvars
terraform -chdir=terraform/root destroy -var-file=terraform.tfvars
```

## DevSecOps Pipeline Usage

The repository contains three GitHub Actions workflows:

- `validate.yml` runs on pushes to `main` and on pull requests. It performs free,
  non-deploying Terraform formatting and root-module validation, Python syntax
  checking, a local Docker build, and schema validation of the manifests rendered
  by `kubectl kustomize app/k8s`. It then applies automatic security gates before
  any deployment: Trivy scans Terraform and rendered Kubernetes configuration for
  misconfigurations and scans the locally built image for known vulnerabilities.
  Each Trivy scan prints a table and fails CI only for `HIGH` or `CRITICAL`
  findings. The Kubernetes workload runs with a non-root, read-only security
  context to satisfy the configuration gate. The validation workflow never
  pushes the image. It also parses the public OpenAPI document, validates the
  prepared monitoring YAML and dashboard JSON, parses the `ServiceMonitor` while
  explicitly skipping only its external CRD schema, and scans `monitoring/` with
  Trivy. These checks do not install Helm releases or contact a Kubernetes
  cluster.
- `build-image.yml` runs when `app/**` changes on `main`, and can also be run
  manually. It publishes
  `ghcr.io/<repository-owner>/landing-zone-demo-app` with the immutable commit SHA
  tag and, on the default branch, the `latest` tag. The dynamic image path is
  normalized to lowercase by the Docker metadata action.
- `demo-deploy.yml` remains manual and supports `plan`, `apply`, and `destroy`.
  It supplies CI values through `TF_VAR_` environment variables and therefore
  does not depend on the ignored local `terraform/root/terraform.tfvars` file.

The manual `enable_aks`, `enable_edge`, and `enable_apim` inputs default to
`false`, so AKS, Application Gateway, WAF, AGIC, and APIM remain absent unless
the operator deliberately selects them. APIM requires edge because Application
Gateway is its backend. Running `apply` with any billable stage enabled can
consume Azure for Students credit. Protect the `demo` GitHub environment with
an approval rule and run `destroy` immediately after the final demonstration.

The demo workflow currently requires these repository or environment secrets:

- `AZURE_CREDENTIALS`: the existing Azure service-principal credentials JSON
- `AZURE_SUBSCRIPTION_ID`: the subscription ID passed to Terraform
- `AZURE_TENANT_ID`: the Microsoft Entra tenant ID passed to Terraform

The image workflow uses the automatically provided `GITHUB_TOKEN`; no additional
registry secret is required. Configure the `landing-zone-demo-app` GHCR package
as public so AKS can pull it without an image pull secret. GHCR is used instead
of Azure Container Registry to avoid adding a paid Azure registry to this
budget-constrained project. Before a controlled deployment, update the manifest
from its static `latest` default to the immutable commit SHA tag published by the
image workflow.

`AZURE_CREDENTIALS` is retained so the existing workflow remains usable. A future
hardening task should replace this long-lived JSON secret with GitHub OIDC
federation after the necessary Azure identity configuration exists.

Key Vault must be enabled only during an approved deployment window because it
can create Azure usage. This repository does not create vault secrets, and the
optional vault has not been deployed or tested in Azure.

## Cost Notes

- Resource Groups: effectively free structural resources
- Virtual Network: generally no direct recurring charge for the VNet object itself
- subnets: no direct recurring charge
- Network Security Groups: no direct recurring charge
- Azure RBAC assignments: no separate direct service charge
- management locks: no separate direct service charge
- AKS: underlying compute is billed when running
- Application Gateway WAF_v2: continuously billed while enabled; reserve it for
  the approved final demo window and destroy it immediately afterward
- API Management Developer tier: continuously billed and intended only for the
  approved demo window; it is not a production SLA tier
- in-cluster Prometheus and Grafana: no managed-service fee, but they consume AKS
  node CPU/memory only while deliberately installed for the final demo
