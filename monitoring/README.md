# Kubernetes Monitoring

This directory contains configuration for an in-cluster Prometheus and Grafana
stack based on `prometheus-community/kube-prometheus-stack`.

## Contents

| File | Purpose |
|---|---|
| `kube-prometheus-stack-values.yaml` | Helm values for Prometheus, Grafana, kube-state-metrics, and node-exporter. |
| `servicemonitor.yaml` | Selects the application Service in the `demo` namespace and scrapes `/metrics`. |
| `grafana-dashboard.json` | Dashboard for application and Kubernetes workload metrics. |

## Data Flow

```text
application /metrics
  -> demo/landing-zone-demo-app Service
  -> monitoring/landing-zone-demo-app ServiceMonitor
  -> Prometheus
  -> Grafana
```

The ServiceMonitor is kept outside `app/k8s` because its CRD is installed by
the monitoring chart. The application Service exposes a stable named `http`
port and the label selected by the ServiceMonitor.

## Configuration

The values file configures:

- one Prometheus replica with six-hour retention and WAL compression;
- Grafana with chart-generated credentials;
- kube-state-metrics and one node-exporter pod per node;
- `ClusterIP` Services for Prometheus and Grafana;
- ephemeral storage for Prometheus and Grafana;
- no Alertmanager, default dashboards, default rules, or AKS control-plane
  scrapes.

Prometheus discovers ServiceMonitors independently of Helm release labels and
namespaces. No ingress, public load balancer, persistent volume, or managed Azure
monitoring service is configured.

The declared requests are approximately 245 millicores and 580 MiB across the
main monitoring components and one node-exporter pod. Confirm available cluster
capacity before installation.

## Install

Review the pinned chart version for compatibility with the target Kubernetes
version, then run from the repository root:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --version 86.0.1 \
  --namespace monitoring \
  --create-namespace \
  --values monitoring/kube-prometheus-stack-values.yaml

kubectl apply -f monitoring/servicemonitor.yaml
```

Wait for Grafana:

```bash
kubectl --namespace monitoring rollout status deployment/monitoring-grafana
```

## Access Grafana

Retrieve the chart-generated password without writing it to a file:

```bash
kubectl --namespace monitoring get secret monitoring-grafana \
  --output jsonpath='{.data.admin-password}' | base64 --decode
```

Forward the internal Grafana Service:

```bash
kubectl --namespace monitoring port-forward service/monitoring-grafana 3000:80
```

Open `http://localhost:3000`, sign in as `admin`, and import
`monitoring/grafana-dashboard.json`. Select the Prometheus data source created by
the chart.

## Verify Metrics

Confirm the ServiceMonitor selector matches the application Service:

```bash
kubectl --namespace monitoring get servicemonitor landing-zone-demo-app
kubectl --namespace demo get service landing-zone-demo-app --show-labels
```

Forward Prometheus and inspect `http://localhost:9090/targets`:

```bash
kubectl --namespace monitoring port-forward \
  service/monitoring-kube-prometheus-prometheus 9090:9090
```

The `demo/landing-zone-demo-app` target should report `UP`. The dashboard uses:

- `demo_app_info`, `demo_app_uptime_seconds`, and
  `demo_app_services_total` from the application;
- container CPU and memory metrics from kubelet/cAdvisor;
- restart and replica metrics from kube-state-metrics.

## Data Persistence

Prometheus and Grafana use ephemeral storage. Pod replacement or chart removal
can discard collected metrics, imported dashboards, and Grafana state. Configure
persistent storage before using this stack for durable monitoring.

## Uninstall

Remove the custom resource before uninstalling its CRD provider:

```bash
kubectl delete -f monitoring/servicemonitor.yaml
helm uninstall monitoring --namespace monitoring
kubectl delete namespace monitoring
```

Helm does not automatically remove the chart CRDs. Remove them only after
confirming that no other Prometheus Operator installation uses them.
