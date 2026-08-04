# Kubernetes Manifests

This directory contains the Kustomize base for deploying the application to the
`demo` namespace in AKS.

## Contents

| File | Purpose |
|---|---|
| `namespace.yaml` | Creates the `demo` namespace. |
| `serviceaccount.yaml` | Defines the workload-identity service account. |
| `configmap.yaml` | Supplies non-sensitive application configuration. |
| `secretproviderclass.yaml` | Mounts `demo-secret` from Azure Key Vault through the CSI driver. |
| `deployment.yaml` | Runs the application with probes, resource limits, and a restricted security context. |
| `service.yaml` | Exposes the pods internally through a `ClusterIP` Service. |
| `ingress.yaml` | Routes Application Gateway traffic to the Service through AGIC. |
| `kustomization.yaml` | Defines the complete manifest set and render order. |

## Request and Secret Flows

```text
Application Gateway -> AGIC Ingress -> ClusterIP Service -> application pods

AKS service-account token -> workload identity -> Key Vault CSI provider
                                             -> /mnt/secrets-store
```

The `ServiceMonitor` in `monitoring/` selects the Service by its
`app: landing-zone-demo-app` label and scrapes the named `http` port. Monitoring
resources are intentionally outside this Kustomization because their CRDs are
installed by `kube-prometheus-stack`.

## Required Configuration

Before deployment:

1. Replace `REPLACE_WITH_MANAGED_IDENTITY_CLIENT_ID` in the ServiceAccount and
   SecretProviderClass with the root `workloads.workload_identity.client_id`
   output.
2. Replace `REPLACE_WITH_KEY_VAULT_NAME` and `REPLACE_WITH_TENANT_ID` in the
   SecretProviderClass.
3. Ensure `demo-secret` exists in Key Vault. Do not store its value in Git,
   Terraform variables, or a Kubernetes Secret.
4. Replace the image's `latest` tag with an immutable SHA tag published by
   `build-image.yml`.

## Dependencies

- AKS with OIDC, workload identity, and the Key Vault Secrets Provider enabled.
- The application managed identity, federated credential, and
  `Key Vault Secrets User` assignment created by Terraform.
- Application Gateway and the managed AGIC add-on for Ingress routing.
- A pullable GHCR application image.

## Render and Validate

These commands do not contact a cluster:

```powershell
kubectl kustomize app/k8s
kubectl kustomize app/k8s | kubeconform -strict -summary -skip SecretProviderClass
```

## Deploy

After the dependencies and deployment markers are configured:

```powershell
kubectl apply -k app/k8s
kubectl --namespace demo rollout status deployment/landing-zone-demo-app
```

The Ingress is hostless and HTTP-only. Production use requires a hostname,
certificate-backed HTTPS listener, and a reviewed ownership boundary between
Terraform and AGIC.
