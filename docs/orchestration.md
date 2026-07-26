# Root Orchestration Layer

## Objective

The root orchestration layer provides a single Terraform entrypoint that composes the existing landing zone phases without replacing them.

## Why This Exists

The numbered modules remain useful for learning and for phase-by-phase explanation in an academic report. The root layer adds a cleaner operational workflow by:

- wiring module outputs into downstream inputs automatically
- reducing repeated manual variable copying
- preserving the incremental architecture already built

## Cost Profile

The root layer does not introduce new Azure services by itself. It only orchestrates:

- foundation resource groups
- networking structure
- low-cost security baseline controls

Cost behavior is therefore the same as the combined underlying modules. This still means `terraform apply` can consume Azure credits, so planning should remain the default development workflow.

## Design Decisions

### 1. Keep The Numbered Modules

The root layer is intentionally thin. It does not duplicate resource definitions. Instead, it calls:

- `terraform/00-foundation`
- `terraform/01-networking`
- `terraform/02-security-baseline`

This keeps the repository easier to explain and reuse.

### 2. Derive Dependencies Through Outputs

The root layer passes:

- the foundation network resource group into the networking module
- the foundation common tags into the networking module
- the foundation resource group map into the security baseline module

This avoids fragile manual cross-module copy and paste.

### 3. Preserve Cost-Safe Development

The preferred workflow remains:

- `terraform fmt`
- `terraform init`
- `terraform validate`
- `terraform plan`

The root entrypoint makes it easier to reason about the full landing zone, but it should still be applied cautiously in a student subscription.

## Recommended Usage

Use the root module when you want:

- one plan covering the current implemented landing zone layers
- a cleaner demo workflow
- simpler documentation for how the parts connect

Use the numbered modules directly when you want:

- to study one phase in isolation
- to explain the architecture incrementally
- to troubleshoot a single layer
