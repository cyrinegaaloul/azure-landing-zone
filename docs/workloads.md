# Phase 4 Workloads Design

## Objective

This phase defines the workload layer around AKS.

## Implemented Scope

- a real `azurerm_kubernetes_cluster` resource in `terraform/04-workloads`
- conditional creation through `enable_aks_demo`
- subnet integration through the networking module output
- node count and VM size as explicit inputs

## Current Repository State

The Terraform module `terraform/04-workloads` now contains a real AKS resource definition. The root module passes the AKS subnet ID from `module.networking.subnets["aks"].id` and keeps AKS disabled by default in `terraform/root/terraform.tfvars`.

The `app/` folder contains a small application service and Kubernetes manifests that can be used later with AKS.
