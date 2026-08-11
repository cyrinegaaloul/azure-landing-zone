[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $WorkloadIdentityClientId,
    [Parameter(Mandatory)] [string] $TenantId,
    [Parameter(Mandatory)] [string] $KeyVaultName,
    [Parameter(Mandatory)] [string] $ImageReference,
    [Parameter(Mandatory)] [string] $BackendIp,
    [Parameter(Mandatory)] [string] $AksSubnetName,
    [Parameter(Mandatory)] [string] $ApimSubnetCidr,
    [Parameter(Mandatory)] [string] $AksSubnetCidr,
    [Parameter(Mandatory)] [string] $PrivateEndpointSubnetCidr,
    [Parameter(Mandatory)] [string] $OutputPath
)

$ErrorActionPreference = 'Stop'

$rendered = (& kubectl kustomize app/k8s) -join "`n"
if ($LASTEXITCODE -ne 0) {
    throw 'Kustomize rendering failed.'
}

$replacements = [ordered]@{
    'REPLACE_WITH_MANAGED_IDENTITY_CLIENT_ID' = $WorkloadIdentityClientId
    'REPLACE_WITH_TENANT_ID'                  = $TenantId
    'REPLACE_WITH_KEY_VAULT_NAME'             = $KeyVaultName
    'REPLACE_WITH_IMAGE_REFERENCE'            = $ImageReference
    'REPLACE_WITH_AKS_BACKEND_IP'             = $BackendIp
    'REPLACE_WITH_AKS_SUBNET_NAME'             = $AksSubnetName
    'REPLACE_WITH_APIM_SUBNET_CIDR'            = $ApimSubnetCidr
    'REPLACE_WITH_AKS_SUBNET_CIDR'             = $AksSubnetCidr
    'REPLACE_WITH_PRIVATE_ENDPOINT_SUBNET_CIDR' = $PrivateEndpointSubnetCidr
}

foreach ($replacement in $replacements.GetEnumerator()) {
    if ([string]::IsNullOrWhiteSpace($replacement.Value)) {
        throw "A value for $($replacement.Key) is required."
    }
    $rendered = $rendered.Replace($replacement.Key, $replacement.Value)
}

if ($rendered -match 'REPLACE_WITH_[A-Z0-9_]+') {
    throw "Rendered Kubernetes configuration still contains placeholder: $($Matches[0])"
}

$outputDirectory = Split-Path -Parent $OutputPath
if ($outputDirectory) {
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
}
[System.IO.File]::WriteAllText($OutputPath, "$rendered`n", [System.Text.UTF8Encoding]::new($false))
Write-Host "Rendered deployment configuration: $OutputPath"
