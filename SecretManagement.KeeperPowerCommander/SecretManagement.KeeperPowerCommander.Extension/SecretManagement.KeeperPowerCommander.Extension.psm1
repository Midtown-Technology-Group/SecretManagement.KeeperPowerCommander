function Get-KeeperPowerCommanderMap {
    param([hashtable] $VaultParameters)

    if (-not $VaultParameters) { $VaultParameters = @{} }
    $mapPath = $VaultParameters.MapPath
    if (-not $mapPath) {
        $mapPath = Join-Path $env:USERPROFILE ".keeper-secret-map.json"
    }

    if (-not (Test-Path -LiteralPath $mapPath)) {
        throw "Keeper secret map not found at '$mapPath'."
    }

    $raw = Get-Content -LiteralPath $mapPath -Raw
    $map = $raw | ConvertFrom-Json
    return @($map.secrets)
}

function Find-KeeperPowerCommanderSecret {
    param(
        [string] $Name,
        [hashtable] $VaultParameters
    )

    Get-KeeperPowerCommanderMap -VaultParameters $VaultParameters |
        Where-Object { $_.name -eq $Name } |
        Select-Object -First 1
}

function Get-KeeperPowerCommanderFieldValue {
    param(
        [object] $Record,
        [string] $Field
    )

    switch -Regex ($Field) {
        '^password$' { return Get-KeeperRecordPassword -Record $Record -Silent }
        '^login$' { return $Record.Login }
        '^url$' {
            if ($Record.Link) { return $Record.Link }
            return $Record.Url
        }
        '^notes$' { return $Record.Notes }
    }

    foreach ($collectionName in @("Custom", "Fields")) {
        $property = $Record.PSObject.Properties[$collectionName]
        if (-not $property) { continue }

        foreach ($item in @($property.Value)) {
            $label = $item.Label
            if (-not $label) { $label = $item.Name }
            if (-not $label) { $label = $item.TypeName }

            if ($label -and ($label -ieq $Field)) {
                $candidate = $item.Value
                if ($candidate -is [System.Array]) {
                    $candidate = $candidate | Select-Object -First 1
                }
                return [string] $candidate
            }
        }
    }

    return $null
}

function Connect-KeeperPowerCommander {
    param([hashtable] $VaultParameters)

    if (-not $VaultParameters) { $VaultParameters = @{} }
    Import-Module PowerCommander -ErrorAction Stop

    if ($VaultParameters.Config) {
        Connect-Keeper -Config $VaultParameters.Config | Out-Null
    }
    else {
        Connect-Keeper | Out-Null
    }
}

function Set-Secret {
    param(
        [string] $VaultName,
        [string] $Name,
        [object] $Secret,
        [hashtable] $VaultParameters,
        [hashtable] $Metadata,
        [hashtable] $AdditionalParameters
    )

    throw "SecretManagement.KeeperPowerCommander is read-only. Update Keeper records in Keeper."
}

function Set-SecretInfo {
    param(
        [string] $VaultName,
        [string] $Name,
        [hashtable] $Metadata,
        [hashtable] $VaultParameters,
        [hashtable] $AdditionalParameters
    )

    throw "SecretManagement.KeeperPowerCommander is read-only. Update metadata in the local map file."
}

function Get-Secret {
    param(
        [string] $VaultName,
        [string] $Name,
        [hashtable] $VaultParameters,
        [hashtable] $AdditionalParameters
    )

    if (-not $VaultParameters -and $AdditionalParameters) { $VaultParameters = $AdditionalParameters }
    $entry = Find-KeeperPowerCommanderSecret -Name $Name -VaultParameters $VaultParameters
    if (-not $entry) { return $null }

    Connect-KeeperPowerCommander -VaultParameters $VaultParameters

    $record = Get-KeeperRecord -Uid $entry.uid -ErrorAction Stop
    $field = if ($entry.field) { $entry.field } else { "Password" }
    $value = Get-KeeperPowerCommanderFieldValue -Record $record -Field $field
    if ([string]::IsNullOrEmpty($value)) { return $null }

    ConvertTo-SecureString -String $value -AsPlainText -Force
}

function Remove-Secret {
    param(
        [string] $VaultName,
        [string] $Name,
        [hashtable] $VaultParameters,
        [hashtable] $AdditionalParameters
    )

    throw "SecretManagement.KeeperPowerCommander is read-only. Remove or rotate Keeper records in Keeper."
}

function Get-SecretInfo {
    param(
        [string] $VaultName,
        [string] $Filter,
        [hashtable] $VaultParameters,
        [hashtable] $AdditionalParameters
    )

    if (-not $VaultParameters -and $AdditionalParameters) { $VaultParameters = $AdditionalParameters }
    if ([string]::IsNullOrEmpty($Filter)) { $Filter = "*" }

    $entries = Get-KeeperPowerCommanderMap -VaultParameters $VaultParameters |
        Where-Object { $_.name -like $Filter }

    foreach ($entry in $entries) {
        $metadata = @{
            KeeperUid = $entry.uid
            Field = if ($entry.field) { $entry.field } else { "Password" }
        }
        if ($entry.description) { $metadata.Description = $entry.description }

        [Microsoft.PowerShell.SecretManagement.SecretInformation]::new(
            [string] $entry.name,
            [Microsoft.PowerShell.SecretManagement.SecretType]::SecureString,
            $VaultName,
            $metadata
        )
    }
}

function Unlock-SecretVault {
    param(
        [string] $VaultName,
        [hashtable] $VaultParameters,
        [hashtable] $AdditionalParameters
    )

    if (-not $VaultParameters -and $AdditionalParameters) { $VaultParameters = $AdditionalParameters }
    Connect-KeeperPowerCommander -VaultParameters $VaultParameters
    return $true
}

function Test-SecretVault {
    param(
        [string] $VaultName,
        [hashtable] $VaultParameters,
        [hashtable] $AdditionalParameters
    )

    try {
        if (-not $VaultParameters -and $AdditionalParameters) { $VaultParameters = $AdditionalParameters }
        $null = Get-KeeperPowerCommanderMap -VaultParameters $VaultParameters
        Import-Module PowerCommander -ErrorAction Stop
        return $true
    }
    catch {
        Write-Error $_
        return $false
    }
}
