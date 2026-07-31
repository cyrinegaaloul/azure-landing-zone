# Phase 5 Workloads Design

## Objective

This phase prepares the workload layer with AKS as the primary deployment target.

## Planned Components

- AKS as the primary cloud-native deployment target
- Jelastic P4D as an optional later comparison target
- one shared application image and port model

## Cost Guidance

AKS should remain disabled until deployment is required because underlying compute resources are billed while running. Jelastic P4D should remain optional and should not block the AKS-first project path.

## Current Repository State

The Terraform module `terraform/04-workloads` captures AKS deployment assumptions such as cluster naming, node sizing, ingress strategy, service type, namespace, and replica count. The `app/` folder contains a small application service and Kubernetes manifests that can be used later with AKS.
