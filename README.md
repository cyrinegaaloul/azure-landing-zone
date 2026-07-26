## Azure Landing Zone

**Design and Implementation of a Secure Azure Landing Zone Integrating AKS and Jelastic P4D within a DevSecOps Approach**.

The current implementation is intentionally limited to low-cost structural layers and cost-safe scaffolds for later phases. This lets the full project be prepared ahead of time while Azure spending stays near zero until the final demonstration window.

## Cost Constraint

This project is being developed on an **Azure for Students** subscription with a limited **$100 USD credit** budget. Cost optimization is therefore a primary architecture and implementation requirement.

The working rules for this repository are:

- prefer free or very low-cost Azure resources during development
- avoid continuously billed services unless they are explicitly required for a final demonstration
- use Terraform validation workflows such as `fmt`, `init`, `validate`, and `plan` more often than `apply`
- treat expensive services as late-phase demonstration components that should be deployed briefly and destroyed immediately afterward
- warn before any recommendation that could actively consume Azure credits

## Current Scope

The repository currently includes:

- `terraform/00-foundation`
- `terraform/01-networking`
- `terraform/02-security-baseline`
- `terraform/03-edge`
- `terraform/04-workloads`
- `terraform/05-observability`
- `terraform/06-devsecops`
- `terraform/root`
- `app/`
- `.github/workflows/`

The implemented modules are split into two categories:

- active low-cost modules:
  - foundation
  - networking
  - security baseline
- deferred demo scaffolds:
  - edge
  - workloads
  - observability
  - devsecops

## Repository Structure

```text
azure-landing-zone/
|-- .github/
|   `-- workflows/
|       |-- demo-deploy.yml
|       `-- validate.yml
|-- app/
|   |-- .dockerignore
|   |-- Dockerfile
|   |-- README.md
|   |-- server.py
|   |-- jelastic/
|   |   `-- README.md
|   `-- k8s/
|       |-- deployment.yaml
|       `-- service.yaml
|-- docs/
|   |-- architecture.md
|   |-- demo-runbook.md
|   |-- devsecops.md
|   |-- edge.md
|   |-- networking.md
|   |-- observability.md
|   |-- orchestration.md
|   |-- security-baseline.md
|   `-- workloads.md
|-- pipelines/
|   `-- README.md
|-- terraform/
|   |-- 00-foundation/
|   |-- 01-networking/
|   |-- 02-security-baseline/
|   |-- 03-edge/
|   |-- 04-workloads/
|   |-- 05-observability/
|   |-- 06-devsecops/
|   `-- root/
`-- README.md
```

## Phase Summary

### 1. Foundation

- creates the resource group structure
- standardizes naming and tagging
- establishes the base landing zone layout

### 2. Networking

- creates the VNet
- reserves subnets for future services
- creates one NSG per subnet

### 3. Security Baseline

- supports resource-group scoped RBAC assignments
- supports optional management locks

### 4. Edge

- prepares Application Gateway, WAF, and APIM design choices
- stays disabled by default to avoid cost during development

### 5. Workloads

- prepares future AKS and Jelastic P4D deployment decisions
- includes a small demo application with health and metrics endpoints

### 6. Observability

- prepares Prometheus and Grafana design choices
- keeps ingestion-sensitive services deferred until demo time

### 7. DevSecOps

- includes validation-focused GitHub Actions workflows
- keeps deployment manual and demo-only

### 8. Root Orchestration

- composes all modules in one Terraform entrypoint
- uses outputs from earlier phases to wire later phases
- keeps expensive module toggles off by default

## Local Usage

For day-to-day development, work from `terraform/root`.

Initialize:

```powershell
terraform -chdir=terraform/root init
```

Plan the low-cost baseline:

```powershell
terraform -chdir=terraform/root plan -var-file=terraform.tfvars
```

Prepare the final demo configuration:

```powershell
Copy-Item terraform\root\demo.tfvars.example terraform\root\demo.tfvars
```

Plan the final demo configuration:

```powershell
terraform -chdir=terraform/root plan -var-file=demo.tfvars
```

Only apply the demo configuration when you are ready to spend credits for a short-lived presentation:

```powershell
terraform -chdir=terraform/root apply -var-file=demo.tfvars
terraform -chdir=terraform/root destroy -var-file=demo.tfvars
```

## Pipeline Usage

The repository contains two GitHub Actions workflows:

- `validate.yml` for default validation on pushes and pull requests
- `demo-deploy.yml` for manual plan, apply, or destroy during the final demo window

## Cost Notes

- Resource Groups: effectively free structural resources
- Virtual Network: generally no direct recurring charge for the VNet object itself
- subnets: no direct recurring charge
- Network Security Groups: no direct recurring charge
- Azure RBAC assignments: no separate direct service charge
- management locks: no separate direct service charge
- Application Gateway and WAF: continuously billed while provisioned
- API Management: tier-based or usage-based cost depending on SKU
- AKS: underlying compute is billed when running
- observability services: can become ingestion-cost sensitive

## Documentation

Phase 1 architecture notes are available in [docs/architecture.md](/abs/path/c:/Users/USER/Documents/azure-landing-zone/docs/architecture.md:1).

The networking design is documented in [docs/networking.md](/abs/path/c:/Users/USER/Documents/azure-landing-zone/docs/networking.md:1).
The security baseline design is documented in [docs/security-baseline.md](/abs/path/c:/Users/USER/Documents/azure-landing-zone/docs/security-baseline.md:1).
The edge design is documented in [docs/edge.md](/abs/path/c:/Users/USER/Documents/azure-landing-zone/docs/edge.md:1).
The workloads design is documented in [docs/workloads.md](/abs/path/c:/Users/USER/Documents/azure-landing-zone/docs/workloads.md:1).
The observability design is documented in [docs/observability.md](/abs/path/c:/Users/USER/Documents/azure-landing-zone/docs/observability.md:1).
The DevSecOps design is documented in [docs/devsecops.md](/abs/path/c:/Users/USER/Documents/azure-landing-zone/docs/devsecops.md:1).
The root orchestration design is documented in [docs/orchestration.md](/abs/path/c:/Users/USER/Documents/azure-landing-zone/docs/orchestration.md:1).
The final demo procedure is documented in [docs/demo-runbook.md](/abs/path/c:/Users/USER/Documents/azure-landing-zone/docs/demo-runbook.md:1).
