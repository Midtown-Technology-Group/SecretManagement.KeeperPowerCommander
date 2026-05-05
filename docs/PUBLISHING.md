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
.\scripts\Publish-GalleryRelease.ps1 -NuGetApiKey $apiKey -WhatIf -Force
```

## Publish

```powershell
.\scripts\Publish-GalleryRelease.ps1 -NuGetApiKey $apiKey -Force
```

## GitHub Release

After Gallery publish succeeds:

```powershell
git tag v<version>
git push origin main --tags
gh release create v<version> --title "v<version>" --notes "<release notes>"
```

Always increment `ModuleVersion` before publishing another Gallery version.
