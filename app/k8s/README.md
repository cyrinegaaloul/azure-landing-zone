# AKS Deployment Assets

This folder contains the Kubernetes assets prepared for the application.

## Files

- `namespace.yaml`
- `serviceaccount.yaml`
- `configmap.yaml`
- `secretproviderclass.yaml`
- `deployment.yaml`
- `service.yaml`
- `ingress.yaml`
- `kustomization.yaml`

## Intended Order

If you later deploy the application to AKS manually, the intended order is:

1. namespace
2. service account
3. config map
4. SecretProviderClass
5. deployment
6. service
7. ingress only after the managed AGIC add-on is available

## Notes

- `service.yaml` uses `ClusterIP`, which keeps the service internal to the cluster.
  Its stable `http` port name and `app: landing-zone-demo-app` Service label are
  consumed by the separately managed `monitoring/servicemonitor.yaml` resource.
- `ingress.yaml` is a hostless, HTTP-only AGIC Ingress. It uses
  `azure-application-gateway`, routes `/` to the existing ClusterIP Service's
  named `http` port, and configures the supported `/health` probe annotation.
  It contains no TLS Secret, hostname, public IP, or Azure resource ID.
- `deployment.yaml` includes health probes and small resource requests appropriate for a lightweight demonstration workload.
- The pod and container security contexts enforce a non-root user, runtime-default seccomp, no privilege escalation, dropped Linux capabilities, and a read-only root filesystem.
- `serviceaccount.yaml` establishes the `demo/landing-zone-demo` workload identity subject. Replace its client-ID marker with the `workload_identity.client_id` Terraform output before deployment.
- `secretproviderclass.yaml` configures the Azure provider to mount `demo-secret` from Key Vault. Replace the client ID, vault name, and tenant ID markers first.
- The Deployment opts into the workload identity webhook and mounts the CSI volume read-only at `/mnt/secrets-store`; it does not create or synchronize a Kubernetes Secret.
- `kustomization.yaml` provides one entrypoint for Kubernetes manifest assembly
  and now includes the standard Ingress, which validates without a live cluster.
- The deployment defaults to the public GHCR package. Keep the package public for the simplest AKS demo; a private package would require image-pull authentication.
- For a controlled deployment, replace the `latest` image tag with the immutable commit SHA tag published by `build-image.yml` before applying the manifests.
- No secret values belong in these manifests or Terraform. Add the future demo value directly to Key Vault during an approved demonstration window.
- The application exposes Prometheus text metrics at `/metrics`. Monitoring
  assets remain outside this Kustomization so its resources can still be
  rendered and validated before the `ServiceMonitor` CRD exists.
- Application Gateway and AGIC remain disabled by default. Do not apply this
  Kustomization until the WAF_v2 gateway, AKS cluster, add-on identity roles, and
  workload-identity markers are ready during the controlled demo window.
