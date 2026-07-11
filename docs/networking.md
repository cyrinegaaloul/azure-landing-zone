# Phase 2 Networking Design

## Objective

Phase 2 introduces the network structure for the landing zone while staying compatible with a student-budget development model. The goal is to prepare clean network boundaries for future services without deploying any continuously billed Azure platform appliances.

## Cost Profile

This phase is intentionally built around low-cost networking primitives:

- Azure Virtual Network: generally no direct recurring charge for the VNet object itself
- subnets: no direct recurring charge
- Network Security Groups: no direct recurring charge

Possible future charges come from traffic, attached services, or paid network appliances, not from the structural resources defined in this module alone.

## Scope

Included in this phase:

- one landing zone VNet
- reserved subnets for future phases
- one NSG per subnet to support segmentation
- reusable outputs for future modules

Excluded from this phase:

- Application Gateway
- WAF
- API Management
- Azure Firewall
- NAT Gateway
- Bastion
- private endpoints
- route tables unless a later phase truly needs them

## Design Decisions

### 1. One Shared Landing Zone VNet

The module creates a single virtual network with a default address space of `10.10.0.0/16`.

Decision rationale:

- keeps the design simple for a graduation project
- leaves enough room for future subnet segmentation
- avoids premature hub-and-spoke complexity before the project needs it

### 2. Reserved Subnets For Future Services

The default subnet plan reserves space for:

- `management`
- `private-endpoints`
- `aks`
- `appgw`
- `apim`

Decision rationale:

- prepares for later phases without deploying those services yet
- reduces the chance of IP refactoring later
- keeps subnet boundaries aligned with security and operational separation

### 3. NSG Per Subnet

Each subnet receives its own NSG by default, even though no custom rules are added yet.

Decision rationale:

- supports least-privilege network design later
- keeps future rule management scoped to each subnet role
- remains low-cost during development

### 4. No Paid Edge Or Connectivity Services Yet

The module intentionally avoids Azure services that are commonly always-on and continuously billed.

Decision rationale:

- protects limited student credits
- keeps early development focused on Terraform structure and architecture
- allows expensive services to be introduced only for final validation or demonstration

## How This Connects To The Foundation Module

This module is designed to consume outputs conceptually produced by `terraform/00-foundation`, especially:

- the network resource group name
- the shared location
- the shared tagging model
- the common naming pattern

At this stage, the handoff can be done manually through variable values. A more automated cross-module strategy can be introduced later if the project truly needs it.

## Recommended Next Step After Networking

After the networking layer is validated, the next logical phase is a lightweight security baseline module focused on design-safe items such as identity structure, RBAC planning, and secret-management preparation without immediately deploying expensive or unnecessary services.
