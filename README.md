# Azure Landing Zone Demo

This repository implements a cost-aware Azure landing-zone prototype and a
containerized demonstration workload. The deployed application path is:

```text
Internet (HTTP development endpoint)
  -> Application Gateway WAF_v2
  -> API Management Developer tier (internal VNet mode, HTTPS)
  -> AKS internal LoadBalancer
  -> non-root application pod
  -> Workload Identity + Secrets Store CSI
  -> private Azure Key Vault endpoint
```

The public listener intentionally remains HTTP because the project has no
owned public domain or trusted certificate. Application Gateway validates TLS
to the internal APIM gateway. Client-facing HTTPS is production hardening, not
a simulated feature.

## Repository layout

| Path | Purpose |
|---|---|
| `terraform/bootstrap-state/` | One-time, separate Azure Blob backend bootstrap. |
| `terraform/00-foundation/` | Resource groups, common naming, and tags. |
| `terraform/01-networking/` | VNet, subnets, NSGs, and rule associations. |
| `terraform/02-security-baseline/` | Key Vault, private endpoint/DNS, RBAC, and optional locks. |
| `terraform/03-edge/` | Application Gateway WAF_v2 and public IP. |
| `terraform/04-workloads/` | AKS, Workload Identity, federation, and Key Vault RBAC. |
| `terraform/05-apim/` | Internal APIM instance and imported demo API. |
| `terraform/root/` | Composition, profiles, cross-module traffic rules, and outputs. |
| `app/` | Python service, Dockerfile, OpenAPI contract, and Kubernetes base. |
| `scripts/` | Deployment-time Kubernetes rendering. |
| `monitoring/` | kube-prometheus-stack values, ServiceMonitor, and Grafana dashboard. |
| `.github/workflows/` | Gated CI/image publication and controlled deployment. |
| `docs/` | Networking, security, edge, APIM, and state details. |

## Functional profiles

Terraform rejects combinations that would create an unusable partial path.

| Profile | Key Vault | Private endpoint | AKS/APIM/App Gateway | Key Vault public access | Locks/WAF |
|---|---:|---:|---:|---:|---|
| `core` | Off | Off | Off | N/A | Off / Detection |
| `key-vault-bootstrap` | On | Off | Off | On | Off / Detection |
| `full` | On | On | On | Off | Off / Detection |
| `secure` | On | On | On | Off | `CanNotDelete` / Prevention |

The bootstrap profile exists only to create `demo-secret` before private-only
Key Vault networking is enabled. It does not deploy expensive application
components. The secure profile leaves Key Vault purge protection disabled so
the internship environment remains intentionally destroyable.

## Prerequisites

- Terraform 1.14 or later
- Azure CLI and an Azure subscription
- Docker for local image validation
- `kubectl`, `kubelogin`, and Helm only for a later deployed environment
- Permission to create a Microsoft Entra application and service principal
- GHCR access for automation

No paid domain, external certificate, monitoring SaaS, Terraform Cloud, or paid
GitHub product is required.

## Terraform state

The root uses the `azurerm` backend. Azure Blob leases provide state locking;
Microsoft Entra authorization avoids storage account keys. Bootstrap the small
state stack once, then initialize local work with a private backend file:

```powershell
az login
terraform -chdir=terraform/bootstrap-state init
terraform -chdir=terraform/bootstrap-state plan -out=tfplan
# Apply only when you intentionally create the backend:
terraform -chdir=terraform/bootstrap-state apply tfplan

Copy-Item terraform/root/backend.dev.hcl.example terraform/root/backend.dev.hcl
terraform -chdir=terraform/root init -migrate-state -backend-config=backend.dev.hcl
```

`backend.dev.hcl` is ignored. It contains names, not credentials. The bootstrap
grants `Storage Blob Data Contributor` to its GitHub service principal and,
optionally, to the current local user. Copy the bootstrap outputs into the
documented GitHub environment settings before running deployment automation.
See [Terraform state](docs/terraform-state.md).

Use `-migrate-state` once so the existing local state is copied into Azure
Blob Storage instead of starting with an empty state. Confirm the migrated
state before archiving the local state files. Later backend initialization may
use `-reconfigure`.

## Planning and deployment

The ignored `terraform.tfvars` contains the active local full-demo values. The
tracked `terraform.tfvars.example` is the safe template and documents the
bootstrap, full, and secure option sets. After backend initialization:

```powershell
# Full demonstration
terraform -chdir=terraform/root plan -out=tfplan

# Cost-safe/core configuration
terraform -chdir=terraform/root plan `
  -var="enable_key_vault=false" `
  -var="enable_key_vault_private_endpoint=false" `
  -var="enable_aks_demo=false" `
  -var="enable_edge_stack=false" `
  -var="enable_apim=false"
```

The recommended deployment path is the manual `controlled-demo-deployment`
workflow. It creates a saved plan, uploads it for review, and requires the
`demo-apply` environment before applying the exact plan. Full deployments then:

1. resolve the CI-published SHA image to its immutable digest;
2. obtain Terraform outputs without committing GUIDs or generated addresses;
3. render Kubernetes configuration and reject remaining placeholders;
4. install the pinned monitoring chart and provision its dashboard;
5. deploy the application, wait for rollout, and smoke-test through App Gateway.

Create `demo-secret` during the Key Vault bootstrap stage. Never commit its
value. Detailed prerequisites are in [pipeline documentation](pipelines/README.md).

## Resource locks and destroy

To demonstrate deletion protection safely:

```text
apply secure -> demonstrate protection -> apply full -> destroy full
```

Do not destroy with the secure profile. The workflow rejects that operation.
The root state backend is separate and is not destroyed with the landing zone.

## Validation and image publication

`validate-build-publish` runs on pull requests and pushes to `main`:

- Terraform format, validation, and Trivy IaC scanning;
- Python syntax and unit tests;
- Kustomize rendering, kubeconform, and Trivy Kubernetes scanning;
- YAML and JSON parsing;
- one Docker build and two-stage image vulnerability reporting/gating;
- CycloneDX SBOM generation.

Pull requests never publish. On `main`, the exact scanned image is pushed to
GHCR using only the Git commit SHA tag. All HIGH/CRITICAL findings are reported;
fixable HIGH/CRITICAL image vulnerabilities fail the pipeline. Unfixed findings
remain visible but do not block this development image.

## Cost impact

| Resource | Purpose | Cost category | Optional |
|---|---|---|---|
| Backend resource group | Isolate state lifecycle | Negligible | Required for remote state |
| Standard LRS storage account | Versioned, locked Terraform state | Low/negligible | Required for remote state |
| Private blob container | Store environment state | No separate charge | Required for remote state |
| Entra application, service principal, and federated credentials | Keyless GitHub OIDC identity | No separate charge | Required for deployment automation |
| Backend RBAC assignments | Keyless local/CI access | No charge | Assign only required principals |
| Key Vault private endpoint | Private AKS-to-vault data path | Low recurring | Disabled in core/bootstrap |
| Private DNS zone | Resolve the vault hostname privately | Low/negligible | Disabled with the endpoint |
| VNet DNS link/zone group | Integrate DNS and endpoint | No or negligible separate charge | Disabled with the endpoint |

Application Gateway WAF_v2, APIM Developer, AKS, and the internal load balancer
remain the dominant costs. The `core` and bootstrap profiles avoid them.

## Development limitations

- The public frontend is HTTP until an owned domain and trusted certificate are
  available.
- AKS uses a public API endpoint; optional authorized CIDRs can reduce exposure.
- The single small node, ephemeral Prometheus data, disabled Alertmanager, and
  APIM Developer tier are deliberate non-production choices.
- GitHub-hosted runners require the state storage data endpoint to be publicly
  reachable; Entra RBAC, disabled shared keys, TLS, and private containers still
  protect access. A private runner would enable a private storage endpoint.
