# Kubernetes Application Base

This Kustomize base defines the AKS workload. It intentionally contains tokens,
not real tenant IDs, managed-identity client IDs, addresses, or image tags.

| File | Purpose |
|---|---|
| `namespace.yaml` | `demo` namespace with restricted Pod Security admission labels. |
| `serviceaccount.yaml` | Workload Identity-enabled ServiceAccount. |
| `configmap.yaml` | Non-sensitive application settings and mounted-file path. |
| `secretproviderclass.yaml` | Azure Key Vault CSI object selection. |
| `deployment.yaml` | One non-root, read-only-root-filesystem application replica. |
| `service.yaml` | Internal Azure LoadBalancer used only by APIM. |
| `networkpolicy.yaml` | Default-deny policy with APIM, probes/nodes, Prometheus, DNS, and private-endpoint exceptions. |
| `kustomization.yaml` | Complete deployable base. |

## Deployment rendering

`scripts/render-kubernetes.ps1` runs `kubectl kustomize` and replaces tokens
using Terraform outputs and the exact GHCR digest. It fails if a token remains.
The committed files are never edited in place.

Values supplied automatically:

- Workload Identity client ID and tenant ID;
- Key Vault name;
- immutable `repository@sha256:digest` image reference;
- AKS internal LoadBalancer address and Azure subnet resource name;
- AKS, APIM, and private-endpoint subnet CIDRs.

The controlled deployment workflow installs monitoring first, applies the
rendered manifest, waits for the Deployment rollout and internal LoadBalancer
address, and tests the application through Application Gateway and APIM. These
operations run only after infrastructure is intentionally applied.

## Security behavior

- Internet traffic has no direct AKS route; APIM reaches the internal service.
- Restricted Pod Security, non-root execution, dropped capabilities, seccomp,
  a read-only root filesystem, probes, and resource limits are enforced.
- NetworkPolicy permits Prometheus scraping and DNS while limiting application
  ingress and VNet egress.
- The CSI volume uses OIDC federation and Azure RBAC; no Kubernetes Secret or
  Key Vault value is committed.
