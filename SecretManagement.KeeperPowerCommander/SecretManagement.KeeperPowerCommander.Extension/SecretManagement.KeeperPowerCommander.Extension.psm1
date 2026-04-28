function Get-KeeperPowerCommanderMapPath {
    param([hashtable] $VaultParameters)

    if (-not $VaultParameters) { $VaultParameters = @{} }
    $mapPath = $VaultParameters.MapPath
    if (-not $mapPath) {
        $mapPath = Join-Path $env:USERPROFILE ".keeper-secret-map.json"
    }

    return $mapPath
}

function Get-KeeperPowerCommanderLookupMode {
    param([hashtable] $VaultParameters)

    if (-not $VaultParameters) { $VaultParameters = @{} }
    $mode = $VaultParameters.LookupMode
    if (-not $mode) {
        if ($VaultParameters.MapPath) { return "Map" }
        return "Map"
    }

    switch -Regex ([string] $mode) {
        '^(map|mapped)$' { return "Map" }
        '^(keepertitle|title|keeper)$' { return "KeeperTitle" }
        '^(hybrid|auto)$' { return "Hybrid" }
    }

    throw "Unsupported KeeperPowerCommander LookupMode '$mode'. Use 'Map', 'KeeperTitle', or 'Hybrid'."
}

function Get-KeeperPowerCommanderMapDocument {
    param([hashtable] $VaultParameters)

    $mapPath = Get-KeeperPowerCommanderMapPath -VaultParameters $VaultParameters
    if (-not (Test-Path -LiteralPath $mapPath)) {
        [pscustomobject]@{ secrets = @() } |
            ConvertTo-Json -Depth 6 |
            Set-Content -LiteralPath $mapPath -Encoding UTF8
    }

    $raw = Get-Content -LiteralPath $mapPath -Raw
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return [pscustomobject]@{ secrets = @() }
    }

    $map = $raw | ConvertFrom-Json
    if (-not ($map.PSObject.Properties.Name -contains "secrets")) {
        $map | Add-Member -NotePropertyName secrets -NotePropertyValue @()
    }

    return $map
}

function Save-KeeperPowerCommanderMapDocument {
    param(
        [object] $Map,
        [hashtable] $VaultParameters
    )

    $mapPath = Get-KeeperPowerCommanderMapPath -VaultParameters $VaultParameters
    $parent = Split-Path -Parent $mapPath
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    $tmpPath = "$mapPath.tmp"
    $Map |
        ConvertTo-Json -Depth 12 |
        Set-Content -LiteralPath $tmpPath -Encoding UTF8
    Move-Item -LiteralPath $tmpPath -Destination $mapPath -Force
}

function Get-KeeperPowerCommanderMap {
    param([hashtable] $VaultParameters)

    $map = Get-KeeperPowerCommanderMapDocument -VaultParameters $VaultParameters
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

function ConvertTo-KeeperPowerCommanderSyntheticEntry {
    param(
        [object] $Record,
        [string] $Field
    )

    $name = $Record.Name
    if (-not $name) { $name = $Record.Title }
    if (-not $name) { return $null }

    $uid = $Record.Uid
    if (-not $uid) { $uid = $Record.UID }
    if (-not $uid) { $uid = $Record.RecordUid }
    if (-not $uid) { return $null }

    [pscustomobject]@{
        name = [string] $name
        uid = [string] $uid
        field = if ($Field) { [string] $Field } else { "Password" }
        source = "KeeperTitle"
    }
}

function Get-KeeperPowerCommanderRecordsByTitle {
    param([hashtable] $VaultParameters)

    Connect-KeeperPowerCommander -VaultParameters $VaultParameters
    @(Get-KeeperChildItem -ObjectType Record)
}

function Find-KeeperPowerCommanderSecretByTitle {
    param(
        [string] $Name,
        [hashtable] $VaultParameters
    )

    $field = if ($VaultParameters -and $VaultParameters.DefaultField) { [string] $VaultParameters.DefaultField } else { "Password" }
    Get-KeeperPowerCommanderRecordsByTitle -VaultParameters $VaultParameters |
        Where-Object {
            $_.Name -eq $Name -or
            $_.Title -eq $Name
        } |
        ForEach-Object { ConvertTo-KeeperPowerCommanderSyntheticEntry -Record $_ -Field $field } |
        Where-Object { $null -ne $_ } |
        Select-Object -First 1
}

function Find-KeeperPowerCommanderSecretEntry {
    param(
        [string] $Name,
        [hashtable] $VaultParameters
    )

    $mode = Get-KeeperPowerCommanderLookupMode -VaultParameters $VaultParameters
    if ($mode -in @("Map", "Hybrid")) {
        $entry = Find-KeeperPowerCommanderSecret -Name $Name -VaultParameters $VaultParameters
        if ($entry) { return $entry }
    }

    if ($mode -in @("KeeperTitle", "Hybrid")) {
        return Find-KeeperPowerCommanderSecretByTitle -Name $Name -VaultParameters $VaultParameters
    }

    return $null
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
    if ($VaultParameters.SkipConnect) { return }
    Import-Module PowerCommander -ErrorAction Stop

    if ($VaultParameters.Config) {
        Connect-Keeper -Config $VaultParameters.Config | ForEach-Object {
            if ($_ -is [string]) { Write-Host $_ }
        }
    }
    else {
        Connect-Keeper | ForEach-Object {
            if ($_ -is [string]) { Write-Host $_ }
        }
    }
}

function ConvertTo-KeeperPowerCommanderPlainText {
    param([object] $Secret)

    if ($Secret -is [securestring]) {
        return [System.Net.NetworkCredential]::new("", $Secret).Password
    }

    if ($Secret -is [pscredential]) {
        return $Secret.GetNetworkCredential().Password
    }

    if ($null -eq $Secret) { return "" }
    return [string] $Secret
}

function ConvertTo-KeeperPowerCommanderSecureString {
    param([object] $Secret)

    if ($Secret -is [securestring]) { return $Secret }
    ConvertTo-SecureString -String (ConvertTo-KeeperPowerCommanderPlainText -Secret $Secret) -AsPlainText -Force
}

function ConvertTo-KeeperPowerCommanderMapEntry {
    param(
        [string] $Name,
        [string] $Uid,
        [string] $Field,
        [hashtable] $Metadata
    )

    $entry = [ordered]@{
        name = $Name
        uid = $Uid
        field = $Field
    }

    if ($Metadata -and $Metadata.Description) {
        $entry.description = [string] $Metadata.Description
    }

    if ($Metadata) {
        $extra = [ordered]@{}
        foreach ($key in $Metadata.Keys) {
            if ($key -in @("Description", "Field", "KeeperUid", "Uid", "Folder", "FolderUid", "RecordType", "Title")) {
                continue
            }
            $extra[$key] = $Metadata[$key]
        }
        if ($extra.Count -gt 0) { $entry.metadata = $extra }
    }

    [pscustomobject] $entry
}

function Set-KeeperPowerCommanderMapEntry {
    param(
        [string] $Name,
        [string] $Uid,
        [string] $Field,
        [hashtable] $Metadata,
        [hashtable] $VaultParameters
    )

    $map = Get-KeeperPowerCommanderMapDocument -VaultParameters $VaultParameters
    $entries = @($map.secrets)
    $replacement = ConvertTo-KeeperPowerCommanderMapEntry -Name $Name -Uid $Uid -Field $Field -Metadata $Metadata
    $found = $false
    $updated = foreach ($entry in $entries) {
        if ($entry.name -eq $Name) {
            $found = $true
            $replacement
        }
        else {
            $entry
        }
    }

    if (-not $found) {
        $updated = @($updated) + $replacement
    }

    $map.secrets = @($updated | Sort-Object name)
    Save-KeeperPowerCommanderMapDocument -Map $map -VaultParameters $VaultParameters
}

function Get-KeeperPowerCommanderRecordUidFromOutput {
    param([object[]] $Output)

    foreach ($item in @($Output)) {
        $text = [string] $item
        if ($text -match 'Record (?:created|updated):\s*(?<uid>\S+)') {
            return $Matches.uid
        }
    }

    return $null
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

    if (-not $VaultParameters -and $AdditionalParameters) { $VaultParameters = $AdditionalParameters }
    if (-not $Metadata) { $Metadata = @{} }

    $mode = Get-KeeperPowerCommanderLookupMode -VaultParameters $VaultParameters
    $entry = Find-KeeperPowerCommanderSecretEntry -Name $Name -VaultParameters $VaultParameters
    $field = if ($Metadata.Field) { [string] $Metadata.Field } elseif ($entry -and $entry.field) { [string] $entry.field } else { "Password" }
    $uid = if ($Metadata.KeeperUid) { [string] $Metadata.KeeperUid } elseif ($Metadata.Uid) { [string] $Metadata.Uid } elseif ($entry) { [string] $entry.uid } else { $null }
    $recordType = if ($Metadata.RecordType) { [string] $Metadata.RecordType } else { "login" }
    $title = if ($Metadata.Title) { [string] $Metadata.Title } else { $Name }
    $folder = if ($Metadata.Folder) { [string] $Metadata.Folder } elseif ($Metadata.FolderUid) { [string] $Metadata.FolderUid } elseif ($VaultParameters.Folder) { [string] $VaultParameters.Folder } elseif ($VaultParameters.FolderUid) { [string] $VaultParameters.FolderUid } else { $null }

    Connect-KeeperPowerCommander -VaultParameters $VaultParameters

    $secureSecret = ConvertTo-KeeperPowerCommanderSecureString -Secret $Secret
    $fieldArguments = @("-$field", $secureSecret)
    if ($uid) {
        $null = Add-KeeperRecord -Uid $uid -Title $title -Extra $fieldArguments 6>&1
    }
    else {
        $createParams = @{
            Title = $title
            RecordType = $recordType
        }
        if ($folder) { $createParams.Folder = $folder }
        $output = Add-KeeperRecord @createParams -Extra $fieldArguments 6>&1
        $uid = Get-KeeperPowerCommanderRecordUidFromOutput -Output $output
        if (-not $uid) {
            $record = Get-KeeperChildItem -ObjectType Record |
                Where-Object Name -eq $title |
                Select-Object -First 1
            if ($record) { $uid = $record.Uid }
        }
    }

    if (-not $uid) {
        throw "Keeper record was created or updated, but the record UID could not be determined for '$Name'."
    }

    if ($mode -ne "KeeperTitle") {
        Set-KeeperPowerCommanderMapEntry -Name $Name -Uid $uid -Field $field -Metadata $Metadata -VaultParameters $VaultParameters
    }
    return $true
}

function Set-SecretInfo {
    param(
        [string] $VaultName,
        [string] $Name,
        [hashtable] $Metadata,
        [hashtable] $VaultParameters,
        [hashtable] $AdditionalParameters
    )

    if (-not $VaultParameters -and $AdditionalParameters) { $VaultParameters = $AdditionalParameters }
    if (-not $Metadata) { $Metadata = @{} }

    $entry = Find-KeeperPowerCommanderSecretEntry -Name $Name -VaultParameters $VaultParameters
    if (-not $entry) {
        throw "Secret '$Name' is not mapped in KeeperPowerCommander."
    }

    $uid = if ($Metadata.KeeperUid) { [string] $Metadata.KeeperUid } elseif ($Metadata.Uid) { [string] $Metadata.Uid } else { [string] $entry.uid }
    $field = if ($Metadata.Field) { [string] $Metadata.Field } elseif ($entry.field) { [string] $entry.field } else { "Password" }
    if (-not $Metadata.Description -and $entry.description) {
        $Metadata.Description = $entry.description
    }

    $mode = Get-KeeperPowerCommanderLookupMode -VaultParameters $VaultParameters
    if ($mode -eq "KeeperTitle") {
        throw "Set-SecretInfo cannot update Keeper metadata in LookupMode 'KeeperTitle'. Use Set-Secret with metadata or register with LookupMode 'Map' or 'Hybrid'."
    }

    Set-KeeperPowerCommanderMapEntry -Name $Name -Uid $uid -Field $field -Metadata $Metadata -VaultParameters $VaultParameters
    return $true
}

function Get-Secret {
    param(
        [string] $VaultName,
        [string] $Name,
        [hashtable] $VaultParameters,
        [hashtable] $AdditionalParameters
    )

    if (-not $VaultParameters -and $AdditionalParameters) { $VaultParameters = $AdditionalParameters }
    $entry = Find-KeeperPowerCommanderSecretEntry -Name $Name -VaultParameters $VaultParameters
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

    $mode = Get-KeeperPowerCommanderLookupMode -VaultParameters $VaultParameters
    if ($mode -eq "KeeperTitle") {
        $field = if ($VaultParameters.DefaultField) { [string] $VaultParameters.DefaultField } else { "Password" }
        $entries = Get-KeeperPowerCommanderRecordsByTitle -VaultParameters $VaultParameters |
            ForEach-Object { ConvertTo-KeeperPowerCommanderSyntheticEntry -Record $_ -Field $field } |
            Where-Object { $null -ne $_ -and $_.name -like $Filter }
    }
    elseif ($mode -eq "Hybrid") {
        $field = if ($VaultParameters.DefaultField) { [string] $VaultParameters.DefaultField } else { "Password" }
        $mapped = @(Get-KeeperPowerCommanderMap -VaultParameters $VaultParameters)
        $mappedNames = @($mapped | ForEach-Object { $_.name })
        $discovered = Get-KeeperPowerCommanderRecordsByTitle -VaultParameters $VaultParameters |
            ForEach-Object { ConvertTo-KeeperPowerCommanderSyntheticEntry -Record $_ -Field $field } |
            Where-Object { $null -ne $_ -and $_.name -notin $mappedNames }
        $entries = @($mapped) + @($discovered) |
            Where-Object { $_.name -like $Filter }
    }
    else {
        $entries = Get-KeeperPowerCommanderMap -VaultParameters $VaultParameters |
            Where-Object { $_.name -like $Filter }
    }

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
        $mode = Get-KeeperPowerCommanderLookupMode -VaultParameters $VaultParameters
        if ($mode -in @("Map", "Hybrid")) {
            $null = Get-KeeperPowerCommanderMap -VaultParameters $VaultParameters
        }
        Import-Module PowerCommander -ErrorAction Stop
        return $true
    }
    catch {
        Write-Error $_
        return $false
    }
}
