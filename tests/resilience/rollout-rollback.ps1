param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ImageTag
)

$Namespace = "demo"
$DeploymentName = "landing-zone-demo-app"
$ContainerName = "landing-zone-demo-app"
$ImageRepository = "ghcr.io/cyrinegaaloul/landing-zone-demo-app"
$Timeout = "180s"

$CurrentImage = & kubectl get deployment $DeploymentName --namespace $Namespace --output 'jsonpath={.spec.template.spec.containers[0].image}'
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($CurrentImage)) {
    Write-Error "Could not read the current Deployment image."
    exit 1
}
$CurrentImage = $CurrentImage.Trim()

$NewImage = "${ImageRepository}:$ImageTag"
Write-Host "Current image: $CurrentImage"
Write-Host "New image:     $NewImage"

& kubectl set image "deployment/$DeploymentName" "$ContainerName=$NewImage" --namespace $Namespace
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to update the Deployment image."
    exit 1
}

& kubectl rollout status "deployment/$DeploymentName" --namespace $Namespace --timeout=$Timeout
$RolloutSucceeded = $LASTEXITCODE -eq 0
if ($RolloutSucceeded) {
    Write-Host "Rollout completed successfully."
}
else {
    Write-Host "Rollout did not complete successfully."
}

$Rollback = Read-Host "Rollback to the previous image? Type 'yes' to rollback"
if ($Rollback -eq "yes") {
    & kubectl rollout undo "deployment/$DeploymentName" --namespace $Namespace
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to start the rollback."
        exit 1
    }

    & kubectl rollout status "deployment/$DeploymentName" --namespace $Namespace --timeout=$Timeout
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Rollback completed successfully."
        exit 0
    }

    Write-Error "Rollback did not complete successfully."
    exit 1
}

Write-Host "Rollback skipped. The Deployment remains on '$NewImage'."
if (-not $RolloutSucceeded) {
    exit 1
}
