# Monitoring

This directory configures an in-cluster, open-source monitoring stack. It does
not use Azure Log Analytics or an external monitoring service.

| File | Purpose |
|---|---|
| `kube-prometheus-stack-values.yaml` | Cost-conscious Prometheus/Grafana Helm values. |
| `servicemonitor.yaml` | Scrapes the demo Service `/metrics` endpoint every 30 seconds. |
| `grafana-dashboard.json` | Request rate, errors, latency, CPU, memory, uptime, and replicas. |
| `kustomization.yaml` | Applies the ServiceMonitor and provisions the dashboard ConfigMap. |

The Grafana sidecar watches ConfigMaps labelled `grafana_dashboard=1`, so the
dashboard is provisioned automatically. Prometheus discovers ServiceMonitors
across namespaces. NetworkPolicy explicitly permits monitoring-namespace
scrapes to the application.

The deployment workflow runs the equivalent of:

```powershell
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack `
  --version 86.0.1 --namespace monitoring --create-namespace `
  --values monitoring/kube-prometheus-stack-values.yaml --wait
kubectl apply -k monitoring
```

These commands are documentation only until infrastructure is deployed. The
current profile uses one Prometheus replica, six-hour retention, ephemeral
storage, no Alertmanager, and no persistent Grafana volume. Those choices avoid
additional Azure disks and paid ingestion but are not production-grade.
