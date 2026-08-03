# Phase 1 Foundation Architecture

## Objective

Phase 1 establishes the Terraform foundation for a future secure Azure Landing Zone. The goal is to create a reusable organizational baseline that supports later networking, security, and workload modules without deploying those services yet.

## Cost Optimization Constraint

The project is being developed under an Azure for Students subscription with approximately $100 USD in Azure credits. Cost optimization is therefore treated as a first-class architecture requirement rather than a secondary concern.

This affects the design in the following ways:

- development favors Terraform structure, validation, and planning over frequent Azure deployments
- free or near-zero-cost resources are preferred in early phases
- continuously billed services are deferred to late-stage demonstration activities
- expensive components should be provisioned briefly and removed immediately after validation or presentation

## Scope Boundaries

Included in Phase 1:

- Terraform version and AzureRM provider configuration
- validated input variables
- naming convention
- governance tags
- three resource groups for foundation, network, and security

Excluded from Phase 1:

- virtual networks and subnets
- NSGs and routing
- managed identities and RBAC assignments
- Key Vault
- AKS
- Application Gateway and WAF
- API Management
- monitoring and observability tooling
- CI/CD pipelines

These exclusions are motivated both by scope control and by cost control.

## High-Level Design

The foundation creates three resource groups in one Azure region:

- `rg-foundation-<project>-<environment>`
- `rg-network-<project>-<environment>`
- `rg-security-<project>-<environment>`

This structure provides clean ownership boundaries for later modules:

- the foundation group anchors shared bootstrap resources
- the network group is reserved for connectivity resources in the next phase
- the security group is reserved for security services added in later phases

## Design Principles

### Incremental Delivery

The landing zone is built in phases so each layer can be validated before the next one is introduced. This lowers risk and makes the project easier to explain, test, and maintain.

It also reduces the chance of consuming Azure credits before the design is mature.

### Reusability

Inputs, tags, naming, and outputs are defined once so future Terraform modules can consume them rather than redefining them.

### Separation Of Concerns

Phase 1 only handles platform foundation concerns. It does not include service-specific logic for networking, workloads, or security tooling.

### Governance Readiness

Even though the current implementation is lightweight, it already applies ownership, environment, and cost-tracking metadata. This supports future governance and reporting needs.

### Cost-Aware Deployment Strategy

The repository is designed so that later expensive services can exist as Terraform code without being deployed continuously during development.

Recommended operating model:

- write Terraform modules early
- validate locally with `terraform fmt`, `terraform init`, `terraform validate`, and `terraform plan`
- delay `terraform apply` for costlier components until the final project demonstration
- destroy temporary demonstration resources immediately after use

## Why This Fits Azure Landing Zone Guidance

This phase aligns with Azure Landing Zone best practices in a simplified way:

- organize resources consistently from the beginning
- prepare clear boundaries for networking and security domains
- use standardized naming and tagging
- keep the platform extensible for future policy, identity, and connectivity layers

## Transition To Phase 2

The next implemented phase is the networking module in `terraform/01-networking`, which consumes the same naming, tagging, and regional conventions while keeping the architecture cost-aware.
