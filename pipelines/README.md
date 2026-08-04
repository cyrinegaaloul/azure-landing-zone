# Pipeline Strategy

This repository uses a cost-aware pipeline approach:

- `validate.yml` runs free, non-deploying checks on pushes to `main` and pull requests
- `build-image.yml` publishes the application image to GHCR on relevant pushes to `main` or by manual request
- `demo-deploy.yml` is manual only
- `plan` is the default cloud-facing action
- AKS is disabled unless the operator explicitly selects `enable_aks`
- Application Gateway WAF_v2 is disabled unless the operator explicitly selects
  `enable_edge`
- Developer-tier API Management is disabled unless the operator explicitly
  selects `enable_apim`; enabling it also requires `enable_edge`
- `apply` and `destroy` are reserved for final demo windows

## Required Secrets For Demo Deployment

- `AZURE_CREDENTIALS` for GitHub Actions Azure login
- `AZURE_SUBSCRIPTION_ID` for the Terraform Azure provider
- `AZURE_TENANT_ID` for tenant-scoped Azure resources such as Key Vault

`AZURE_CREDENTIALS` keeps the existing login functional. Replace it later with
GitHub OIDC federation after the required Azure identity and federated credential
have been configured; no placeholder client or tenant IDs are used here.

## Recommended Protection

- require environment approval on the `demo` environment
- review the `enable_aks` input before every manual run
- review the separately disabled `enable_edge` input and its continuous WAF_v2
  cost before every manual run
- review the separately disabled `enable_apim` input and its continuous
  Developer-tier APIM cost before every manual run
- always follow `apply` with `destroy`

The workflow passes its shared Terraform values with `TF_VAR_` environment
variables, so it does not depend on the ignored local
`terraform/root/terraform.tfvars` file.

GHCR is used instead of Azure Container Registry to avoid consuming Azure credit.
For the simplest AKS demonstration, configure the
`landing-zone-demo-app` package as public. The workflow needs no registry secret;
GitHub supplies `GITHUB_TOKEN` automatically.

Running `apply` can consume the Azure for Students credit. Run `destroy` after
the final demonstration to remove billable resources.

## Validation and Security Gates

`validate.yml` runs automatically before deployment and keeps the existing
validation sequence:

1. Terraform formatting, initialization, and root-module validation.
2. Trivy Infrastructure-as-Code scanning across `terraform/`.
3. Python syntax checking and one local Docker image build.
4. Trivy vulnerability scanning of that local image before any push.
5. One `kubectl kustomize app/k8s` render reused by kubeconform schema validation
   and a separate Trivy Kubernetes configuration scan. The render now includes
   the standard Kubernetes Ingress consumed later by AGIC.
6. OpenAPI and monitoring YAML syntax, dashboard JSON, and `ServiceMonitor`
   parsing checks, followed by a Trivy scan of `monitoring/`.

[Trivy](https://trivy.dev/) is an open-source scanner used for Terraform and
Kubernetes misconfiguration checks and container package vulnerability checks.
All Trivy gates report only `HIGH` and `CRITICAL` findings and return a
failing exit code when either severity is present. The image scan explicitly
uses the vulnerability scanner; this stage does not add Python SAST, dependency,
or secret scanning.

The third-party Trivy setup action is pinned to the immutable commit for its
patched `v0.2.6` release, and the Trivy CLI version is pinned explicitly. The
Kubernetes Deployment uses a non-root runtime-default seccomp profile, drops all
Linux capabilities, blocks privilege escalation, and mounts its root filesystem
read-only.

[kubeconform](https://github.com/yannh/kubeconform) remains responsible for
Kubernetes schema validation. It complements Trivy: kubeconform checks whether
the rendered resources match Kubernetes schemas, while Trivy checks their
security configuration. The external `SecretProviderClass` custom resource is
explicitly skipped by kubeconform because its CRD schema is installed by the AKS
Key Vault provider add-on; all built-in Kubernetes resources remain strictly
validated.

The validation workflow needs only read access to repository contents and does
not require Azure credentials, package publishing permission, or any new GitHub
secret. Trivy's binary is pinned and cached per job, and the Docker image is
built only once within validation.

The monitoring checks reuse the same kubeconform and Trivy installations as the
application checks. Kubeconform skips only the `ServiceMonitor` kind because its
schema is supplied later by kube-prometheus-stack; YAML parsing still runs in a
separate step. The application Kustomize render is reused, and the Grafana
dashboard is parsed as JSON. CI does not run Helm or contact a cluster.

The prepared open-source Prometheus and Grafana stack is documented in
`monitoring/README.md`. It is not deployed by any workflow and is reserved for
the final controlled AKS demonstration window; managed Azure monitoring services
are excluded to protect student credit.

Terraform root validation automatically includes the conditional `03-edge`
module, conditional `05-apim` module, and managed AGIC add-on configuration. It
also parses `app/openapi.yaml` without importing or publishing an API.
Validation does not log in to Azure, create a gateway or APIM service, enable an
AKS add-on, or apply the Ingress. The manual demo workflow maps `enable_edge`
and `enable_apim` to their Terraform toggles; both default to `false`.
