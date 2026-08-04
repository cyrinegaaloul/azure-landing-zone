$Namespace = "demo"
$DeploymentName = "landing-zone-demo-app"
$AppLabel = "app=landing-zone-demo-app"
$TimeoutSeconds = 180

$PodName = & kubectl get pods --namespace $Namespace --selector $AppLabel --output 'jsonpath={.items[0].metadata.name}'
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($PodName)) {
    Write-Error "Could not find an application pod in namespace '$Namespace'."
    exit 1
}
$PodName = $PodName.Trim()

Write-Host "Application pod: $PodName"
$Confirmation = Read-Host "Delete this pod and test Deployment recovery? Type 'yes' to continue"
if ($Confirmation -ne "yes") {
    Write-Host "Pod recovery test cancelled."
    exit 0
}

& kubectl delete pod $PodName --namespace $Namespace
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to delete pod '$PodName'."
    exit 1
}

Write-Host "Waiting for Deployment '$DeploymentName' to create a replacement pod..."
$Deadline = (Get-Date).AddSeconds($TimeoutSeconds)
$ReplacementPodName = ""

while ((Get-Date) -lt $Deadline) {
    $CandidatePodName = & kubectl get pods --namespace $Namespace --selector $AppLabel --output 'jsonpath={.items[0].metadata.name}' 2>$null
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($CandidatePodName)) {
        $ReplacementPodName = $CandidatePodName.Trim()
    }

    if ($ReplacementPodName -and $ReplacementPodName -ne $PodName) {
        break
    }

    Start-Sleep -Seconds 2
}

if (-not $ReplacementPodName -or $ReplacementPodName -eq $PodName) {
    Write-Host "FAILED: Kubernetes did not create a replacement pod within $TimeoutSeconds seconds."
    exit 1
}

& kubectl wait --namespace $Namespace --for=condition=Ready "pod/$ReplacementPodName" --timeout="${TimeoutSeconds}s"
if ($LASTEXITCODE -eq 0) {
    Write-Host "PASSED: replacement pod '$ReplacementPodName' is Ready."
    exit 0
}

Write-Host "FAILED: replacement pod '$ReplacementPodName' did not become Ready."
exit 1
