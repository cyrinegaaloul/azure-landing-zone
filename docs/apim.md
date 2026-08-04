# Azure API Management

The `terraform/05-apim` module provides the external API gateway for the
application. It imports the OpenAPI contract, applies API policies, and forwards
requests to Application Gateway.

## Architecture

```text
Internet
  -> Azure API Management
  -> Application Gateway WAF_v2
  -> AGIC-managed Kubernetes Ingress
  -> ClusterIP Service
  -> application pods
```

APIM governs the API contract and request policies. Application Gateway
provides regional ingress and WAF inspection. Kubernetes Ingress maps the
resulting request to an in-cluster Service.

## Terraform Resources

| Resource | Purpose |
|---|---|
| `azurerm_api_management.this` | Developer-tier APIM service. |
| `azurerm_api_management_api.this` | API imported from `app/openapi.yaml`. |
| `azurerm_api_management_api_policy.this` | Rate limiting, correlation ID, and backend forwarding. |

All resources use `count` and are created only when `enable_apim = true`.

## Configuration

Key module inputs:

| Input | Default | Description |
|---|---|---|
| `enable_apim` | `false` | Enables APIM resources. |
| `apim_sku_name` | `Developer_1` | Development SKU; other SKUs are rejected by validation. |
| `backend_url` | `null` | Application Gateway frontend URL. |
| `openapi_spec_path` | Required | Path to the OpenAPI document. |

The root module derives `backend_url` from the Application Gateway public IP.
It rejects `enable_apim = true` unless `enable_edge_stack = true`; no placeholder
IP address is used.

The aggregate `apim` output returns the service ID, service name, gateway URL,
API name, and backend URL. It returns `null` when APIM is disabled.

## Published API

`app/openapi.yaml` publishes these operations beneath the APIM `/demo` path:

| Operation | Purpose |
|---|---|
| `GET /health` | Application health. |
| `GET /api/info` | Application and platform information. |
| `GET /api/status` | Runtime status. |

`/metrics` is excluded because Prometheus consumes it inside the cluster.

## API Policy

The API-level policy:

- limits each client IP to 30 calls per 60 seconds;
- sets `X-Correlation-ID` from the APIM request ID when the caller does not
  supply the header;
- forwards the request to Application Gateway without rewriting the URL or
  body.

The API does not require APIM subscriptions. OAuth, JWT validation, Microsoft
Entra authorization, caching, products, versioning, and developer portal
configuration are outside this module.

## Networking and TLS

The module uses APIM's public gateway and does not use the reserved `apim`
subnet. The current backend uses the Application Gateway HTTP bootstrap
listener. Production use requires end-to-end HTTPS, a custom domain and
certificate, an evaluated private-networking topology, and a production APIM
SKU.

## Deployment

1. Enable the edge stack and APIM in the root configuration.
2. Review the root Terraform plan.
3. Apply through the protected manual workflow.
4. Read the assigned gateway URL:

   ```powershell
   terraform -chdir=terraform/root output apim
   ```

5. Verify only the operations defined in `app/openapi.yaml`.
