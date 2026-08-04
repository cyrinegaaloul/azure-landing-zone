# Azure API Management Stage

The `terraform/05-apim` module prepares a small, optional API Management layer
for the demo. It creates one Developer-tier APIM service, imports the repository
OpenAPI document, and applies one API-level policy. The module is disabled by
default and nothing in this stage has been deployed to Azure.

## Request Path

```text
Internet client
    |
    v
Azure API Management public gateway
    |  API contract and policies
    v
Application Gateway WAF_v2 public HTTP frontend
    |  WAF inspection and AGIC-managed routing
    v
AKS Ingress -> ClusterIP Service -> demo pod
```

APIM and Application Gateway have distinct roles. APIM publishes and governs
the API contract. Application Gateway provides the regional WAF and ingress
path. Kubernetes Ingress and AGIC select the in-cluster Service. For this first
stage, APIM uses the real Application Gateway public address produced by the
edge module; no example IP address or fabricated backend is stored in code.

The initial backend scheme is HTTP because the current Application Gateway demo
listener is the documented bootstrap listener. Add a certificate-backed HTTPS
listener and change this backend URL before treating the path as production.

## Published API

`app/openapi.yaml` is an OpenAPI 3.0 document imported by Terraform. It exposes:

- `GET /health`
- `GET /api/info`
- `GET /api/status`

The Prometheus `/metrics` endpoint is deliberately excluded. Metrics remain an
internal observability interface scraped by the in-cluster `ServiceMonitor`, not
a public API operation.

The API is available beneath APIM's `/demo` path after deployment. The final
gateway hostname is assigned by Azure and is returned by the root `apim` output.

## API Policy

The API-level policy:

- limits each client IP to 30 calls per 60 seconds
- adds `X-Correlation-ID` from the APIM request ID only when the caller did not
  already send that header
- forwards the request to Application Gateway without rewriting its body or URL

Subscriptions are not required for this demo API. OAuth, JWT validation,
Microsoft Entra authorization, caching, API versioning, products, and developer
portal customization are intentionally deferred.

## Enablement and Cost Control

Both APIM and the edge stack default to disabled:

```hcl
enable_edge_stack = false
enable_apim       = false
apim_sku_name     = "Developer_1"
```

`enable_apim = true` is rejected unless `enable_edge_stack = true`, because the
gateway is the selected backend. The module accepts only `Developer_1`; this
tier is suitable for development and demonstrations, not production. APIM and
Application Gateway are continuously billed and APIM provisioning can take a
substantial amount of time. Check that the globally scoped APIM name
`apim-${project_name}-${environment}` is available before the final demo.

The existing `apim` subnet remains reserved and unused. This stage deliberately
uses APIM's public gateway and does not introduce VNet injection, private
endpoints, Premium tier, or new NSG rules.

## Controlled Deployment

1. Run the normal validation workflow and review the Terraform plan.
2. Manually run `demo-deploy` with `action=apply`, `enable_edge=true`, and
   `enable_apim=true`. Enable AKS separately only when the complete request path
   is required.
3. Run `terraform -chdir=terraform/root output apim` for the Azure-assigned
   gateway URL and test only the three documented API operations.
4. Run the manual workflow with the same feature toggles and `action=destroy`
   immediately after the demonstration.

Future production work should add end-to-end TLS, a custom domain and managed
certificate, private networking where justified, Microsoft Entra/OAuth
authorization, subscription/product governance, versioning, and a production
APIM tier. Those controls are not part of this cost-constrained stage.
