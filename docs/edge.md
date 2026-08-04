# Application Gateway WAF_v2 and AGIC

The `terraform/03-edge` module provides public layer-7 ingress and WAF
inspection. The `terraform/04-workloads` module connects AKS to the existing
gateway through the managed Application Gateway Ingress Controller (AGIC)
add-on.

## Architecture

```text
APIM or Internet
  -> Standard static public IP
  -> Application Gateway WAF_v2 and WAF policy
  -> AGIC-managed Kubernetes Ingress
  -> ClusterIP Service
  -> application pods
```

AGIC watches Kubernetes Ingress resources and programs Application Gateway
listeners, backend pools, HTTP settings, probes, and routing rules. It is an AKS
managed add-on, not a separate gateway or Helm installation.

## Terraform Resources

| Resource | Name pattern | Purpose |
|---|---|---|
| Standard public IP | `pip-appgw-<project>-<environment>` | Public frontend address. |
| WAF policy | `wafpol-<project>-<environment>` | Microsoft Default Rule Set 2.2. |
| Application Gateway | `appgw-<project>-<environment>` | Capacity-one WAF_v2 gateway. |

Resources are created only when `enable_edge_stack = true`. The `edge` output
returns Application Gateway, public IP, and WAF policy details, or `null` when
disabled.

Key inputs:

| Input | Default | Description |
|---|---|---|
| `enable_edge_stack` | `false` | Enables the public IP, WAF policy, and gateway. |
| `app_gateway_subnet_id` | Required | Dedicated Application Gateway subnet. |
| `waf_policy_mode` | `Detection` | `Detection` or `Prevention`. |
| `health_probe_path` | `/health` | Bootstrap backend probe path. |
| `application_gateway_capacity` | `1` | Fixed WAF_v2 instance capacity. |

## Bootstrap Configuration

Application Gateway requires a complete configuration before AGIC is active.
Terraform supplies:

- a public frontend on HTTP port 80;
- an empty backend pool;
- an HTTP backend setting on port 80;
- a `/health` probe;
- one listener and one Basic routing rule.

The empty pool does not define a synthetic AKS backend. After the application
Ingress is applied, AGIC discovers the actual pod endpoints.

## Ownership and Drift

Terraform owns the gateway resource, WAF SKU and capacity, subnet, public IP,
tags, and WAF policy. AGIC owns the gateway's Ingress-derived child
configuration.

The scoped lifecycle rule ignores only AGIC-managed collections:

- backend pools and HTTP settings;
- listeners, frontend ports, probes, and routing rules;
- redirects, rewrite sets, and URL path maps.

It does not use `ignore_changes = all`. HTTPS changes require an explicit
ownership review so Terraform and AGIC do not manage the same listener or
frontend configuration.

## Managed Identity Permissions

When AKS and edge are enabled, AKS creates the AGIC add-on identity. Terraform
assigns that identity:

| Scope | Role |
|---|---|
| Application Gateway | `Network Contributor` |
| Network resource group | `Reader` |
| Application Gateway subnet | `Network Contributor` |

No subscription-wide assignment is created.

## Network Requirements

When edge is enabled, the Application Gateway NSG permits:

- `Internet` to TCP 80 for the bootstrap listener;
- `GatewayManager` to TCP 65200-65535 for platform management;
- the existing TCP 443 path for future HTTPS;
- Application Gateway to the AKS subnet on TCP 80 and 443.

Azure's default load-balancer and outbound platform rules remain in place. See
[`network-security.md`](network-security.md) for the complete traffic matrix.

## TLS Boundary

The bootstrap listener is HTTP-only. WAF inspection does not provide transport
encryption. Before production use:

1. provision a certificate through the approved certificate-management path;
2. add an HTTPS listener and HTTP-to-HTTPS redirect;
3. review AGIC and Terraform ownership of certificate-related blocks;
4. remove the public HTTP rule after HTTPS verification.

The repository contains no certificate, private key, password, or Kubernetes
TLS Secret.

## Deployment Order

1. Enable and apply the edge module while AKS remains disabled.
2. Enable AKS and edge together so the managed add-on references the existing
   gateway and Terraform can assign its identity roles.
3. Configure workload-identity markers and the immutable application image tag.
4. Apply `app/k8s` through Kustomize.
5. Verify AGIC reconciliation, gateway backend health, WAF policy association,
   and application routing.
