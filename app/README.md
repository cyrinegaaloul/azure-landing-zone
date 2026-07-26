# Demo Application

This application is a small Python HTTP service intended for local development and future deployment to AKS or Jelastic P4D.

## Endpoints

- `/` returns application metadata
- `/health` returns a health response for readiness and liveness checks
- `/metrics` returns Prometheus-compatible metrics

## Local Run

```powershell
python server.py
```

Then open:

- `http://localhost:8080/`
- `http://localhost:8080/health`
- `http://localhost:8080/metrics`

## Container Build

```powershell
docker build -t landing-zone-demo-app:latest .
docker run -p 8080:8080 landing-zone-demo-app:latest
```

Containerization is included for future AKS and Jelastic deployment preparation. Building the image locally does not consume Azure credits.
