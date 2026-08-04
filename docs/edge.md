# Application Gateway WAF_v2 and AGIC

This stage prepares a traditional Azure Application Gateway edge for the final
AKS demonstration. All edge resources and the AGIC integration are disabled by
default and have not been deployed.

```text
Internet
  -> Standard static Azure Public IP
  -> Application Gateway WAF_v2 + WAF policy
  -> AKS-managed Application Gateway Ingress Controller (AGIC)
  -> demo/landing-zone-demo-app Kubernetes Ingress
  -> ClusterIP Service on port http/80
  -> application pods on port 8080
```

Application Gateway is the Azure layer-7 proxy and WAF. AGIC is an AKS add-on
that watches Kubernetes Ingress resources and translates them into Application
Gateway listeners, backend pools, HTTP settings, probes, and routing rules. AGIC
is not installed with Helm and is not a second gateway.

## Why This Design

The explicitly managed gateway uses `WAF_v2`, because the AKS add-on can create
only `Standard_v2` when it creates a gateway itself. Terraform therefore creates
the WAF_v2 gateway first and supplies its resource ID to the managed add-on. The
gateway uses the dedicated `appgw` subnet; no unrelated resource belongs there.

The associated WAF policy enables Microsoft Default Rule Set 2.2 and defaults to
`Detection`. Detection records matches without immediately blocking the first
demo traffic, allowing false positives to be reviewed before an intentional
switch to `Prevention`. No custom WAF exclusions or broad allow/block rules are
configured. This stage does not add a diagnostic log destination; durable WAF
request-log collection remains deferred with the wider monitoring design.

## Conditional Resources

`enable_edge_stack = false` is the default. When it remains false, Terraform
creates no edge Public IP, WAF policy, or Application Gateway. When true, the
`terraform/03-edge` module prepares:

- `pip-appgw-<project>-<environment>`: Standard SKU, static Public IP;
- `wafpol-<project>-<environment>`: enabled WAF policy using DRS 2.2;
- `appgw-<project>-<environment>`: capacity-one WAF_v2 gateway in the existing
  `appgw` subnet, with the WAF policy associated globally.

`waf_policy_mode` accepts only `Detection` or `Prevention` and defaults to
`Detection` everywhere.

## Bootstrap Configuration

Azure requires a minimally complete Application Gateway configuration before
AGIC exists. Terraform supplies uniquely named bootstrap-only blocks:

- public frontend IP configuration;
- HTTP frontend port 80;
- empty backend address pool;
- HTTP backend setting on port 80 with a 30-second timeout;
- `/health` HTTP probe every 30 seconds, with a 10-second timeout and threshold 3;
- one HTTP listener;
- one Basic routing rule with priority 100.

The empty pool does not invent an AKS backend. After the Ingress is deployed,
AGIC discovers the real pod endpoints and programs the gateway.

## AGIC Ownership and Terraform Drift

AGIC owns the gateway's backend pools, backend HTTP settings, frontend ports,
HTTP listeners, probes, redirects, routing rules, rewrite sets, and URL path
maps. AzureRM represents many of these as sets, so an AGIC change can otherwise
appear as a complete remove/re-add diff.

Terraform selectively ignores only those AGIC-managed nested blocks. It still
owns and detects drift for the gateway resource, WAF_v2 SKU/capacity, subnet,
public frontend IP configuration, tags, and global WAF policy. The configuration
does not use `ignore_changes = all`. Future TLS certificates remain Terraform or
Key Vault concerns rather than being silently ignored. Adding HTTPS will require
an explicit ownership review and adjustment of the ignored listener/frontend
sets so Terraform and AGIC do not compete over certificate-related blocks.

## Managed Add-on and Permissions

`terraform/04-workloads` adds `ingress_application_gateway { gateway_id = ... }`
only when both `enable_aks_demo` and `enable_edge_stack` are true. Supplying only
`gateway_id` prevents AKS from creating a second Standard_v2 gateway.

AKS creates the AGIC add-on managed identity. Terraform does not invent another
identity. Because AKS uses the foundation resource group while Application
Gateway uses the network resource group, Terraform assigns the generated add-on
identity:

- `Network Contributor` on the Application Gateway resource;
- `Reader` on the network resource group;
- `Network Contributor` on the dedicated Application Gateway subnet.

The principal ID is known after AKS creation, which Terraform can carry into the
role assignments during the same apply. No Owner or subscription-wide role is
used. Identity replication checks are skipped for these managed-identity role
assignments to avoid a transient Microsoft Entra propagation race. AGIC may
briefly report authorization errors until the post-cluster role assignments are
created and its reconciliation retries.

## HTTP Demo and Future HTTPS

The initial demo listener is HTTP port 80 because no certificate strategy exists
yet. The edge switch conditionally adds a temporary `Internet`-to-`appgw` NSG
rule for TCP 80. The existing TCP 443 rule remains preparation for HTTPS. WAF
inspection does not replace TLS encryption.

Before any non-demo use:

1. provision a certificate through an approved Key Vault integration;
2. add an HTTPS listener using the Key Vault certificate reference;
3. redirect HTTP to HTTPS;
4. verify AGIC ownership and certificate rotation;
5. remove the temporary public TCP 80 rule.

No PFX, private key, certificate password, Kubernetes TLS Secret, hostname, or
certificate material is stored in this repository.

## Network Requirements

When edge is enabled, the `appgw` NSG adds:

- temporary `Internet` inbound TCP 80 at priority 110;
- `GatewayManager` inbound TCP 65200-65535 at priority 120.

The existing TCP 443 public rule remains priority 100. Azure's built-in
`AllowAzureLoadBalancerInBound` and `AllowInternetOutBound` rules are retained,
so they are not duplicated or overridden. No custom outbound deny is added.
Application Gateway can reach the AKS subnet on the already prepared TCP 80/443
rule.

## Cost and Deployment Sequence

Application Gateway WAF_v2 is continuously billed while deployed. Keep
`enable_edge_stack = false` during normal development and enable it only for an
approved final evidence window.

The controlled deployment order is:

1. review a root Terraform plan with edge enabled and AKS still disabled;
2. create networking and the WAF_v2 edge through an approved Terraform apply;
3. enable both AKS and edge so the managed AGIC add-on references the existing
   gateway and receives its scoped roles;
4. replace Kubernetes workload identity markers and immutable image tag;
5. render and apply the application Kustomization, including `ingress.yaml`;
6. verify AGIC, backend health, WAF policy association, and HTTP application
   access;
7. capture evidence and immediately run the approved Terraform destroy workflow.

The optional APIM stage is now defined separately in `terraform/05-apim` and
`docs/apim.md`, but remains disabled and undeployed. Application Gateway for
Containers, managed monitoring, and a production certificate design remain
deferred. None of the deployment steps above were run while preparing this
stage.
