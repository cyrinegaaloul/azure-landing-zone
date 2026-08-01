# AKS Deployment Assets

This folder contains the Kubernetes assets prepared for the application.

## Files

- `namespace.yaml`
- `configmap.yaml`
- `secret-placeholder.yaml`
- `deployment.yaml`
- `service.yaml`
- `ingress-placeholder.yaml`
- `kustomization.yaml`

## Intended Order

If you later deploy the application to AKS manually, the intended order is:

1. namespace
2. config map
3. secret placeholder
4. deployment
5. service
6. ingress placeholder only when an ingress controller is available

## Notes

- `service.yaml` uses `ClusterIP`, which keeps the service internal to the cluster.
- `secret-placeholder.yaml` is only a template and should be replaced or generated securely before real deployment.
- `ingress-placeholder.yaml` is only a template and is not tied to a real hostname yet.
- `deployment.yaml` includes health probes and small resource requests appropriate for a lightweight demonstration workload.
- `kustomization.yaml` provides one simple entrypoint for Kubernetes manifest assembly.
