param(
    [Parameter()]
    [string] $Name = "KeeperPowerCommander",

    [Parameter()]
    [string] $MapPath = (Join-Path $env:USERPROFILE ".keeper-secret-map.json"),

    [Parameter()]
    [switch] $AllowClobber
)

$ErrorActionPreference = "Stop"

Import-Module Microsoft.PowerShell.SecretManagement -ErrorAction Stop

if (-not (Test-Path -LiteralPath $MapPath)) {
    throw "Map file not found at '$MapPath'. Copy examples\keeper-secret-map.example.json and update it first."
}

$params = @{
    Name = $Name
    ModuleName = "SecretManagement.KeeperPowerCommander"
    VaultParameters = @{ MapPath = $MapPath }
}

if ($AllowClobber.IsPresent) {
    $params.AllowClobber = $true
}

Register-SecretVault @params
Get-SecretVault -Name $Name
