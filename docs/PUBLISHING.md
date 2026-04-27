# Publishing

Publish from a clean checkout on `main`.

## Preflight

```powershell
git status --short --branch
Test-ModuleManifest .\SecretManagement.KeeperPowerCommander\SecretManagement.KeeperPowerCommander.psd1
```

Run the dry run:

```powershell
$apiKey = Get-Secret -Vault LocalStore -Name 'powershell-gallery/mtg-thomas-publish-to-gallery-api-secret' -AsPlainText
.\scripts\Publish-GalleryRelease.ps1 -NuGetApiKey $apiKey -WhatIf
```

## Publish

```powershell
.\scripts\Publish-GalleryRelease.ps1 -NuGetApiKey $apiKey
```

## GitHub Release

After Gallery publish succeeds:

```powershell
git tag v0.1.2
git push origin main --tags
gh release create v0.1.2 --title "v0.1.2" --notes "Clean package metadata and add bootstrap/publishing helpers."
```

Always increment `ModuleVersion` before publishing another Gallery version.
