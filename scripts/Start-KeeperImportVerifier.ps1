param(
    [Parameter()]
    [string] $RepositoryPath = (Split-Path -Parent $PSScriptRoot),

    [Parameter()]
    [string[]] $Name = @("*"),

    [Parameter()]
    [string] $ReportPath = (Join-Path $env:TEMP "keeper-localstore-import-verification.json")
)

$ErrorActionPreference = "Stop"

$verifyScript = Join-Path $RepositoryPath "scripts\Test-LocalStoreKeeperImport.ps1"
if (-not (Test-Path -LiteralPath $verifyScript)) {
    throw "Verifier script not found at '$verifyScript'."
}

$nameLiteral = "@(" + (($Name | ForEach-Object { "'" + ($_ -replace "'", "''") + "'" }) -join ", ") + ")"
$launcher = @"
`$ErrorActionPreference = "Stop"
Set-Location '$($RepositoryPath -replace "'", "''")'
Import-Module PowerCommander -ErrorAction Stop
Import-Module Microsoft.PowerShell.SecretManagement -ErrorAction Stop
Import-Module SecretManagement.KeeperPowerCommander -Force -ErrorAction Stop
if (Get-SecretVault -Name KeeperPowerCommander -ErrorAction SilentlyContinue) {
    Unregister-SecretVault -Name KeeperPowerCommander
}
Register-SecretVault -Name KeeperPowerCommander -ModuleName SecretManagement.KeeperPowerCommander -VaultParameters @{ MapPath = 'C:\Users\ThomasBray\.codex\keeper-secret-map.json' }
Write-Host "Connecting to Keeper. Complete SSO if prompted..." -ForegroundColor Cyan
Connect-Keeper | Out-Null
& '$($verifyScript -replace "'", "''")' -Name $nameLiteral -ReportPath '$($ReportPath -replace "'", "''")' -Verbose
Write-Host ""
Write-Host "Report written to $($ReportPath -replace "'", "''")" -ForegroundColor Green
Read-Host "Press Enter to close"
"@

$launcherPath = Join-Path $env:TEMP "keeper-localstore-import-verifier-launch.ps1"
Set-Content -LiteralPath $launcherPath -Value $launcher -Encoding UTF8
Start-Process powershell.exe -ArgumentList @("-NoExit", "-ExecutionPolicy", "Bypass", "-File", $launcherPath)

[pscustomobject]@{
    Started = $true
    LauncherPath = $launcherPath
    ReportPath = $ReportPath
}
