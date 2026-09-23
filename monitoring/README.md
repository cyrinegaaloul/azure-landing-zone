# Monitoring

This directory contains the application scrape configuration and dashboard for
Azure Monitor managed service for Prometheus. Prometheus and Grafana are Azure
managed services; neither runs as a Kubernetes Pod.

| File | Purpose |
|---|---|
| `podmonitor.yaml` | Azure Monitor metrics-agent CRD that scrapes application `/metrics` every 30 seconds. |
| `grafana-dashboard.json` | Request rate, errors, latency, CPU, memory, uptime, and replicas. |
| `kustomization.yaml` | Applies the managed-Prometheus scrape configuration. |

The AKS Azure Monitor metrics agent discovers the `PodMonitor` and sends the
metrics to the Terraform-created Azure Monitor Workspace. Import
`grafana-dashboard.json` in Azure Managed Grafana and choose its Azure Monitor
Workspace Prometheus data source when prompted. NetworkPolicy permits the
metrics agent in `kube-system` to scrape the application.

The deployment workflow applies `kubectl apply -k monitoring` after AKS has
enabled managed metrics. No Helm repository or in-cluster Prometheus/Grafana
workload is used.
