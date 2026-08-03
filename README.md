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
- `terraform/04-workloads`
- `terraform/root`
- `app/`
- `.github/workflows/`

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
|   |-- networking.md
|   |-- orchestration.md
|   |-- security-baseline.md
|   `-- workloads.md
|-- pipelines/
|   `-- README.md
|-- terraform/
|   |-- 00-foundation/
|   |-- 01-networking/
|   |-- 02-security-baseline/
|   |-- 04-workloads/
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

### 3. Security Baseline

- supports resource-group scoped RBAC assignments
- supports optional management locks

### 4. Workloads

- defines a real conditional AKS resource
- keeps AKS disabled by default
- consumes the AKS subnet output from the networking module

### 5. Root Orchestration

- composes the active modules in one Terraform entrypoint
- uses outputs from earlier phases to wire later phases
- centralizes environment-level settings

## Local Usage

For day-to-day development, work from `terraform/root`.

The `terraform/root` module is the source of truth for shared settings such as:

- subscription ID
- location
- environment
- project name
- owner
- subnet plan
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
- AKS: underlying compute is billed when running

## Documentation

Phase 1 architecture notes are available in [docs/architecture.md](/abs/path/c:/Users/USER/Documents/azure-landing-zone/docs/architecture.md:1).

The networking design is documented in [docs/networking.md](/abs/path/c:/Users/USER/Documents/azure-landing-zone/docs/networking.md:1).
The security baseline design is documented in [docs/security-baseline.md](/abs/path/c:/Users/USER/Documents/azure-landing-zone/docs/security-baseline.md:1).
The workloads design is documented in [docs/workloads.md](/abs/path/c:/Users/USER/Documents/azure-landing-zone/docs/workloads.md:1).
The root orchestration design is documented in [docs/orchestration.md](/abs/path/c:/Users/USER/Documents/azure-landing-zone/docs/orchestration.md:1).
The deployment procedure is documented in [docs/demo-runbook.md](/abs/path/c:/Users/USER/Documents/azure-landing-zone/docs/demo-runbook.md:1).
