[CmdletBinding()]
param(
    [Parameter()]
    [string] $SourceVault = "LocalStore",

    [Parameter()]
    [string] $DestinationVault = "KeeperPowerCommander",

    [Parameter()]
    [string[]] $Name = @("*"),

    [Parameter()]
    [string] $ReportPath = (Join-Path $env:TEMP "keeper-localstore-import-verification.json"),

    [Parameter()]
    [switch] $StopOnFailure
)

$ErrorActionPreference = "Stop"

function Get-SecretLength {
    param([object] $Value)

    if ($null -eq $Value) { return $null }
    if ($Value -is [securestring]) {
        return [System.Net.NetworkCredential]::new("", $Value).Password.Length
    }
    if ($Value -is [pscredential]) {
        return $Value.GetNetworkCredential().Password.Length
    }
    return ([string] $Value).Length
}

Import-Module Microsoft.PowerShell.Security -ErrorAction Stop
Import-Module Microsoft.PowerShell.SecretManagement -ErrorAction Stop

$selected = foreach ($pattern in $Name) {
    Get-SecretInfo -Vault $SourceVault -Name $pattern
}
$selected = @($selected | Sort-Object Name -Unique)

$results = New-Object System.Collections.Generic.List[object]
$total = $selected.Count
$overall = [System.Diagnostics.Stopwatch]::StartNew()

Write-Host "Verifying $total secret(s) from '$SourceVault' against '$DestinationVault'."
Write-Host "Report path: $ReportPath"

for ($index = 0; $index -lt $total; $index++) {
    $item = $selected[$index]
    $displayIndex = $index + 1
    $percent = if ($total -gt 0) { ($displayIndex / $total) * 100 } else { 100 }
    $timer = [System.Diagnostics.Stopwatch]::StartNew()

    Write-Progress -Activity "Verifying Keeper import" -Status "$displayIndex/$total $($item.Name)" -PercentComplete $percent
    Write-Host ("[{0}/{1}] {2}" -f $displayIndex, $total, $item.Name)
    Write-Verbose "Reading source secret '$($item.Name)' from '$SourceVault'."

    try {
        $source = Get-Secret -Vault $SourceVault -Name $item.Name -ErrorAction Stop
        $sourceLength = Get-SecretLength -Value $source

        Write-Verbose "Reading destination metadata for '$($item.Name)' from '$DestinationVault'."
        $destInfo = Get-SecretInfo -Vault $DestinationVault -Name $item.Name -ErrorAction Stop

        Write-Verbose "Reading destination secret '$($item.Name)' from '$DestinationVault'."
        $dest = Get-Secret -Vault $DestinationVault -Name $item.Name -ErrorAction Stop
        $destLength = Get-SecretLength -Value $dest

        $ok = ($sourceLength -eq $destLength) -and ([string] $destInfo.Type -eq "SecureString")
        $timer.Stop()

        $status = if ($ok) { "OK" } else { "FAIL" }
        Write-Host ("  {0} source={1} dest={2} type={3} elapsed={4:n1}s" -f $status, $sourceLength, $destLength, $destInfo.Type, $timer.Elapsed.TotalSeconds)

        $result = [pscustomobject]@{
            Name = $item.Name
            Status = $status
            SourceType = [string] $item.Type
            DestType = [string] $destInfo.Type
            SourceLength = $sourceLength
            DestLength = $destLength
            LengthMatches = ($sourceLength -eq $destLength)
            ElapsedSeconds = [Math]::Round($timer.Elapsed.TotalSeconds, 3)
            Error = $null
        }
    }
    catch {
        $timer.Stop()
        Write-Host ("  FAIL elapsed={0:n1}s error={1}" -f $timer.Elapsed.TotalSeconds, $_.Exception.Message) -ForegroundColor Red

        $result = [pscustomobject]@{
            Name = $item.Name
            Status = "FAIL"
            SourceType = [string] $item.Type
            DestType = $null
            SourceLength = $null
            DestLength = $null
            LengthMatches = $false
            ElapsedSeconds = [Math]::Round($timer.Elapsed.TotalSeconds, 3)
            Error = $_.Exception.Message
        }

        if ($StopOnFailure.IsPresent) {
            $results.Add($result)
            break
        }
    }

    $results.Add($result)
}

Write-Progress -Activity "Verifying Keeper import" -Completed
$overall.Stop()

$failures = @($results | Where-Object { $_.Status -ne "OK" -or -not $_.LengthMatches -or $_.DestType -ne "SecureString" })
$summary = [pscustomobject]@{
    Checked = $results.Count
    Failures = $failures.Count
    DestSecureStringCount = @($results | Where-Object { $_.DestType -eq "SecureString" }).Count
    ElapsedSeconds = [Math]::Round($overall.Elapsed.TotalSeconds, 3)
    GeneratedAt = (Get-Date).ToString("o")
    FailureItems = @($failures | Select-Object Name,Status,SourceType,DestType,SourceLength,DestLength,LengthMatches,ElapsedSeconds,Error)
}

$summary |
    ConvertTo-Json -Depth 6 |
    Set-Content -LiteralPath $ReportPath -Encoding UTF8

$summary
