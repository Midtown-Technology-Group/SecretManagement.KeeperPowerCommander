param(
    [Parameter(Mandatory = $true)]
    [string] $VaultName,

    [Parameter(Mandatory = $true)]
    [string] $SecretName,

    [Parameter(Mandatory = $true)]
    [string] $EnvName,

    [Parameter(Mandatory = $true)]
    [string] $Command,

    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]] $CommandArgs,

    [Parameter()]
    [int] $TimeoutSeconds = 60
)

$ErrorActionPreference = "Stop"

$pwshModulePath = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "PowerShell\Modules"
if ((Test-Path -LiteralPath $pwshModulePath) -and (($env:PSModulePath -split ';') -notcontains $pwshModulePath)) {
    $env:PSModulePath = "$pwshModulePath;$env:PSModulePath"
}

$modulePath = $env:PSModulePath
$job = Start-Job -ScriptBlock {
    param($VaultName, $SecretName, $ModulePath)
    $env:PSModulePath = $ModulePath
    Import-Module Microsoft.PowerShell.SecretManagement -ErrorAction Stop
    Get-Secret -Vault $VaultName -Name $SecretName -AsPlainText -ErrorAction Stop
} -ArgumentList $VaultName, $SecretName, $modulePath

try {
    if (-not (Wait-Job -Job $job -Timeout $TimeoutSeconds)) {
        Stop-Job -Job $job -ErrorAction SilentlyContinue
        throw "Timed out after $TimeoutSeconds seconds while retrieving SecretManagement secret '$SecretName' from vault '$VaultName'."
    }

    $secret = Receive-Job -Job $job
    if ($job.State -ne "Completed") {
        throw ($secret -join [Environment]::NewLine)
    }
    $secret = [string] ($secret -join [Environment]::NewLine)
}
finally {
    Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
}

if ([string]::IsNullOrEmpty($secret)) {
    throw "SecretManagement returned an empty secret for '$SecretName'."
}

Set-Item -Path "env:$EnvName" -Value $secret

try {
    & $Command @CommandArgs
    exit $LASTEXITCODE
}
finally {
    Remove-Item -Path "env:$EnvName" -ErrorAction SilentlyContinue
}
