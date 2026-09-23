# Kubernetes Frontend Base

This Kustomize base defines the AKS frontend workload. It intentionally contains tokens,
not real tenant IDs, managed-identity client IDs, addresses, or image tags.

| File | Purpose |
|---|---|
| `namespace.yaml` | `demo` namespace with restricted Pod Security admission labels. |
| `serviceaccount.yaml` | Workload Identity-enabled ServiceAccount. |
| `configmap.yaml` | Non-sensitive application settings and mounted-file path. |
| `secretproviderclass.yaml` | Azure Key Vault CSI object selection. |
| `deployment.yaml` | One non-root, read-only-root-filesystem application replica. |
| `service.yaml` | ClusterIP backend for the ingress resource. |
| `ingress-controller.yaml` | AKS Application Routing internal NGINX controller using the APIM-reserved private IP. |
| `ingress.yaml` | Routes the internal controller to the ClusterIP service. |
| `networkpolicy.yaml` | Default-deny policy with APIM, AKS ingress, Azure Monitor metrics, DNS, and private-endpoint exceptions. |
| `kustomization.yaml` | Complete deployable base. |

## Deployment rendering

`scripts/render-kubernetes.ps1` runs `kubectl kustomize` and replaces tokens
using Terraform outputs and the exact GHCR digest. It fails if a token remains.
The committed files are never edited in place.

Values supplied automatically:

- Workload Identity client ID and tenant ID;
- Key Vault name;
- immutable `repository@sha256:digest` image reference;
- internal ingress-controller address and Azure subnet resource name;
- AKS, APIM, and private-endpoint subnet CIDRs.

The controlled deployment workflow applies the rendered manifest, waits for the
AKS-managed ingress controller and Deployment rollout, then tests the
application through Application Gateway and APIM. These operations run only
after infrastructure is intentionally applied.

## Security behavior

- Internet traffic has no direct AKS route; APIM reaches the internal ingress
  controller, which routes to the ClusterIP service.
- Restricted Pod Security, non-root execution, dropped capabilities, seccomp,
  a read-only root filesystem, probes, and resource limits are enforced.
- NetworkPolicy permits Azure Monitor metrics scraping and DNS while limiting application
  ingress and VNet egress.
- The CSI volume uses OIDC federation and Azure RBAC; no Kubernetes Secret or
  Key Vault value is committed.
