param(
    [Parameter()]
    [string] $Destination = (Join-Path ([Environment]::GetFolderPath("MyDocuments")) "PowerShell\Modules")
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$source = Join-Path $repoRoot "SecretManagement.KeeperPowerCommander"
$target = Join-Path $Destination "SecretManagement.KeeperPowerCommander"

New-Item -ItemType Directory -Force $Destination | Out-Null
if (Test-Path -LiteralPath $target) {
    Remove-Item -LiteralPath $target -Recurse -Force
}

Copy-Item -LiteralPath $source -Destination $target -Recurse
Write-Host "Installed SecretManagement.KeeperPowerCommander to $target"
