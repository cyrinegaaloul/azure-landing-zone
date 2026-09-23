# P4D backend

This portable Python backend exposes `GET /health`, `GET /api/info`, and
`GET /api/items` on port `8080`. It intentionally contains no Azure SDK,
credentials, Kubernetes manifests, or Azure infrastructure dependency.

Build locally with `docker build -t landing-zone-demo-backend ./backend`.
P4D deployment is prepared in `p4d/`, but cannot be completed until cluster
access and the supported deployment mechanism are supplied.
