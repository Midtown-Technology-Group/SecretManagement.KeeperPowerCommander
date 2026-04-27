# SecretManagement.KeeperPowerCommander

Read-only PowerShell SecretManagement extension vault backed by Keeper PowerCommander.

This module lets operator scripts use the standard SecretManagement interface:

```powershell
Get-SecretInfo -Vault KeeperPowerCommander
Get-Secret -Vault KeeperPowerCommander -Name pax8-mcp -AsPlainText
```

The extension uses Keeper PowerCommander to reach the Keeper Vault. It does not require Keeper Secrets Manager.

## Status

Early operator tooling. Read-only by design.

## Requirements

- Windows PowerShell 5.1 or PowerShell 7+
- `Microsoft.PowerShell.SecretManagement`
- Keeper PowerCommander
- A working Keeper/PowerCommander login session, or an operator available to complete Keeper SSO prompts

## Install

Clone the repo, then from the repository root:

```powershell
.\scripts\Install-ModuleLocal.ps1
```

Create a map file outside the repo, for example:

```powershell
Copy-Item .\examples\keeper-secret-map.example.json $env:USERPROFILE\.keeper-secret-map.json
notepad $env:USERPROFILE\.keeper-secret-map.json
```

Register a vault:

```powershell
Register-SecretVault `
  -Name KeeperPowerCommander `
  -ModuleName SecretManagement.KeeperPowerCommander `
  -VaultParameters @{ MapPath = "$env:USERPROFILE\.keeper-secret-map.json" }
```

## Map File

The map file stores friendly SecretManagement names and Keeper record references. It must not store secret values.

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

## Read Secrets

```powershell
Get-SecretInfo -Vault KeeperPowerCommander
$secret = Get-Secret -Vault KeeperPowerCommander -Name pax8-mcp
```

Use `-AsPlainText` only at the boundary where a downstream tool requires plaintext.

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

AGPL-3.0. See `LICENSE`.

Keeper PowerCommander is a runtime dependency under Keeper's license. See `THIRD_PARTY_NOTICES.md`.
