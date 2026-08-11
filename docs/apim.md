# API Management

`terraform/05-apim` deploys API Management Developer tier in internal VNet
mode. Its functional role is policy/API mediation between Application Gateway
and the AKS internal service.

## Data path

```text
Application Gateway -> APIM private gateway :443 -> demo API -> AKS ILB :80
```

The module imports `app/openapi.yaml`, publishes the API under `/demo`, and
sets its backend from the conditional AKS output. APIM remains inaccessible
directly from the Internet. Application Gateway preserves the APIM hostname for
TLS/SNI validation.

Required control-plane, probe, dependency, and data-path NSG exceptions are
defined at the root because they span modules. Priority-4000 VNet denies make
those exceptions meaningful rather than relying on Azure's default VNet allow.

Developer tier is appropriate for a non-production demonstration but is
billable and has no production SLA. The core and Key Vault bootstrap profiles
do not create APIM. Premium/multi-region APIM, custom domains, client
certificates, and production capacity are intentionally outside project scope.
