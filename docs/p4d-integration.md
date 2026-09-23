# Frontend, P4D backend, and APIM preparation

```text
Internet -> Application Gateway/WAF -> APIM
                                      -> /demo    -> AKS internal NGINX ingress -> frontend
                                      -> /backend -> P4D backend (when configured)
```

The frontend is the independently deployable `app/` image and runs only on
AKS. Its `BACKEND_API_URL` configuration is optional and empty by default. The
portable `backend/` image has no Azure dependencies and is intended for P4D.
No backend Kubernetes Deployment is created.

Terraform creates the `/backend` APIM API only when `p4d_backend_url` is a
real confirmed HTTP(S) value. This avoids inventing a backend address and
leaves the working `/demo` frontend API unchanged.

No APIM-to-P4D NSG rule is added yet. The current APIM subnet rules permit only
the existing Azure dependencies and AKS frontend path. Add a precise rule only
after the supervisor confirms whether P4D is reached through public HTTPS, a
VPN/private path, or another approved network route.

## Dev and prod strategy

`dev` is the development branch and deploys with `target_environment=dev`.
`main` is the production branch and deploys with `target_environment=prod`.
The controlled workflow uses `demo-dev-plan`/`demo-dev-apply` and
`demo-prod-plan`/`demo-prod-apply` GitHub environments. Configure the required
Azure/state settings and, when available, `P4D_BACKEND_URL` separately in each
environment; do not commit these values. Use a distinct `TFSTATE_KEY` per
environment. The existing state must not be repurposed from `dev` to `prod`;
confirm and perform any state migration separately before a production apply.

CI builds and scans both images on `dev` and `main`. It publishes the frontend
and backend SHA-tagged images to GHCR. The controlled deployment workflow
deploys only the frontend to AKS; its P4D step intentionally reports that no
deployment was attempted until access is available.

## Required supervisor information

1. P4D cluster access and the dev/prod environment layout.
2. Approved P4D deployment method (JPS, API, SSH, or another mechanism).
3. Backend hostname/IP, port, health endpoint, protocol, and certificate/TLS requirements.
4. Whether APIM reaches P4D through public HTTPS, VPN, private peering, or another path.
5. Network/firewall rules required for APIM-to-P4D traffic.
6. Image registry pull requirements for P4D.
7. Authentication required between APIM and the backend.

Do not set `p4d_backend_url` or `P4D_BACKEND_URL` until those answers are
known and reviewed.
