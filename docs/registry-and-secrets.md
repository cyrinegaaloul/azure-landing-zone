# Image Registry And Secret Strategy

## Objective

This document describes how the application image and configuration can be prepared for AKS without requiring an immediate Azure Container Registry or secret-management deployment.

## Image Registry Options

The current workload layer supports three planning modes:

- `local-only`
- `external`
- `acr`

### Recommended Early Path

For development, the simplest path is:

- build the image locally
- keep the registry mode as `external` or `local-only`
- avoid creating Azure Container Registry until deployment is required

### Later Azure Path

If the project later uses Azure Container Registry:

- create or reference one registry
- update the image name to use the registry server
- decide whether AKS will use managed identity or an image pull secret

## Secret Strategy

The current repository prepares three secret-delivery modes:

- `kubernetes-secret`
- `external-secret`
- `key-vault-csi`

### Recommended Early Path

For a lightweight deployment, use `kubernetes-secret` as the planning assumption and keep real values out of Git.

### Later Azure Path

If the project later adds Azure Key Vault integration, the preferred production direction is to use Key Vault with CSI or another external secret flow instead of storing long-lived values directly in Kubernetes manifests.
