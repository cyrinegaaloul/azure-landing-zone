# Kubernetes Resilience Tests

These small PowerShell scripts demonstrate application recovery and Deployment
controls after the landing-zone infrastructure and Kubernetes manifests have
been deployed. They are not run by CI and must not be used before checking the
active Kubernetes context.

## Prerequisites

- The conditional AKS infrastructure and the resources in `app/k8s` are deployed.
- `kubectl` is installed and authenticated to the intended cluster.
- The current context points to the demonstration cluster; verify it with
  `kubectl config current-context`.
- The `demo` namespace contains Deployment `landing-zone-demo-app` with one
  healthy replica.
- Your Kubernetes identity can read, delete, scale, and update the Deployment
  and its pods.
- For the rollout test, the requested tag exists in
  `ghcr.io/cyrinegaaloul/landing-zone-demo-app` and the cluster can pull it.

Run the commands below from the repository root in PowerShell.

## Pod Recovery

```powershell
.\tests\resilience\pod-recovery.ps1
```

The script finds and displays the application pod, asks for confirmation,
deletes it, and waits up to three minutes for the Deployment controller to
create a different Ready pod.

Expected result: the original pod disappears and the script prints `PASSED`
with the replacement pod name.

## Scale Test

```powershell
.\tests\resilience\scale-test.ps1
```

The script verifies that the Deployment starts at one replica, scales it to two,
waits until both pods are Ready, and reports success. It then restores the
Deployment to one replica and waits for it to stabilize.

Expected result: two Ready pods are observed temporarily, `PASSED` is printed,
and the Deployment finishes with one replica.

## Rollout and Rollback

Use an existing immutable image tag, such as a commit SHA:

```powershell
.\tests\resilience\rollout-rollback.ps1 -ImageTag "0123456789abcdef"
```

The script displays the current and requested images, updates the application
container, and waits for the rollout. It then asks whether to run
`kubectl rollout undo`. Enter `yes` to restore the previous Deployment revision;
any other response leaves the new image deployed.

Expected result: the new image rolls out successfully. If rollback is selected,
the previous revision is restored and becomes ready.

These scripts intentionally make temporary changes to the live demonstration
workload. Execute them only after the final infrastructure deployment, observe
the results, and complete the project teardown afterward.
