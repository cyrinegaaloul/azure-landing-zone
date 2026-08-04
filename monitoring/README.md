# AKS Demo Monitoring Assets

These files prepare a temporary, in-cluster monitoring stack; they do not mean
that monitoring is currently deployed.

```text
Application /metrics
  -> demo/landing-zone-demo-app Service (ClusterIP, port http)
  -> monitoring/landing-zone-demo-app ServiceMonitor
  -> Prometheus
  -> Grafana
```

The stack uses the open-source
[`prometheus-community/kube-prometheus-stack`](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
chart from `https://prometheus-community.github.io/helm-charts`. Prometheus and
Grafana run inside AKS only during the controlled demo window. Azure Managed
Grafana, Azure Monitor managed Prometheus, Log Analytics, and Container Insights
are intentionally excluded to protect the Azure for Students credit.

## Prepared Configuration

- `kube-prometheus-stack-values.yaml` enables one ephemeral Prometheus replica,
  Grafana, kube-state-metrics, and a small node-exporter DaemonSet.
- Alertmanager, persistent volumes, bundled dashboards/rules, and unavailable
  AKS control-plane scrapes are disabled for this small demonstration.
- Prometheus retains metrics for six hours and discovers `ServiceMonitor`
  resources without requiring Helm release labels or the release namespace.
- Grafana and Prometheus use `ClusterIP`; no ingress or public load balancer is
  configured.
- No Grafana password is stored in Git. The chart generates a temporary password
  in a Kubernetes Secret at installation time.
- `servicemonitor.yaml` lives in `monitoring` but selects the labeled Service in
  `demo`. Keeping it outside `app/k8s/kustomization.yaml` avoids applying the
  custom resource before the chart installs its CRD.
- `grafana-dashboard.json` is intentionally imported manually, avoiding another
  operator or a duplicated JSON payload in Helm values.

The custom dashboard uses application metrics exposed by `app/server.py`.
Container CPU and memory come from kubelet/cAdvisor metrics; restart and
Deployment replica metrics depend on kube-state-metrics. Node exporter supplies
additional node telemetry for troubleshooting, although the compact dashboard
does not require it directly.

## Future Controlled Install

The following commands are runbook instructions only. Review chart/Kubernetes
compatibility before the demo; `86.0.1` is intentionally pinned for a
reproducible install.

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

Wait for the stack, then retrieve the Helm-generated Grafana password without
writing it to a file:

```bash
kubectl --namespace monitoring rollout status deployment/monitoring-grafana
kubectl --namespace monitoring get secret monitoring-grafana \
  --output jsonpath='{.data.admin-password}' | base64 --decode
```

Use username `admin` and keep Grafana internal by port-forwarding it:

```bash
kubectl --namespace monitoring port-forward service/monitoring-grafana 3000:80
```

Open `http://localhost:3000`, select **Dashboards > New > Import**, upload
`monitoring/grafana-dashboard.json`, and select the chart-provisioned Prometheus
data source when prompted.

## Verification

Confirm the `ServiceMonitor` exists and its selector matches the application
Service:

```bash
kubectl --namespace monitoring get servicemonitor landing-zone-demo-app
kubectl --namespace demo get service landing-zone-demo-app --show-labels
```

Forward Prometheus and inspect **Status > Targets** at
`http://localhost:9090/targets`. The `demo/landing-zone-demo-app` endpoint should
be `UP`; querying `demo_app_info{namespace="demo"}` should return one series.

```bash
kubectl --namespace monitoring port-forward service/monitoring-kube-prometheus-prometheus 9090:9090
curl --get --data-urlencode 'query=demo_app_info{namespace="demo"}' \
  http://localhost:9090/api/v1/query
```

In Grafana, verify that the dashboard shows app identity, uptime, tracked service
count, pod CPU/memory/restarts, and desired versus available replicas.

## Resource and Data-Lifetime Notes

The declared requests total roughly 245 millicores and 580 MiB across the main
Prometheus, Grafana, operator, kube-state-metrics, and one node-exporter pod.
Actual chart support components add some overhead. Limits are deliberately small
for a single-node demo, so confirm spare node capacity before installation.
Prometheus and Grafana use ephemeral storage: pod recreation or uninstall can
discard metrics, dashboard imports, and Grafana state. That is acceptable for
the temporary demonstration and avoids Azure Disk charges.

## Future Uninstall

Remove the custom resource before removing the chart, then remove the temporary
namespace after checking that it contains nothing else:

```bash
kubectl delete -f monitoring/servicemonitor.yaml
helm uninstall monitoring --namespace monitoring
kubectl delete namespace monitoring
```

The chart's CRDs can remain after Helm uninstall. Review and remove them only if
no other monitoring installation uses them. None of the install, apply, delete,
or uninstall commands in this document were executed while preparing this stage.

