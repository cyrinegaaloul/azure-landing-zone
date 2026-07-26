# Phase 5 Workloads Design

## Objective

This phase prepares the workload layer for future AKS and Jelastic P4D deployment while keeping Azure spend close to zero during development.

## Planned Components

- AKS for cloud-native Kubernetes deployment
- Jelastic P4D for alternate platform deployment
- one shared demo application image and port model

## Cost Guidance

AKS should remain disabled until final demo preparation because underlying compute resources are billed while running. Jelastic P4D should also be treated as a demo-only target.

## Current Repository State

The Terraform module `terraform/04-workloads` captures the planned deployment model, while the `app/` folder contains a small demo service and Kubernetes manifests.
