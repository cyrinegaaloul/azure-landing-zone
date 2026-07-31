# AKS Implementation Notes

## Objective

This document describes how the current repository prepares the application for Azure Kubernetes Service without requiring an AKS deployment during development.

## Current AKS Preparation

The repository already includes:

- AKS planning variables in `terraform/04-workloads`
- a containerized application in `app/`
- Kubernetes manifests in `app/k8s`
- a root-level configuration path that can enable AKS later

## Planned AKS Shape

The current workload assumptions are:

- cluster tier: Free
- node count: 1
- node size: `Standard_B2s`
- namespace: `demo`
- service type: `ClusterIP`
- ingress strategy: deferred to a later edge layer

## Why The Service Is Internal

The current service is `ClusterIP` because it avoids introducing an external load balancer early. This keeps the application deployment simpler and avoids adding network cost before the edge layer is formally implemented.

## Recommended Later Steps

When you are ready to continue the AKS implementation, the next tasks are:

1. decide whether ingress should be handled by an ingress controller or by the later edge layer
2. choose the image registry strategy
3. define AKS identity and secret handling
4. plan the monitoring integration for `/metrics`
5. deploy only for a short validation window if cost is a concern
