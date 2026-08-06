# Application Gateway WAF_v2 Frontend

The `terraform/03-edge` module provides the public WAF-enabled frontend for the
internal API Management gateway.

## Ownership Change

The legacy demonstration used the AKS-managed Application Gateway Ingress
Controller add-on to program this gateway directly from Kubernetes Ingress:

```text
APIM -> Application Gateway -> AGIC -> AKS
```

That design placed the WAF behind a public APIM endpoint and would create a
routing loop if APIM were simply moved behind the same gateway.

The corrected design removes AGIC ownership from this Application Gateway:

```text
Client -> Application Gateway WAF_v2 -> internal APIM -> AKS internal LoadBalancer
```

Terraform now owns the gateway backend pool, probe, HTTP settings, listener,
and routing rule. The previous `ignore_changes` list for AGIC-managed child
collections has been removed.

## Terraform Resources

| Resource | Name pattern | Purpose |
|---|---|---|
| Standard public IP | `pip-appgw-<project>-<environment>` | Public frontend address. |
| WAF policy | `wafpol-<project>-<environment>` | Microsoft Default Rule Set 2.2 in Detection mode. |
| Application Gateway | `appgw-<project>-<environment>` | Capacity-one WAF_v2 reverse proxy. |

## APIM Backend Configuration

When APIM is enabled, the gateway uses:

- APIM private VIPs in the backend pool;
- HTTPS on backend port 443;
- the default APIM gateway hostname as Host header and SNI name;
- certificate-chain and SNI validation;
- the APIM `/status-0123456789abcdef` health endpoint;
- a 120-second probe timeout, eight-failure threshold, and 180-second request
  timeout.

The public listener remains HTTP port 80 as a temporary demonstration listener.
WAF Detection mode observes rule matches but does not block them.

If the edge stack is enabled without APIM, Terraform retains an empty bootstrap
backend so the gateway resource remains independently plannable. That mode is
diagnostic only and does not expose the application.

## Networking

The Application Gateway subnet keeps the required rules:

- Internet to TCP 80 for the temporary public listener;
- Internet to TCP 443 for the future HTTPS listener;
- `GatewayManager` to TCP 65200-65535 with destination `*`.

Application traffic leaves the gateway subnet for the APIM subnet on TCP 443.
The direct Application Gateway-to-AKS NSG rule has been removed from the target
path.

## AGIC Consequences

AGIC is no longer enabled on AKS because a controller watching the legacy
Ingress would overwrite Terraform's APIM backend configuration. The three AGIC
role assignments are therefore no longer required and are expected to be
destroyed during migration.

The legacy `app/k8s/ingress.yaml` file is retained as a diagnostic reference but
is excluded from Kustomize. An existing deployed Ingress must be removed by an
operator after the new path is verified; this repository review does not run
that deletion.

## TLS Boundary

Application Gateway-to-APIM traffic uses HTTPS. Client-to-Application Gateway
traffic remains HTTP until an approved public hostname and certificate are
available. Production hardening requires:

1. a public DNS record for the application hostname;
2. a trusted certificate stored through an approved secret path;
3. an HTTPS listener and SNI configuration;
4. HTTP-to-HTTPS redirection;
5. WAF tuning followed by evaluated Prevention mode.
