# Managed ingress and observability

## Application routing

```text
Internet
  -> Application Gateway + WAF
  -> internal API Management
  -> AKS Application Routing managed NGINX ingress (private IP)
  -> ClusterIP Service
  -> frontend Pod

APIM -> P4D backend (unchanged)
```

AKS Application Routing is used instead of AGIC. AGIC would make Application
Gateway a Kubernetes-controlled ingress tier and conflicts with this project's
intentional Application Gateway/WAF -> APIM boundary. The Application Routing
add-on is Azure-supported, owns only the downstream AKS NGINX controller, and
is configured with an internal LoadBalancer and the existing reserved AKS IP.
APIM therefore remains the only caller of the AKS ingress endpoint.

## Managed Prometheus and Grafana

```text
AKS pods and Kubernetes metrics
  -> Azure Monitor metrics add-on
  -> Azure Monitor Workspace (managed Prometheus)
  -> Azure Managed Grafana
```

Terraform creates the Azure Monitor Workspace, enables the AKS managed metrics
integration, creates Azure Managed Grafana, links the workspace, and grants the
Grafana system-assigned identity `Monitoring Data Reader` on that workspace
only. When `PLATFORM_ADMIN_GROUP_OBJECT_ID` is configured, that Microsoft Entra
group receives the scoped `Grafana Admin` role on the managed Grafana instance.
No Prometheus server, Grafana deployment, persistent volume, or Grafana
port-forward exists in AKS.

`monitoring/podmonitor.yaml` preserves collection of the frontend `/metrics`
endpoint. After deployment, import `monitoring/grafana-dashboard.json` through
the Azure Managed Grafana UI and select the linked Azure Monitor Workspace
Prometheus data source when prompted. This deliberately avoids storing Grafana
administrator credentials or API keys in Terraform or GitHub Actions.
