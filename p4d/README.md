# P4D deployment preparation

`dev.jps` and `prod.jps` are parameterized Jelastic/P4D deployment manifests
for the portable `backend/` container. They intentionally do not contain a
cluster name, endpoint, credentials, image registry credentials, domain, or
network settings and have not been tested against a P4D cluster.

Before deployment, obtain from the supervisor:

1. P4D cluster access and target dev/prod environments.
2. The accepted backend deployment method (JPS, API, SSH, or another flow).
3. Registry/image pull requirements and the exact image reference format.
4. Backend hostname or IP, public/private reachability, and APIM-to-P4D path.
5. Required health endpoint, port, TLS certificate/hostname, and APIM auth.

Once supplied, use the matching JPS file only if the supervisor confirms this
JPS schema and Docker-node capabilities for the target P4D installation.
