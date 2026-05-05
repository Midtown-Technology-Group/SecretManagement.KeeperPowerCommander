param(
    [Parameter(Mandatory = $true)]
    [string] $NuGetApiKey,

    [Parameter()]
    [switch] $WhatIf,

    [Parameter()]
    [switch] $Force
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$modulePath = Join-Path $repoRoot "SecretManagement.KeeperPowerCommander"
$manifestPath = Join-Path $modulePath "SecretManagement.KeeperPowerCommander.psd1"

Test-ModuleManifest -Path $manifestPath | Out-Null

$publishParams = @{
    Path = $modulePath
    NuGetApiKey = $NuGetApiKey
    Verbose = $true
}

if ($WhatIf.IsPresent) {
    $publishParams.WhatIf = $true
}

if ($Force.IsPresent) {
    $publishParams.Force = $true
}

Publish-Module @publishParams
