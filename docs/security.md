# Security Model

This document describes implemented security controls, optional controls, and
deployment-time security configuration for the landing zone. It does not add
Azure Defender, a Key Vault private endpoint, or other paid security services.

## Implemented Controls

- Azure RBAC authorization for Key Vault; no Key Vault access policies.
- AKS OIDC issuer and Microsoft Entra Workload Identity.
- Secrets Store CSI Driver integration without synchronizing values into a
  Kubernetes Secret.
- Resource- and resource-group-scoped role assignments; no subscription-scoped
  Contributor, Owner, or User Access Administrator assignment.
- Application Gateway WAF_v2 with Microsoft Default Rule Set 2.2.
- Explicit NSG rules for the Application Gateway, internal APIM, AKS, and
  reserved private-endpoint subnets.
- Non-root Kubernetes containers with dropped capabilities, seccomp, and a
  read-only root filesystem.
- CI validation and Trivy scans for Terraform, rendered Kubernetes resources,
  monitoring configuration, and the locally built container image.

## RBAC Model

| Principal | Role | Scope | Purpose | Activation |
|---|---|---|---|---|
| Platform administrators Entra group | Contributor | Foundation resource group | Manage platform resources without managing Azure RBAC. | Group object ID is non-null. |
| Network operators Entra group | Network Contributor | Network resource group | Manage VNet, subnets, NSGs, Application Gateway, and related networking. | Group object ID is non-null. |
| Security readers Entra group | Security Reader | Security resource group | Inspect security configuration without changing resources. | Group object ID is non-null. |
| Application user-assigned managed identity | Key Vault Secrets User | Specific Key Vault | Read secret values through the CSI provider. | AKS and Key Vault are enabled. |
| AKS system-assigned identity | Network Contributor | AKS subnet | Manage the internal Kubernetes LoadBalancer and required network interfaces. | AKS is enabled. |

The generic `role_assignments` map remains available for reviewed
resource-group assignments. Its `scope_key` must resolve to a resource group
created by the foundation module. Do not use it to reproduce subscription-wide
permissions.

No AGIC identity or AGIC role assignment remains. Terraform owns Application
Gateway because the gateway fronts internal APIM rather than Kubernetes
Ingress.

## Workload Identity and Secret Access

```text
AKS pod
  -> Kubernetes ServiceAccount token
  -> AKS OIDC issuer
  -> federated identity credential
  -> application user-assigned managed identity
  -> Key Vault Secrets User on one vault
  -> Secrets Store CSI volume
```

Terraform defines the federation subject as
`system:serviceaccount:demo:landing-zone-demo`. The ServiceAccount and
SecretProviderClass must both use the application identity's client ID. The
SecretProviderClass tenant must match the deployment tenant.

The tracked manifests deliberately contain
`REPLACE_WITH_MANAGED_IDENTITY_CLIENT_ID` and `REPLACE_WITH_TENANT_ID`. After
Terraform deployment, obtain the client ID from the sensitive `workloads`
output and the tenant ID from the secure deployment configuration. Replace the
markers locally without committing the resulting manifests or identifiers.

Secret values must be created directly in Key Vault through an approved
operator workflow. They must not be stored in Terraform variables, GitHub
workflow files, Kubernetes manifests, or Git-tracked variable files.

## Key Vault

| Setting | Development default | Protected environment guidance |
|---|---|---|
| RBAC authorization | Enabled | Keep enabled. |
| Soft-delete retention | 7 days | Review retention requirements before first deployment. |
| Purge protection | Disabled | Enable only after accepting that it cannot be disabled. |
| Public network access | Enabled | Disable after private endpoint and DNS connectivity are implemented and tested. |

`enable_key_vault_purge_protection` and
`key_vault_public_network_access_enabled` control these settings. A private
endpoint is intentionally deferred; the reserved subnet currently contains no
private endpoint.

## Resource Locks

`enable_resource_group_locks` defaults to `false`. When enabled, Terraform
adds `CanNotDelete` locks to the network and security resource groups. This
protects shared resources while allowing updates.

Locks must be removed or disabled before an intentional destroy. They remain
off in development and safe profiles so normal cleanup is not blocked.

## WAF and Network Controls

The WAF policy uses Microsoft Default Rule Set 2.2. `Detection` remains the
development default so application behavior can be observed before enforcement.
Use `Prevention` only after reviewing WAF logs and testing the API paths. No
rule exclusions or disabled managed rules are configured.

Internet ingress is limited to Application Gateway listener ports. AKS has no
direct Internet ingress rule. The broad-looking `GatewayManager` destination
and APIM service-tag rules are required Azure platform flows and must not be
replaced with generic Internet or allow-all rules. Management SSH/RDP is an
internal subnet-to-subnet rule and remains disabled by default.

## Development Defaults

```hcl
platform_admin_group_object_id          = null
network_operator_group_object_id        = null
security_reader_group_object_id         = null
enable_resource_group_locks             = false
enable_key_vault_purge_protection       = false
key_vault_public_network_access_enabled = true
waf_policy_mode                         = "Detection"
```

For a protected demonstration, supply existing Entra security-group object IDs,
enable the resource-group locks, and evaluate WAF `Prevention`. Do not use
personal user object IDs or fabricated GUIDs.

## Manual Setup

1. Create the three optional Microsoft Entra security groups outside Terraform.
2. Supply their object IDs through an ignored `.tfvars` file or `TF_VAR_*`
   environment variables.
3. Review the plan to confirm each assignment is at the intended resource group.
4. After AKS deployment, populate the Kubernetes identity markers locally.
5. Create `demo-secret` directly in Key Vault without recording its value in
   Terraform state or Git.

The manual deployment workflow uses GitHub OIDC federation with short-lived
tokens. Configure an Entra application or managed identity to trust the
repository's protected `demo` environment, then store only its client ID,
tenant ID, and subscription ID as environment secrets. Do not add a client
secret or credentials JSON.

## Future Hardening

- Add a Key Vault private endpoint, private DNS, and tested network rules before
  disabling public access.
- Add a trusted public certificate and HTTPS listener to Application Gateway.
- Review WAF telemetry before enabling Prevention.
- Move Terraform state to a protected remote backend with locking and RBAC.
- Replace broad built-in roles with reviewed custom roles if operational needs
  justify the additional maintenance.
