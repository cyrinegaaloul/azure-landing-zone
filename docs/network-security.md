# Network Security

## Subnets

| Subnet | Default CIDR | Function |
|---|---|---|
| `management` | `10.10.0.0/24` | Reserved administrator path; disabled by default. |
| `private-endpoints` | `10.10.1.0/24` | Key Vault private endpoint with NSG policy enabled. |
| `aks` | `10.10.2.0/24` | AKS nodes, Azure CNI pods, and internal LoadBalancer. |
| `appgw` | `10.10.3.0/24` | Dedicated Application Gateway v2 subnet. |
| `apim` | `10.10.4.0/24` | Internal API Management subnet. |

## Enforced application path

Custom allows are evaluated before priority-4000 denies that override Azure's
default `AllowVNetInBound` and `AllowVNetOutBound` rules.

| Source | Destination | Ports | Purpose |
|---|---|---|---|
| Internet | App Gateway | TCP 80 | Development frontend only. |
| GatewayManager | App Gateway | TCP 65200-65535 | Required v2 infrastructure. |
| App Gateway subnet | APIM subnet | TCP 443 | Trusted HTTPS backend. |
| ApiManagement | APIM subnet | TCP 3443 | Required APIM control plane. |
| AzureLoadBalancer | APIM subnet | TCP 6390 | Required APIM probes. |
| APIM subnet | AKS subnet | TCP 80 | Internal application backend. |
| AzureLoadBalancer | AKS subnet | TCP 30000-32767 | AKS service probes. |
| AKS subnet | Private endpoints | TCP 443 | Private Key Vault access. |

Self-subnet rules preserve Application Gateway scale-unit, APIM instance, and
AKS node/Azure CNI communication. APIM also receives explicit outbound rules
for its documented Azure dependencies: Internet HTTP, Storage HTTPS, SQL,
Key Vault, Azure Monitor, and Azure-provided DNS. AKS retains HTTPS access for
image pulls and Azure platform endpoints.

After approved paths, VNet inbound/outbound denies prevent arbitrary subnets
from reaching App Gateway, APIM, AKS, or the Key Vault endpoint. Internet has no
direct APIM or AKS listener. NSGs are stateful, so response traffic does not
need mirrored rules.

## Private endpoint DNS

The full profile creates `privatelink.vaultcore.azure.net`, links it to the
landing-zone VNet, and associates it with the Key Vault private endpoint. AKS
therefore resolves the standard vault hostname to the endpoint address. The
provider's private-endpoint NSG policy is enabled on the dedicated subnet so
the allow/deny rules are effective.

## Kubernetes NetworkPolicy

The application policy allows APIM traffic, AKS node/probe traffic, Prometheus
scraping, DNS, and private-endpoint HTTPS. Other selected-pod ingress and egress
is denied. Workload Identity token projection and the node-level CSI provider
remain functional because the policy selects only the application pod.

Authorized source CIDRs are rendered from Terraform outputs rather than copied
manually into a deployment manifest.
