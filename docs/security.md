# Security and Identity

## Implemented controls

- Microsoft Entra-backed AKS authentication with Kubernetes RBAC and Azure RBAC
  for Kubernetes enabled; local cluster accounts are disabled.
- OIDC Workload Identity federation from the `demo/landing-zone-demo`
  ServiceAccount to a user-assigned managed identity.
- `Key Vault Secrets User` scoped to the application vault.
- Key Vault RBAC authorization, soft deletion, optional purge protection, and
  public access disabled when the private endpoint is active.
- WAF_v2, subnet NSGs with explicit application paths, Kubernetes NetworkPolicy, restricted Pod
  Security, and hardened non-root containers.
- GitHub OIDC authentication with no Azure client secret or credentials JSON.

## End-to-end secret path

```text
Pod -> ServiceAccount token -> AKS OIDC issuer -> federated managed identity
    -> Key Vault Secrets User -> Private DNS -> private endpoint -> Key Vault
    -> CSI-mounted /mnt/secrets-store/demo-secret -> /secret-status boolean
```

The endpoint proves that the mounted file is readable without disclosing it.
The value is never stored in Git, Terraform variables, Kubernetes Secrets,
logs, metrics, or API responses.

## Human RBAC groups

Terraform conditionally supports three Microsoft Entra groups:

| Group | Azure role and scope |
|---|---|
| Platform administrators | Contributor on the foundation resource group; AKS RBAC cluster admin. |
| Network operators | Network Contributor on the network resource group. |
| Security readers | Security Reader on the security resource group. |

Create and retrieve groups later with a sufficiently privileged Entra account:

```powershell
az ad group create --display-name "alz-platform-administrators" --mail-nickname "alz-platform-admins"
az ad group create --display-name "alz-network-operators" --mail-nickname "alz-network-operators"
az ad group create --display-name "alz-security-readers" --mail-nickname "alz-security-readers"

az ad group show --group "alz-platform-administrators" --query id -o tsv
az ad group show --group "alz-network-operators" --query id -o tsv
az ad group show --group "alz-security-readers" --query id -o tsv
```

Supply the object IDs through ignored tfvars, `TF_VAR_*`, or the documented
GitHub variables. Group creation has no separate Azure resource charge. The
assignments never grant Owner or User Access Administrator.

The one-time Key Vault bootstrap can grant `Key Vault Secrets Officer` to a
specified human object ID. Apply the bootstrap profile, create `demo-secret`
interactively, then apply the full profile; the temporary assignment is removed
when its input returns to null.

## AKS administration

The GitHub deployment service principal's object ID is optional in core
profiles and required for automated Kubernetes deployment. Terraform assigns
`Azure Kubernetes Service RBAC Cluster Admin` at cluster scope. Human platform
administrators receive the same Kubernetes data-plane role through their group.

The AKS API server remains public for an internship environment. Set
`aks_api_server_authorized_ip_ranges` when stable administrator/runner egress
CIDRs are available. Making the cluster private would require a private runner,
VPN, or similar access path and is intentionally future work.

## Locks

The secure profile places `CanNotDelete` locks on network and security resource
groups. Use this lifecycle:

```text
secure apply -> demonstrate protection -> full apply -> full destroy
```

The workflow refuses secure-profile destroy. Purge protection remains disabled
because it is irreversible and would complicate a temporary student deployment.

## Deliberate limitations

- No Defender paid plans, Sentinel, Azure Firewall, Bastion, VPN Gateway, or
  third-party security SaaS.
- No fabricated certificate or domain. The public demo listener is HTTP; the
  App Gateway-to-APIM hop remains trusted HTTPS.
- No secret signing/attestation system was added solely for appearance. The CI
  SBOM and immutable digest provide practical, free supply-chain evidence.
