# Application Gateway Edge

`terraform/03-edge` creates a Terraform-owned Standard_v2 public IP,
Application Gateway WAF_v2, and WAF policy. It does not use AGIC or a Kubernetes
Ingress resource.

## Routing

```text
HTTP client :80 -> WAF -> App Gateway -> HTTPS :443 -> internal APIM
```

The backend pool uses APIM private addresses. The backend hostname and SNI are
the APIM gateway hostname, certificate-chain and SNI validation remain enabled,
and the health probe uses APIM's status endpoint. Terraform owns every gateway
child object; there is no competing Kubernetes controller.

## WAF modes

- Full development profile: Detection, allowing rule tuning and demonstration.
- Secure profile: Prevention after the expected API traffic is validated.

## Public HTTP limitation

The listener remains HTTP because this project has no owned public domain and
no trusted certificate. A self-signed certificate would not create a correctly
trusted client endpoint and is not committed. When a domain is available,
add DNS ownership, a trusted certificate, an HTTPS listener, and HTTP redirect.
The module's separation of frontend, listener, and backend settings supports
that later change.
