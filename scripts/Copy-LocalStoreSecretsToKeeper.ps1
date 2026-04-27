[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter()]
    [string] $SourceVault = "LocalStore",

    [Parameter()]
    [string] $DestinationVault = "KeeperPowerCommander",

    [Parameter()]
    [string[]] $Name = @("*"),

    [Parameter()]
    [string] $Folder,

    [Parameter()]
    [switch] $Force
)

$ErrorActionPreference = "Stop"

Import-Module Microsoft.PowerShell.SecretManagement -ErrorAction Stop

$destination = Get-SecretVault -Name $DestinationVault -ErrorAction Stop
if ($destination.ModuleName -ne "SecretManagement.KeeperPowerCommander") {
    throw "Destination vault '$DestinationVault' is backed by '$($destination.ModuleName)', not SecretManagement.KeeperPowerCommander."
}

$selected = foreach ($pattern in $Name) {
    Get-SecretInfo -Vault $SourceVault -Name $pattern
}

$selected = $selected | Sort-Object Name -Unique
if (-not $selected) {
    Write-Host "No LocalStore secrets matched the requested name pattern."
    return
}

foreach ($item in $selected) {
    $metadata = @{
        Description = "Migrated from SecretManagement vault '$SourceVault'."
        Field = "Password"
        RecordType = "login"
    }
    if ($Folder) { $metadata.Folder = $Folder }

    $targetExists = Get-SecretInfo -Vault $DestinationVault -Name $item.Name -ErrorAction SilentlyContinue
    if ($targetExists -and -not $Force.IsPresent) {
        Write-Host "Skip existing mapping: $($item.Name)"
        continue
    }

    if ($PSCmdlet.ShouldProcess($item.Name, "Copy secret from '$SourceVault' to '$DestinationVault'")) {
        Write-Host "Copying: $($item.Name)"
        $secret = Get-Secret -Vault $SourceVault -Name $item.Name
        Set-Secret -Vault $DestinationVault -Name $item.Name -Secret $secret -Metadata $metadata
    }
}
