# AKS Frontend

`app/` contains the dependency-free frontend that proves the deployed network,
identity, secret, and monitoring paths. Its optional backend URL is supplied
through configuration; it contains no backend application/data logic.

| File | Purpose |
|---|---|
| `server.py` | Frontend API, health endpoint, safe secret-mount status, backend health check, and Prometheus metrics. |
| `test_server.py` | Standard-library unit tests for path normalization and secret status. |
| `Dockerfile` | Reproducible Python 3.12 image running as UID/GID 10001. |
| `openapi.yaml` | APIM-imported contract for public demo operations. |
| `k8s/` | Kustomize base rendered with Terraform outputs at deployment time. |

## Endpoints

| Endpoint | Purpose | Published through APIM |
|---|---|---:|
| `/health` | Liveness/readiness and smoke test. | Yes |
| `/api/info` | Runtime and project metadata. | Yes |
| `/api/status` | Frontend uptime and configured backend reachability. | Yes |
| `/secret-status` | Returns only `{"secretMounted": true|false}`. | Yes |
| `/metrics` | Prometheus request, error, latency, uptime, and service metrics. | No |

The application reads at most one byte from the mounted secret file. It never
returns, logs, or exports the secret value.

Set `BACKEND_API_URL` to the P4D backend base URL only after connectivity is
confirmed. An empty value keeps the frontend healthy and independently
deployable.

## Local validation

```powershell
python -m py_compile app/server.py app/test_server.py
Push-Location app
python -m unittest -v
Pop-Location
docker build -t landing-zone-demo-frontend:local ./app
```

CI builds the container once, scans the local image, generates a CycloneDX
SBOM, and publishes only the commit-SHA tag after all gates pass.
