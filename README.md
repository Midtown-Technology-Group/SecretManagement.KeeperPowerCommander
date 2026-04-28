# SecretManagement.KeeperPowerCommander

PowerShell SecretManagement extension vault backed by Keeper PowerCommander.

This module lets operator scripts use the standard SecretManagement interface:

```powershell
Get-SecretInfo -Vault KeeperPowerCommander
Get-Secret -Vault KeeperPowerCommander -Name pax8-mcp -AsPlainText
```

The extension uses Keeper PowerCommander to reach the Keeper Vault. It does not require Keeper Secrets Manager.

## Status

Early operator tooling. Reads and writes Keeper records through PowerCommander. Destructive operations remain intentionally conservative.

## Requirements

- Windows PowerShell 5.1 or PowerShell 7+
- `Microsoft.PowerShell.SecretManagement`
- Keeper PowerCommander
- A working Keeper/PowerCommander login session, or an operator available to complete Keeper SSO prompts

## Install

From PowerShell Gallery:

```powershell
Install-Module SecretManagement.KeeperPowerCommander -Scope CurrentUser
```

From a local clone:

```powershell
.\scripts\Install-ModuleLocal.ps1
```

Register a mapless vault that resolves SecretManagement names from Keeper record titles:

```powershell
.\scripts\Register-KeeperPowerCommanderVault.ps1 `
  -LookupMode KeeperTitle `
  -AllowClobber
```

Or create a map file outside the repo when you want local aliases, field overrides, or stable friendly names:

```powershell
Copy-Item .\examples\keeper-secret-map.example.json $env:USERPROFILE\.keeper-secret-map.json
notepad $env:USERPROFILE\.keeper-secret-map.json
```

Register a mapped vault:

```powershell
.\scripts\Register-KeeperPowerCommanderVault.ps1 `
  -MapPath "$env:USERPROFILE\.keeper-secret-map.json"
```

## Map File

The map file stores friendly SecretManagement names and Keeper record references. It must not store secret values. It is optional when the vault is registered with `LookupMode = "KeeperTitle"`.

```json
{
  "secrets": [
    {
      "name": "pax8-mcp",
      "uid": "5gKlpRgw4zF9zTxXYEgs1Q",
      "field": "Password",
      "description": "Pax8 MCP secret"
    }
  ]
}
```

Supported field names include `Password`, `Login`, `Url`, `Notes`, or a custom Keeper field label.

## Lookup Modes

- `Map` is the default. Secrets resolve only through the local map file.
- `KeeperTitle` resolves `Get-Secret` and `Get-SecretInfo` directly from Keeper record titles. This is the lightest bootstrap path for a new workstation because there is no local map file to copy.
- `Hybrid` checks the map first, then discovers additional Keeper records by title.

Direct title lookup reads the `Password` field by default. Set `DefaultField` in `VaultParameters` when another Keeper field should be used for title-discovered records.

## Read Secrets

```powershell
Get-SecretInfo -Vault KeeperPowerCommander
$secret = Get-Secret -Vault KeeperPowerCommander -Name pax8-mcp
```

Use `-AsPlainText` only at the boundary where a downstream tool requires plaintext.

## Write Secrets

`Set-Secret` creates or updates a Keeper record, then updates the local map file with the Keeper record UID.

```powershell
Set-Secret `
  -Vault KeeperPowerCommander `
  -Name "example/api-token" `
  -Secret (Read-Host -AsSecureString "Secret") `
  -Metadata @{
    Folder = "Codex/LocalStore Migration"
    Description = "Example API token"
    Field = "Password"
  }
```

To copy LocalStore entries into Keeper without deleting the source entries:

```powershell
.\scripts\Copy-LocalStoreSecretsToKeeper.ps1 `
  -Name "powershell-gallery/*" `
  -Folder "Codex/LocalStore Migration" `
  -WhatIf
```

## MCP / Environment Injection

Use the launcher to fetch a secret into an environment variable for a child process:

```powershell
.\scripts\Start-CommandWithSecret.ps1 `
  -VaultName KeeperPowerCommander `
  -SecretName pax8-mcp `
  -EnvName PAX8_MCP_SECRET `
  -Command pwsh `
  -CommandArgs '-NoProfile', '-File', '.\path\to\server.ps1'
```

## License

AGPL-3.0-or-later. See `LICENSE`.

Keeper PowerCommander is a runtime dependency under Keeper's license. See `THIRD_PARTY_NOTICES.md`.

## Publish

Publish new versions from a clean checkout after bumping `ModuleVersion`:

```powershell
$apiKey = Get-Secret -Vault LocalStore -Name 'powershell-gallery/mtg-thomas-publish-to-gallery-api-secret' -AsPlainText
.\scripts\Publish-GalleryRelease.ps1 -NuGetApiKey $apiKey -WhatIf
.\scripts\Publish-GalleryRelease.ps1 -NuGetApiKey $apiKey
```
