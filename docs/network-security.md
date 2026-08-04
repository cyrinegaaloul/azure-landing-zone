# Network Security Traffic Matrix

This document defines the Network Security Group (NSG) rules implemented by the
networking and root Terraform modules. Rules use logical subnet keys so CIDR
changes remain centralized in the root `subnets` variable.

## Subnets

| Subnet key | Default CIDR | NSG name | Purpose |
|---|---|---|---|
| `management` | `10.10.0.0/24` | `nsg-management-alz-dev` | Optional administrative source. |
| `private-endpoints` | `10.10.1.0/24` | `nsg-private-endpoints-alz-dev` | Key Vault and other private endpoints. |
| `aks` | `10.10.2.0/24` | `nsg-aks-alz-dev` | AKS nodes and workload traffic. |
| `appgw` | `10.10.3.0/24` | `nsg-appgw-alz-dev` | Application Gateway WAF_v2. |
| `apim` | `10.10.4.0/24` | `nsg-apim-alz-dev` | Reserved for a future private APIM topology. |

Each subnet has a dedicated NSG and subnet association.

## Traffic Matrix

| Source | Destination | Port | Protocol | Action | Rule | Priority |
|---|---|---:|---|---|---|---:|
| `Internet` | Application Gateway | 443 | TCP | Allow | `internet-to-appgw-https` | 100 inbound |
| `Internet` | Application Gateway | 80 | TCP | Conditional allow | `internet-to-appgw-http-bootstrap` | 110 inbound |
| `GatewayManager` | Application Gateway | 65200-65535 | TCP | Conditional allow | `gateway-manager-to-appgw-infrastructure` | 120 inbound |
| `AzureLoadBalancer` | AKS | 30000-32767 | TCP | Allow | `azure-load-balancer-to-aks-probes` | 100 inbound |
| Application Gateway | AKS | 80, 443 | TCP | Allow | `appgw-to-aks-web` | 200 inbound |
| AKS | Private endpoints | 443 | TCP | Allow | `aks-to-private-endpoints-https` | 200 inbound |
| AKS | `Internet` | 443 | TCP | Allow | `aks-to-internet-https` | 200 outbound |
| Management | AKS | 22, 3389 | TCP | Conditional allow | `management-to-aks-admin` | 300 inbound |
| Any | Any | Other traffic | Any | Azure default fallback | Built-in NSG rules | 65000+ |

Conditional rules are created by root locals:

- `enable_edge_stack` controls the HTTP bootstrap and `GatewayManager` rules;
- `enable_management_access` controls the internal SSH/RDP rule.

## Rule Design

- Priorities 100-199 are reserved for ingress and Azure platform traffic,
  200-299 for application flows, and 300-399 for optional administration.
- NSGs are stateful; response traffic for an allowed connection does not require
  a reverse rule.
- Azure service tags are used for `Internet`, `AzureLoadBalancer`, and
  `GatewayManager` traffic.
- Subnet-to-subnet rules resolve CIDRs from `var.subnets` rather than embedding
  addresses in resource definitions.
- There is no direct Internet path to AKS or the management subnet.
- The management rule permits reachability only; it does not create hosts,
  credentials, or listeners.

The AKS probe rule currently uses the Kubernetes NodePort range. Narrow it to
the final health-check port when the deployed ingress configuration provides a
stable value.

## Default Rules

No custom blanket deny rule is defined. Azure NSGs already include default
allow and deny rules, including VNet, load-balancer, Internet-outbound, and
deny-all fallbacks. Introducing a higher-priority blanket deny without the final
platform dependency set could interrupt AKS networking, DNS, health probes, or
Application Gateway management traffic.

Before production enforcement, validate all required platform flows and then
evaluate scoped deny rules or centralized egress controls.

## Deferred Networking

- The reserved `apim` subnet is unused because the current Developer-tier APIM
  module uses its public gateway and the Application Gateway public frontend.
- Key Vault private endpoints and their network policies are not implemented.
- Prometheus and Grafana run inside AKS and require no separate subnet.

See [`edge.md`](edge.md) for gateway ownership and bootstrap details and
[`apim.md`](apim.md) for the API gateway topology.
