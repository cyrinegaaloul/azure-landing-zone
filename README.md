## Azure Landing Zone

**Design and Implementation of a Secure Azure Landing Zone Integrating AKS and Jelastic P4D within a DevSecOps Approach**.

This repository contains the infrastructure, application, and workflow assets for the project. The implementation is organized in phases so the platform can be assembled progressively and deployed when required.

## Project Context

The project is being developed on an **Azure for Students** subscription with a limited **$100 USD credit** budget. Resource selection and deployment timing must therefore be controlled carefully.

Working rules for the repository:

- use Terraform workflows such as `fmt`, `init`, `validate`, and `plan` during development
- avoid creating continuously billed services until they are required
- keep planning settings separated from deployment settings
- review cloud-facing changes before running `apply`

## Repository Scope

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

The modules fall into two groups:

- implemented platform layers:
  - foundation
  - networking
  - security baseline
- planned service layers:
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
|       |-- configmap.yaml
|       |-- deployment.yaml
|       |-- ingress-placeholder.yaml
|       |-- namespace.yaml
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

- captures Application Gateway, WAF, and APIM design inputs
- keeps the service layer separated from the current platform baseline

### 5. Workloads

- prepares AKS as the primary workload target
- preserves Jelastic as an optional later comparison target
- includes an application with health and metrics endpoints

### 6. Observability

- captures Prometheus and Grafana design inputs
- separates observability planning from current deployment scope

### 7. DevSecOps

- includes validation-focused GitHub Actions workflows
- defines a controlled deployment workflow

### 8. Root Orchestration

- composes all modules in one Terraform entrypoint
- uses outputs from earlier phases to wire later phases
- centralizes environment-level settings

## Local Usage

For day-to-day development, work from `terraform/root`.

Initialize:

```powershell
terraform -chdir=terraform/root init
```

Plan the current root configuration:

```powershell
terraform -chdir=terraform/root plan -var-file=terraform.tfvars
```

Prepare an alternate configuration when needed:

```powershell
Copy-Item terraform\root\demo.tfvars.example terraform\root\demo.tfvars
```

Plan the alternate configuration:

```powershell
terraform -chdir=terraform/root plan -var-file=demo.tfvars
```

Apply and destroy only when you are ready to create and later remove Azure resources:

```powershell
terraform -chdir=terraform/root apply -var-file=demo.tfvars
terraform -chdir=terraform/root destroy -var-file=demo.tfvars
```

## Pipeline Usage

The repository contains two GitHub Actions workflows:

- `validate.yml` for validation on pushes and pull requests
- `demo-deploy.yml` for manual plan, apply, or destroy operations

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
The deployment procedure is documented in [docs/demo-runbook.md](/abs/path/c:/Users/USER/Documents/azure-landing-zone/docs/demo-runbook.md:1).
