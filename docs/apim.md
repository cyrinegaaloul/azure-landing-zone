# Internal Azure API Management

The `terraform/05-apim` module deploys classic Developer-tier API Management
in internal VNet mode. It imports the application OpenAPI contract, applies API
policies, forwards requests to a separate AKS internal LoadBalancer, and creates
exact-hostname private DNS records for the APIM endpoints.

## Architecture

The original demonstration used this path:

```text
APIM public gateway -> Application Gateway public IP -> AGIC -> AKS
```

That path is superseded because APIM was publicly reachable and the WAF was
behind the API gateway.

The corrected path is:

```text
Client
  -> Application Gateway WAF_v2 public frontend
  -> API Management private virtual IP
  -> AKS internal LoadBalancer Service
  -> application pods
```

APIM no longer depends on an Application Gateway output. It consumes the
internal AKS backend URL, and the edge module consumes APIM's computed private
IP addresses and gateway hostname. This ordering prevents the routing loop
`Application Gateway -> APIM -> Application Gateway`.

## Terraform Resources

| Resource | Purpose |
|---|---|
| `azurerm_api_management.this` | Developer-tier APIM service injected into the dedicated APIM subnet with `virtual_network_type = "Internal"`. |
| `azurerm_api_management_api.this` | API imported from `app/openapi.yaml` with the `/demo` suffix. |
| `azurerm_api_management_api_policy.this` | Rate limiting, correlation ID, and backend forwarding. |
| `azurerm_private_dns_zone.apim_endpoint` | Exact-FQDN private zones for APIM gateway, portal, developer portal, management, and SCM endpoints. |
| `azurerm_private_dns_a_record.apim_endpoint` | Maps each endpoint hostname to the APIM private VIP. |
| `azurerm_private_dns_zone_virtual_network_link.apim_endpoint` | Makes endpoint records resolvable within the landing-zone VNet. |

The module deliberately does not create a private zone for the shared
`azure-api.net` apex. An apex zone would override public Azure DNS resolution
for unrelated services. Each zone is scoped to one APIM endpoint FQDN.

## Configuration

| Input | Default | Description |
|---|---|---|
| `enable_apim` | `false` | Enables APIM, API, policy, and private DNS resources. |
| `owner` | Required | Globally unique APIM name suffix. |
| `publisher_name` | Module default | Publisher name displayed by APIM. |
| `publisher_email` | Module default | Publisher contact address displayed by APIM. |
| `apim_sku_name` | `Developer_1` | Classic Developer tier, which supports internal VNet injection. |
| `apim_subnet_id` | Required | Repository-reserved, non-delegated APIM subnet. |
| `virtual_network_id` | Required | VNet linked to the exact-hostname private DNS zones. |
| `backend_url` | Required when enabled | Internal AKS LoadBalancer URL. |
| `openapi_spec_path` | Required | OpenAPI document imported into APIM. |

The APIM service name follows
`apim-<project>-<environment>-<owner>`.

## Published API

The API suffix remains `/demo` and subscriptions remain disabled. The imported
operations are:

| Public path through Application Gateway | APIM operation |
|---|---|
| `/demo/health` | `GET /health` |
| `/demo/api/info` | `GET /api/info` |
| `/demo/api/status` | `GET /api/status` |

`/metrics` remains internal to Kubernetes monitoring.

The API policy preserves the existing behavior:

- 30 calls per client IP per 60 seconds;
- `X-Correlation-ID` populated from the APIM request ID when absent;
- normal forwarding to the AKS backend.

## APIM Subnet and NSG Requirements

The `apim` subnet is reserved for APIM in this project and has no delegation.
Azure does not require the subnet to be exclusive to APIM, but this repository
keeps it exclusive for clearer routing and security boundaries. Classic APIM
VNet injection requires an NSG association and no subnet delegation.

The root module conditionally adds these rules when APIM is enabled:

| Direction | Source | Destination | Ports | Purpose |
|---|---|---|---|---|
| Inbound | Application Gateway subnet | APIM subnet | TCP 443 | Gateway requests to the internal APIM gateway. |
| Inbound | `ApiManagement` | APIM subnet | TCP 3443 | Azure APIM control plane. |
| Inbound | `AzureLoadBalancer` | APIM subnet | TCP 6390 | APIM infrastructure health. |
| Outbound | APIM subnet | AKS subnet | TCP 80 | API forwarding to the internal Kubernetes LoadBalancer. |
| Outbound | APIM subnet | `Internet` | TCP 80 | Certificate validation and platform management. |
| Outbound | APIM subnet | `Storage` | TCP 443 | Core storage dependency. |
| Outbound | APIM subnet | `Sql` | TCP 1433 | Core database dependency. |
| Outbound | APIM subnet | `AzureKeyVault` | TCP 443 | Platform certificate and secret dependency. |
| Outbound | APIM subnet | `AzureMonitor` | TCP 1886, 443 | Diagnostics, metrics, and health. |

An additional inbound AKS NSG rule permits APIM-subnet traffic to the internal
application LoadBalancer on TCP 80.

## DNS and TLS

Internal APIM responds only when the request uses a configured APIM hostname.
Application Gateway uses APIM's computed private IPs as backend addresses and
sends the default gateway FQDN as both Host header and TLS SNI name. The default
APIM certificate is publicly trusted, so no repository-managed backend root
certificate or custom APIM domain is required for this demonstration.

The Application Gateway public listener remains HTTP on port 80. Production
exposure requires a public DNS name, a trusted certificate, an HTTPS listener,
and an HTTP-to-HTTPS redirect. No certificate or private key is committed.

## Deployment Prerequisites

1. Confirm that the configured internal AKS LoadBalancer IP is unused.
2. Apply Terraform and allow the Developer-tier VNet update to finish; this can
   take tens of minutes and can interrupt Developer-tier traffic.
3. Apply the Kustomize base to create or update the internal LoadBalancer.
4. Confirm that the Service received the configured private address.
5. Check APIM network status and private DNS resolution.
6. Confirm Application Gateway backend health before external testing.
