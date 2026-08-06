# Application

This directory contains the Python HTTP application, its container definition,
the public OpenAPI contract, and Kubernetes deployment manifests.

## Contents

| Path | Purpose |
|---|---|
| `server.py` | Standard-library HTTP server and Prometheus metrics endpoint. |
| `Dockerfile` | Builds the application image used by CI and AKS. |
| `.dockerignore` | Excludes local Python artifacts from the image build context. |
| `openapi.yaml` | OpenAPI 3.0 contract imported by Azure API Management. |
| `k8s/` | Kustomize-managed Kubernetes resources for AKS. |

## HTTP Endpoints

| Endpoint | Purpose | APIM exposure |
|---|---|---|
| `/` | Application metadata. | Internal application route. |
| `/api/info` | Application and platform information. | Published. |
| `/api/status` | Runtime status and component summary. | Published. |
| `/health` | Startup, readiness, and liveness probe. | Published. |
| `/metrics` | Prometheus text-format metrics. | Internal only. |

API Management imports `openapi.yaml`, which excludes `/metrics`. Prometheus
scrapes `/metrics` through the in-cluster Service and `ServiceMonitor`.

## Configuration

The service reads these environment variables:

| Variable | Default | Description |
|---|---|---|
| `APP_NAME` | `landing-zone-demo-app` | Application name returned by the API. |
| `APP_ENV` | `dev` | Environment label. |
| `APP_VERSION` | `0.1.0` | Application version. |
| `APP_HOST` | `0.0.0.0` | Listener address. |
| `APP_PORT` | `8080` | Listener port. |

The Kubernetes ConfigMap supplies the application name, environment, and
version. The container definition supplies the listener address and port.

## Run Locally

```powershell
Set-Location app
python server.py
```

The service is available at `http://localhost:8080`.

## Build the Container

From the repository root:

```powershell
docker build -t landing-zone-demo-app:local ./app
docker run --rm -p 8080:8080 landing-zone-demo-app:local
```

The publishing workflow builds the same Dockerfile and pushes immutable commit
SHA tags to GitHub Container Registry.

## Architecture Integration

Requests reach the application through Application Gateway WAF_v2, internal
APIM, and the AKS internal LoadBalancer Service. See
[`k8s/README.md`](k8s/README.md) for manifest configuration and dependencies.
