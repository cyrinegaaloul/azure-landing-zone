# CI/CD Pipelines

This directory documents the GitHub Actions workflows in
`.github/workflows/`. Validation and image publication are automatic; Azure
planning and deployment are manual.

## Workflows

| Workflow | Trigger | Purpose | Azure changes |
|---|---|---|---|
| `validate.yml` | Push to `main`, pull request | Validates source, manifests, image, and security configuration. | None |
| `build-image.yml` | Changes under `app/` on `main`, manual | Builds and publishes the application image to GHCR. | None |
| `demo-deploy.yml` | Manual | Runs the selected Terraform `plan`, `apply`, or `destroy` action. | Depends on selected action |

## Validation Pipeline

`validate.yml` contains two jobs.

### Terraform validation

1. Check formatting with `terraform fmt -check -recursive`.
2. Initialize the root module without a backend.
3. Run `terraform validate`.
4. Scan Terraform configuration with Trivy.

### Application and Kubernetes validation

1. Compile `app/server.py` to validate Python syntax.
2. Build the application image once and scan the local image with Trivy.
3. Render `app/k8s` once with Kustomize.
4. Validate built-in Kubernetes resources with kubeconform.
5. Scan the rendered resources with Trivy.
6. Parse the OpenAPI and monitoring YAML files.
7. Validate the Grafana dashboard JSON and the `ServiceMonitor` manifest.
8. Scan monitoring configuration with Trivy.

Trivy reports `HIGH` and `CRITICAL` findings and returns a failing exit code for
either severity. Kubeconform skips only external custom resources whose schemas
are supplied by components installed later:

- `SecretProviderClass` from the Azure Key Vault provider add-on;
- `ServiceMonitor` from `kube-prometheus-stack`.

The validation workflow requires only `contents: read`. It does not authenticate
to Azure, push images, install Helm releases, or contact a Kubernetes cluster.

## Image Publication

`build-image.yml` publishes:

```text
ghcr.io/<repository-owner>/landing-zone-demo-app:<commit-sha>
ghcr.io/<repository-owner>/landing-zone-demo-app:latest
```

The SHA tag is immutable and should be used in `app/k8s/deployment.yaml` for a
deployment. The `latest` tag is published only from the default branch.

The workflow uses `GITHUB_TOKEN` with `packages: write`; no separate registry
credential is required. If the package is private, configure an image pull
secret or another supported GHCR authentication method in AKS.

## Manual Terraform Workflow

`demo-deploy.yml` accepts these inputs:

| Input | Default | Description |
|---|---|---|
| `action` | `plan` | Terraform action: `plan`, `apply`, or `destroy`. |
| `enable_aks` | `false` | Enables conditional AKS resources. |
| `enable_edge` | `false` | Enables Application Gateway WAF_v2 and AGIC integration. |
| `enable_apim` | `false` | Enables Developer-tier APIM; requires `enable_edge=true`. |

The workflow passes configuration through `TF_VAR_` environment variables and
does not depend on a local `terraform.tfvars` file.

Required repository or environment secrets:

| Secret | Purpose |
|---|---|
| `AZURE_CREDENTIALS` | Credentials consumed by `azure/login`. |
| `AZURE_SUBSCRIPTION_ID` | AzureRM provider subscription. |
| `AZURE_TENANT_ID` | Tenant-scoped resources such as Key Vault. |

Protect the `demo` GitHub environment with required reviewers. Replacing the
credentials JSON with GitHub OIDC federation is a recommended identity
hardening step after the corresponding Azure identity is configured.
