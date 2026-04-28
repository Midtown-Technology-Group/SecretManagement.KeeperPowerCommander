# Bootstrap

This is the local operator path for using the module with Keeper PowerCommander.

## Install from PowerShell Gallery

```powershell
Install-Module SecretManagement.KeeperPowerCommander -Scope CurrentUser
```

## Register Without a Map File

For a new workstation, use Keeper record titles directly as SecretManagement names:

```powershell
Register-KeeperPowerCommanderVault.ps1 `
  -LookupMode KeeperTitle `
  -AllowClobber
```

Or directly:

```powershell
Register-SecretVault `
  -Name KeeperPowerCommander `
  -ModuleName SecretManagement.KeeperPowerCommander `
  -VaultParameters @{ LookupMode = "KeeperTitle" } `
  -AllowClobber
```

This avoids copying a local map file. `Get-Secret -Name example-api-token` resolves the Keeper record whose title is `example-api-token`.

## Create a Map File

Copy the example to a local, untracked path and replace the UID values:

```powershell
Copy-Item .\examples\keeper-secret-map.example.json $env:USERPROFILE\.keeper-secret-map.json
notepad $env:USERPROFILE\.keeper-secret-map.json
```

The map stores friendly names and Keeper record references. It must not store secret values. Use it when you need local aliases, field overrides, or names that do not match Keeper record titles.

## Register the Vault

```powershell
Register-KeeperPowerCommanderVault.ps1 `
  -LookupMode Map `
  -MapPath "$env:USERPROFILE\.keeper-secret-map.json"
```

Or directly:

```powershell
Register-SecretVault `
  -Name KeeperPowerCommander `
  -ModuleName SecretManagement.KeeperPowerCommander `
  -VaultParameters @{ MapPath = "$env:USERPROFILE\.keeper-secret-map.json" } `
  -AllowClobber
```

## Verify

```powershell
Get-SecretVault -Name KeeperPowerCommander
Get-SecretInfo -Vault KeeperPowerCommander
Test-SecretVault -Name KeeperPowerCommander
```

To retrieve a secret:

```powershell
Get-Secret -Vault KeeperPowerCommander -Name example-api-token
```

Use `-AsPlainText` only when passing the value to a downstream process.
