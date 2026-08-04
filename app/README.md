# Demo Application

This application is a small Python HTTP service intended for local development and future deployment to AKS.

## Endpoints

- `/` returns application metadata
- `/api/info` returns structured application and platform metadata
- `/api/status` returns a simple project status payload
- `/health` returns a health response for readiness and liveness checks
- `/metrics` returns Prometheus-compatible metrics

`openapi.yaml` defines the public APIM contract for `/health`, `/api/info`, and
`/api/status`. It intentionally omits `/metrics`, which remains an internal
Prometheus scrape endpoint.

## Local Run

```powershell
python server.py
```

Then open:

- `http://localhost:8080/`
- `http://localhost:8080/api/info`
- `http://localhost:8080/api/status`
- `http://localhost:8080/health`
- `http://localhost:8080/metrics`

## AKS Preparation

The `k8s/` folder now includes:

- `configmap.yaml`
- `namespace.yaml`
- `serviceaccount.yaml`
- `secretproviderclass.yaml`
- `deployment.yaml`
- `service.yaml`
- `ingress.yaml`
- `kustomization.yaml`
- `README.md`

The hostless `ingress.yaml` targets the existing ClusterIP Service through the
managed Application Gateway ingress class. Application Gateway, AGIC, and AKS
remain disabled and must exist before these manifests are applied.

## Container Build

```powershell
docker build -t landing-zone-demo-app:latest .
docker run -p 8080:8080 landing-zone-demo-app:latest
```

Containerization is included for future AKS deployment preparation. Building the image locally does not consume Azure credits.

## Why Python Here

Python was chosen because this demo app uses only the standard library, which keeps the runtime simple:

- no framework dependency is required
- no package installation is required
- the same app can still be containerized and deployed to AKS later

The goal at this stage is to keep the application small and predictable while the infrastructure design is still evolving.
