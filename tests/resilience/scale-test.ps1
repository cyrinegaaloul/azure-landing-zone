$Namespace = "demo"
$DeploymentName = "landing-zone-demo-app"
$Timeout = "180s"

$CurrentReplicas = & kubectl get deployment $DeploymentName --namespace $Namespace --output 'jsonpath={.spec.replicas}'
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($CurrentReplicas)) {
    Write-Error "Could not read Deployment '$DeploymentName'."
    exit 1
}
$CurrentReplicas = $CurrentReplicas.Trim()

if ($CurrentReplicas -ne "1") {
    Write-Error "Expected the Deployment to start with 1 replica, but found $CurrentReplicas."
    exit 1
}

Write-Host "Scaling Deployment '$DeploymentName' from 1 replica to 2..."
& kubectl scale deployment $DeploymentName --namespace $Namespace --replicas=2
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to scale the Deployment to 2 replicas."
    exit 1
}

& kubectl rollout status "deployment/$DeploymentName" --namespace $Namespace --timeout=$Timeout
$ScaleUpSucceeded = $LASTEXITCODE -eq 0

$ReadyReplicas = & kubectl get deployment $DeploymentName --namespace $Namespace --output 'jsonpath={.status.readyReplicas}'
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($ReadyReplicas) -or $ReadyReplicas.Trim() -ne "2") {
    $ScaleUpSucceeded = $false
}

if ($ScaleUpSucceeded) {
    Write-Host "PASSED: both application pods are Ready."
}
else {
    Write-Host "FAILED: two application pods did not become Ready."
}

Write-Host "Scaling Deployment '$DeploymentName' back to 1 replica..."
& kubectl scale deployment $DeploymentName --namespace $Namespace --replicas=1
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to restore the Deployment to 1 replica."
    exit 1
}

& kubectl rollout status "deployment/$DeploymentName" --namespace $Namespace --timeout=$Timeout
if ($LASTEXITCODE -ne 0) {
    Write-Error "The Deployment did not stabilize after scaling back to 1 replica."
    exit 1
}

if ($ScaleUpSucceeded) {
    exit 0
}

exit 1
