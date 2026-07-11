# Phase 3 Security Baseline Design

## Objective

This phase introduces a low-cost security baseline that improves governance without provisioning paid security services. The initial emphasis is on RBAC structure and optional protection controls that fit a student-budget project.

## Cost Profile

This phase is intentionally limited to low-cost or no-direct-cost controls:

- Azure RBAC assignments: no separate direct service charge
- management locks: no separate direct service charge

These controls can still affect operations, especially deletion workflows, so they must be used intentionally.

## Scope

Included in this phase:

- resource-group scoped RBAC assignments
- optional management locks on resource groups
- Terraform outputs for auditing what was assigned

Excluded from this phase:

- Key Vault
- Microsoft Defender plans
- Azure Policy assignments that require a broader governance rollout
- SIEM or monitoring ingestion
- managed identities for workloads

## Design Decisions

### 1. RBAC Starts At Resource Group Scope

Role assignments are scoped to the existing `foundation`, `network`, and `security` resource groups.

Decision rationale:

- keeps least-privilege boundaries aligned with the current landing zone structure
- is easier to explain and test than subscription-wide assignments
- avoids over-permissioning early in the project

### 2. Locks Are Optional By Default

Resource locks are supported but not forced.

Decision rationale:

- protects the option to demonstrate deletion protection later
- avoids blocking frequent create-and-destroy workflows during student-budget development
- keeps the environment easier to clean up after demonstrations

### 3. No Paid Security Services Yet

The module does not deploy Key Vault, WAF, Defender plans, or monitoring services.

Decision rationale:

- respects the budget constraint
- keeps the focus on foundational governance
- lets later phases add those services only when they are actually needed

## Recommended Usage

- use `Reader` or other least-privilege built-in roles during early testing
- keep management locks disabled until you explicitly need to demonstrate protection controls
- prefer `terraform plan` and `terraform validate` during development

## Recommended Next Step After Security Baseline

After foundation, networking, and the lightweight security baseline are validated, the next step should be design preparation for higher-cost services rather than immediate deployment. That means documenting how AKS, Application Gateway, APIM, observability, and CI/CD will plug into the existing structure before spending credits on them.
