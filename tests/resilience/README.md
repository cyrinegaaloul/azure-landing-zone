# Kubernetes Resilience Tests

This directory contains manually invoked PowerShell tests for the deployed
application workload. The scripts validate Kubernetes controller behavior; they
are not part of CI and do not provision infrastructure.

## Contents

| Script | Purpose | Final state |
|---|---|---|
| `pod-recovery.ps1` | Deletes one application pod and verifies that the Deployment creates a Ready replacement. | One healthy replica |
| `scale-test.ps1` | Scales the Deployment from one replica to two and verifies both are Ready. | Restored to one replica |
| `rollout-rollback.ps1` | Updates the application image and optionally restores the previous revision. | Selected image or previous revision |

All scripts target:

- namespace: `demo`
- Deployment: `landing-zone-demo-app`
- container: `landing-zone-demo-app`

## Prerequisites

- AKS and the manifests in `app/k8s` are deployed.
- `kubectl` is installed and authenticated.
- `kubectl config current-context` identifies the intended cluster.
- The application Deployment starts with one healthy replica.
- The current Kubernetes identity can read, delete, scale, and update the
  Deployment and its pods.
- The image tag supplied to the rollout test exists in GHCR and is pullable by
  the cluster.

Run the scripts from the repository root in PowerShell.

## Pod Recovery

```powershell
.\tests\resilience\pod-recovery.ps1
```

After confirmation, the script deletes the current pod and waits up to 180
seconds for a different pod to become Ready. A successful test prints `PASSED`
and the replacement pod name.

## Replica Scaling

```powershell
.\tests\resilience\scale-test.ps1
```

The script requires an initial replica count of one. It scales to two replicas,
waits for the Deployment rollout, verifies two Ready replicas, and restores the
replica count to one.

## Rollout and Rollback

Pass an existing immutable image tag:

```powershell
.\tests\resilience\rollout-rollback.ps1 -ImageTag "0123456789abcdef"
```

The script updates the Deployment image and waits for rollout completion. Enter
`yes` at the prompt to run `kubectl rollout undo`; any other response retains
the new image.

## Operational Considerations

- Review the active Kubernetes context before each test.
- Run one test at a time.
- Do not run the scale test when the Deployment is managed by an autoscaler.
- Use an image tag that is compatible with the existing probes and container
  configuration.
