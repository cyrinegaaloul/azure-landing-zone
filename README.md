## Azure Landing Zone

**Design and Implementation of a Secure Azure Landing Zone Integrating AKS and Jelastic P4D within a DevSecOps Approach**.

The current implementation is intentionally limited to the early Azure Landing Zone layers using Terraform and free or very low-cost Azure resources. These phases create the organizational and networking base that later modules will consume for security, workloads, and DevSecOps automation.

## Cost Constraint

This project is being developed on an **Azure for Students** subscription with a limited **$100 USD credit** budget. Cost optimization is therefore a primary architecture and implementation requirement.

The working rules for this repository are:

- prefer free or very low-cost Azure resources during development
- avoid continuously billed services unless they are explicitly required for a final demonstration
- use Terraform validation workflows such as `fmt`, `init`, `validate`, and `plan` more often than `apply`
- treat expensive services as late-phase demonstration components that should be deployed briefly and destroyed immediately afterward
- warn before any recommendation that could actively consume Azure credits

Examples of services that should not be deployed casually during development include:

- AKS node pools
- Application Gateway
- WAF
- API Management
- Azure Monitor ingestion-heavy configurations
- any always-on compute resource

## Current Scope

The repository currently includes:

- `terraform/00-foundation`
- `terraform/01-networking`
- `terraform/02-security-baseline`

The `terraform/00-foundation` module is responsible for:

- configuring the Terraform and AzureRM versions
- validating reusable input variables
- defining a consistent naming prefix
- defining common tags for governance and cost visibility
- creating three resource groups:
  - foundation
  - network
  - security
- exposing outputs that future modules can reuse

The `terraform/01-networking` module is responsible for:

- creating a landing zone virtual network
- reserving subnets for future layers such as AKS, Application Gateway, APIM, and private endpoints
- creating one NSG per subnet
- exposing VNet, subnet, and NSG outputs for future modules

The `terraform/02-security-baseline` module is responsible for:

- defining resource-group scoped RBAC assignments
- supporting optional management locks
- exposing outputs for security baseline auditability

Services such as AKS, Application Gateway, WAF, API Management, monitoring, Jelastic, CI/CD, Docker, and Kubernetes are intentionally excluded from the current implementation.

Even when future Terraform code is prepared for those services, that does not mean they should be applied immediately in the student subscription.

## Repository Structure

```text
azure-landing-zone/
|-- app/
|-- docs/
|   |-- architecture.md
|   `-- networking.md
|   `-- security-baseline.md
|-- pipelines/
|-- terraform/
|   |-- 00-foundation/
|   |   |-- main.tf
|   |   |-- outputs.tf
|   |   |-- providers.tf
|   |   |-- terraform.tfvars
|   |   `-- variables.tf
|   `-- 01-networking/
|       |-- main.tf
|       |-- outputs.tf
|       |-- providers.tf
|       |-- terraform.tfvars.example
|       `-- variables.tf
|   `-- 02-security-baseline/
|       |-- main.tf
|       |-- outputs.tf
|       |-- providers.tf
|       |-- terraform.tfvars.example
|       `-- variables.tf
`-- README.md
```

## Why The Implementation Starts With Structure

These first modules follow Azure Landing Zone principles by establishing resource organization and segmentation before service deployment.

The three resource groups create a clean separation of responsibilities:

- `foundation`: reserved for shared landing zone bootstrap assets
- `network`: reserved for future connectivity resources such as VNets and subnets
- `security`: reserved for future security resources such as Key Vault and policy-related assets

This separation is lightweight, free to create, and prepares the project for future expansion without refactoring the naming or governance model.

It also fits the student-budget constraint because Azure resource groups do not create meaningful recurring cost by themselves.

The networking layer is also cost-conscious because VNets, subnets, and NSGs are structural resources and are much safer to model during development than always-on managed platform services.

The security baseline remains cost-aware because RBAC assignments and management locks improve governance without introducing continuously billed security products.

## Architecture Decisions

### 1. Dedicated Foundation Module

The repository starts with a dedicated `terraform/00-foundation` module because the first objective is to establish stable platform primitives before adding services.

Decision rationale:

- keeps the scope aligned with the current milestone
- avoids mixing bootstrap resources with future networking or workload resources
- supports incremental delivery and easier testing

### 2. Standard Naming Prefix

Resource names are built from:

```text
<logical-name>-<project-name>-<environment>
```

Example:

```text
rg-foundation-alz-dev
```

Decision rationale:

- improves readability
- avoids hardcoded one-off names
- makes future modules consistent with the same naming scheme

### 3. Common Tags For Governance

The modules apply common tags such as:

- `environment`
- `owner`
- `cost_center`
- `managed_by`
- `criticality`
- `workload`

Decision rationale:

- supports governance and reporting
- improves cost tracking
- aligns future resources with the same metadata model

### 4. Reusable Outputs

The current modules export:

- resource group names and IDs
- the deployment location
- the naming prefix
- the resolved common tags
- VNet, subnet, and NSG details for future consumers

Decision rationale:

- allows future modules to consume the outputs directly
- reduces duplication between Terraform layers
- improves maintainability as the landing zone grows

### 5. Cost-Aware Incremental Delivery

Expensive platform services are intentionally deferred. During development, the project focuses on low-cost structural layers first, then uses Terraform plans and documentation to model later phases before any real deployment happens.

Decision rationale:

- supports learning without consuming credits too early
- keeps the repository aligned with the final architecture
- allows expensive services to be deployed only for a short demonstration window

### 6. Reserved Network Boundaries Before Workloads

The networking module reserves subnet boundaries for future services such as AKS, Application Gateway, APIM, management access, and private endpoints before those services are created.

Decision rationale:

- avoids rework later when expensive services are finally introduced
- supports better segmentation and future least-privilege controls
- keeps the current implementation low-cost and architecture-focused

### 7. Low-Cost Security Controls Before Security Products

The security baseline starts with RBAC assignments and optional resource locks before introducing services such as Key Vault, WAF, or monitoring.

Decision rationale:

- improves governance while staying within the student budget
- supports zero-trust and least-privilege concepts early
- avoids activating paid services before the platform structure is stable

## Usage

### Foundation

Initialize:

```powershell
terraform -chdir=terraform/00-foundation init
```

Plan:

```powershell
terraform -chdir=terraform/00-foundation plan
```

Apply:

```powershell
terraform -chdir=terraform/00-foundation apply
```

### Networking

Initialize:

```powershell
terraform -chdir=terraform/01-networking init
```

Prepare variables by copying `terraform/01-networking/terraform.tfvars.example` to `terraform/01-networking/terraform.tfvars`.

Plan:

```powershell
terraform -chdir=terraform/01-networking plan -var-file=terraform.tfvars
```

Apply:

```powershell
terraform -chdir=terraform/01-networking apply -var-file=terraform.tfvars
```

### Security Baseline

Initialize:

```powershell
terraform -chdir=terraform/02-security-baseline init
```

Prepare variables by copying `terraform/02-security-baseline/terraform.tfvars.example` to `terraform/02-security-baseline/terraform.tfvars`.

Plan:

```powershell
terraform -chdir=terraform/02-security-baseline plan -var-file=terraform.tfvars
```

Apply:

```powershell
terraform -chdir=terraform/02-security-baseline apply -var-file=terraform.tfvars
```

Only run `apply` when you are ready to create Azure resources in the subscription. Even low-cost resources should be reviewed carefully against the available student credits.

If you choose to test the networking module with `apply`, it is still wise to destroy the resources afterward to protect the student budget.

## Cost Notes For Current Modules

- Resource Groups: effectively free structural resources
- Virtual Network: generally no direct recurring charge for the VNet object itself
- subnets: no direct recurring charge
- Network Security Groups: no direct recurring charge
- Azure RBAC assignments: no separate direct service charge
- management locks: no separate direct service charge

Future cost typically comes from attached services, traffic patterns, or always-on managed components rather than from the current foundation and networking resources alone.

## Next Planned Phase

The next implementation phase should shift from low-cost platform structure to design preparation for higher-cost services only after foundation, networking, and the security baseline are validated.

That preparation should stay cost-aware by modeling integrations, variables, and documentation before paid or always-on services are created.

## Documentation

Phase 1 architecture notes are available in [docs/architecture.md](/abs/path/c:/Users/USER/Documents/azure-landing-zone/docs/architecture.md:1).

The networking design is documented in [docs/networking.md](/abs/path/c:/Users/USER/Documents/azure-landing-zone/docs/networking.md:1).
The security baseline design is documented in [docs/security-baseline.md](/abs/path/c:/Users/USER/Documents/azure-landing-zone/docs/security-baseline.md:1).
