# AKS Deployment Assets

This folder contains the Kubernetes assets prepared for the application.

## Files

- `namespace.yaml`
- `configmap.yaml`
- `deployment.yaml`
- `service.yaml`
- `ingress-placeholder.yaml`

## Intended Order

If you later deploy the application to AKS manually, the intended order is:

1. namespace
2. config map
3. deployment
4. service
5. ingress placeholder only when an ingress controller is available

## Notes

- `service.yaml` uses `ClusterIP`, which keeps the service internal to the cluster.
- `ingress-placeholder.yaml` is only a template and is not tied to a real hostname yet.
- `deployment.yaml` includes health probes and small resource requests appropriate for a lightweight demonstration workload.
