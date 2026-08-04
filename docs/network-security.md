# Network Security Traffic Matrix

This document describes the NSG rules prepared in Terraform for the conditional
landing-zone architecture. They have not been applied to Azure.

## Subnet Plan

The default development CIDRs come from the root `subnets` variable. Rules refer
to logical subnet keys, so changing these CIDRs in one place also updates the
resolved rule prefixes.

| Subnet key | Default CIDR | Development NSG name | Intended role |
|---|---|---|---|
| `management` | `10.10.0.0/24` | `nsg-management-alz-dev` | Optional internal administration source |
| `private-endpoints` | `10.10.1.0/24` | `nsg-private-endpoints-alz-dev` | Key Vault and future private endpoints |
| `aks` | `10.10.2.0/24` | `nsg-aks-alz-dev` | Conditional AKS cluster |
| `appgw` | `10.10.3.0/24` | `nsg-appgw-alz-dev` | Conditional Application Gateway |
| `apim` | `10.10.4.0/24` | `nsg-apim-alz-dev` | Reserved for future private APIM networking |

Each subnet retains its existing dedicated NSG and subnet association.

## Approved Traffic Matrix

| Source | Destination | Port | Protocol | Action | Terraform rule | Priority |
|---|---|---:|---|---|---|---:|
| `Internet` | Application Gateway subnet | 443 | TCP | Allow | `internet-to-appgw-https` | 100 inbound |
| `Internet` | Application Gateway subnet | 80 | TCP | Conditional allow | `internet-to-appgw-http-bootstrap` | 110 inbound |
| `GatewayManager` | Application Gateway subnet | 65200-65535 | TCP | Conditional allow | `gateway-manager-to-appgw-infrastructure` | 120 inbound |
| `AzureLoadBalancer` | AKS subnet | 30000-32767 | TCP | Allow | `azure-load-balancer-to-aks-probes` | 100 inbound |
| Application Gateway subnet | AKS subnet | 80, 443 | TCP | Allow | `appgw-to-aks-web` | 200 inbound |
| AKS subnet | Private Endpoints subnet | 443 | TCP | Allow | `aks-to-private-endpoints-https` | 200 inbound |
| AKS subnet | `Internet` | 443 | TCP | Allow | `aks-to-internet-https` | 200 outbound |
| Management subnet | AKS subnet | 22, 3389 | TCP | Conditional allow | `management-to-aks-admin` | 300 inbound |
| Any | Any | Other traffic | Any | Azure default fallback | Built-in NSG rules | 65000+ |

The health-probe rule uses the default Kubernetes NodePort range because the
conditional AKS Service or ingress health-check node port is not finalized.
During the controlled deployment design, replace this range with the exact
generated probe port when practical.

## Rule Behavior and Rationale

- Priorities 100-199 are reserved for essential ingress and Azure platform
  health traffic, 200-299 for application flows, and 300-399 for optional
  administration.
- Azure NSGs are stateful. An allowed connection automatically permits its
  response traffic, so no reverse-direction return rules are created.
- `Internet` and `AzureLoadBalancer` are Azure service tags maintained by the
  platform. `GatewayManager` identifies Application Gateway infrastructure
  traffic. Subnet-to-subnet rules use CIDRs resolved from `var.subnets`.
- There is no Internet-to-AKS or Internet-to-management rule. Future public HTTPS
  terminates only at Application Gateway before forwarding to AKS.
- `enable_management_access` defaults to `false`. Enabling it creates only an
  internal management-to-AKS rule for TCP 22 and 3389; it does not make either
  port public. The rule merely permits network reachability and does not create
  credentials, virtual machines, or listeners.
- The Private Endpoints rule is attached to the `private-endpoints` NSG because
  that is the receiving subnet. Private endpoint network-policy behavior must be
  confirmed when a real private endpoint is introduced.
- Public HTTP 80 and GatewayManager infrastructure rules exist only when
  `enable_edge_stack` is true. HTTP is temporary until Key Vault-backed TLS is
  designed; the existing TCP 443 rule alone does not make the HTTP listener
  reachable.
- Application Gateway relies on Azure's built-in `AzureLoadBalancer` inbound and
  Internet outbound rules. They are not duplicated, and no outbound deny is
  added to the dedicated gateway subnet.

## Default Deny Decision

No custom blanket deny rule is added. Azure-created NSGs already contain
`DenyAllInbound` and `DenyAllOutBound`, and they also include higher-precedence
platform defaults such as `AllowVNetInBound`, `AllowVnetOutBound`,
`AllowAzureLoadBalancerInBound`, and `AllowInternetOutBound`. A premature custom
deny could disrupt AKS node/pod communication, DNS, bootstrap, load-balancer
health probes, or future Application Gateway platform traffic.

Consequently, these rules encode the explicitly approved application paths but
do not claim to provide production microsegmentation against every Azure default
allow. Before production enforcement, enumerate the final AKS and Application
Gateway dependencies, narrow the probe port, and then assess scoped deny rules or
an egress firewall without blocking platform-required traffic.

## Deferred Scope

- Application Gateway WAF_v2, its WAF policy, and Standard static Public IP are
  implemented conditionally but remain disabled and undeployed.
- The conditional Developer-tier APIM stage currently uses its public gateway
  and the Application Gateway public frontend. It does not use the reserved
  `apim` subnet, so that subnet receives no speculative APIM rule. Private APIM
  networking and its exact platform flows remain deferred.
- Key Vault and private endpoints remain optional or absent. The HTTPS rule is
  prepared for their future use.
- Prometheus and Grafana run inside AKS when deliberately installed, so the
  monitoring assets need no separate subnet-to-subnet NSG rules.
- AKS and Key Vault remain disabled by default. These rules create no cost until
  a future Terraform apply is explicitly approved.
- See `docs/edge.md` for the AGIC ownership, HTTP bootstrap, scoped RBAC, TLS
  follow-up, cost controls, and final deployment sequence.
- See `docs/apim.md` for the API contract, policy, backend wiring, cost controls,
  and future hardening boundary.
