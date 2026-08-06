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
| `service.yaml` | Exposes the pods through a static private AKS LoadBalancer used only by internal APIM. |
| `ingress.yaml` | Superseded AGIC diagnostic manifest; retained but excluded from Kustomize. |
| `kustomization.yaml` | Defines the complete manifest set and render order. |

## Request and Secret Flows

```text
Application Gateway -> internal APIM -> AKS internal LoadBalancer -> application pods

AKS service-account token -> workload identity -> Key Vault CSI provider
                                             -> /mnt/secrets-store
```

The `ServiceMonitor` in `monitoring/` selects the LoadBalancer Service by its
`app: landing-zone-demo-app` label and scrapes the named `http` port. Monitoring
resources are intentionally outside this Kustomization because their CRDs are
installed by `kube-prometheus-stack`.

## Required Configuration

Before deployment:

1. Replace `REPLACE_WITH_MANAGED_IDENTITY_CLIENT_ID` in the ServiceAccount and
   SecretProviderClass with the sensitive root
   `workloads.workload_identity.client_id` output.
2. Replace `REPLACE_WITH_TENANT_ID` locally and verify that `keyvaultName`
   matches the target Azure environment. Terraform generates the vault name as
   `kv-<project>-<environment>-<owner>`; the current profile uses
   `kv-alz-dev-cyrine`. Do not commit either populated identifier.
3. Ensure `demo-secret` exists in Key Vault. Do not store its value in Git,
   Terraform variables, or a Kubernetes Secret.
4. Replace the image's `latest` tag with an immutable SHA tag published by
   `build-image.yml`.
5. Confirm that `10.10.2.10` is unused and matches the root
   `aks_internal_load_balancer_ip` value before applying the Service.

## Dependencies

- AKS with OIDC, workload identity, and the Key Vault Secrets Provider enabled.
- The application managed identity, federated credential, and
  `Key Vault Secrets User` assignment created by Terraform.
- Internal-mode APIM and Application Gateway for the public WAF path.
- AKS control-plane identity with Network Contributor on the AKS subnet so the
  cloud provider can manage the internal LoadBalancer.
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

The applied Kustomize base does not include the legacy Ingress and does not use
AGIC. Verify that the Service's reported private address matches the configured
static address before testing APIM. Production use requires a hostname and
certificate-backed HTTPS listener on Application Gateway.
