# LocalStore to Keeper Import Plan

Date: 2026-04-27

## Current State

- Source vault: `LocalStore`
- Destination vault: `KeeperPowerCommander`
- Destination module: `SecretManagement.KeeperPowerCommander` 0.2.0
- Destination map: `C:\Users\ThomasBray\.codex\keeper-secret-map.json`
- LocalStore entries: 182 total
  - 175 `String`
  - 7 `SecureString`
- Existing KeeperPowerCommander mappings:
  - `pax8-mcp`
  - `codex/dogfood/test-write-2026-04-27`

## Guardrails

- Do not print secret values.
- Do not remove anything from `LocalStore` during import.
- Import into a clearly named Keeper folder first, preserving the SecretManagement name as the Keeper record title.
- Use `-WhatIf` before every real batch.
- Verify every batch by reading through `KeeperPowerCommander` and comparing type/length in memory only.
- Keep destructive cleanup manual until a separate cleanup plan is reviewed.

## Keeper Folder

Use one flat Keeper folder for the first import:

```powershell
Connect-Keeper | Out-Null
Add-KeeperFolder -Name "Codex LocalStore Import 2026-04-27"
```

If the folder already exists, reuse it.

## Canary

Start with the PowerShell Gallery secret because it is a single `SecureString` and already proved useful for publishing this module.

```powershell
.\scripts\Copy-LocalStoreSecretsToKeeper.ps1 `
  -Name "powershell-gallery/*" `
  -Folder "Codex LocalStore Import 2026-04-27" `
  -WhatIf

.\scripts\Copy-LocalStoreSecretsToKeeper.ps1 `
  -Name "powershell-gallery/*" `
  -Folder "Codex LocalStore Import 2026-04-27"
```

Verify:

```powershell
$name = "powershell-gallery/mtg-thomas-publish-to-gallery-api-secret"
$source = Get-Secret -Vault LocalStore -Name $name
$dest = Get-Secret -Vault KeeperPowerCommander -Name $name
[System.Net.NetworkCredential]::new("", $source).Password.Length -eq
  [System.Net.NetworkCredential]::new("", $dest).Password.Length
```

## Batch Order

Import in small batches by prefix. Run each with `-WhatIf`, then without `-WhatIf`, then verify mapped count and no-leak round trips.

1. `powershell-gallery/*`
2. Top-level non-`pass` entries:
   - `/bifrost-docs/*`
   - `bifrost-docs/*`
   - `github/*`
   - `neon/*`
   - `cloudflare/*`
   - `netbird/*`
   - `proxmox/*`
   - `siteground/*`
   - `bifrost/*`
3. Low-count `pass` groups:
   - `pass/context7/*`
   - `pass/idemeum/*`
   - `pass/vercel/*`
   - `pass/personal/*`
   - `pass/dnsfilter/*`
   - `pass/pax8/*`
   - `pass/itglue/*`
   - `pass/meraki/*`
   - `pass/logmeininc/*`
4. Infrastructure/service groups:
   - `pass/cloudflare/*`
   - `pass/github/*`
   - `pass/azure/*`
   - `pass/bifrost/*`
   - `pass/proxmox/*`
5. Vendor integration groups:
   - `pass/autotask/*`
   - `pass/halopsa/*`
   - `pass/cipp/*`
   - `pass/ninjaone/*`
   - `pass/huntress/*`
   - `pass/connectsecure/*`
   - `pass/cove/*`
   - `pass/vipre/*`
   - Remaining `pass/*`

## Batch Template

```powershell
$folder = "Codex LocalStore Import 2026-04-27"
$pattern = "pass/pax8/*"

.\scripts\Copy-LocalStoreSecretsToKeeper.ps1 -Name $pattern -Folder $folder -WhatIf
.\scripts\Copy-LocalStoreSecretsToKeeper.ps1 -Name $pattern -Folder $folder

Get-SecretInfo -Vault KeeperPowerCommander -Name $pattern |
  Select-Object Name,Type,VaultName
```

## Follow-Up Improvements

- Teach the copy helper to verify source/destination lengths after each import.
- Add an optional `-CreateFolder` switch for simple root-level Keeper folders.
- Add a report mode that summarizes planned names and types without touching values.
- Decide later whether to reorganize Keeper records into nested operational folders.
