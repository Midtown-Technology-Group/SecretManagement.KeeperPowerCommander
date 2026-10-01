# Keeper SecretManagement extension guidance

This PowerShell extension implements the standard SecretManagement vault interface using Keeper PowerCommander, not Keeper Secrets Manager. Read [README.md](README.md), [docs/BOOTSTRAP.md](docs/BOOTSTRAP.md), and the relevant import/publishing runbook before changing operator behavior.

## Map and contracts

`SecretManagement.KeeperPowerCommander/` contains the module manifest and nested extension. `scripts/` contains local installation, vault registration, import verification, child-process injection, and Gallery publishing. `tests/` covers manifests and lookup modes. Preserve `Map`, `KeeperTitle`, and map-first `Hybrid` behavior, UID/field overrides, and the documented default Password field.

Live operator map files store record references and metadata only, never secret values, and belong outside the repo. Keep `examples/keeper-secret-map.example.json` as a checked-in non-secret template; copy it before adding local aliases or field overrides. Plaintext is allowed only at the downstream boundary that requires it; never emit it to logs, transcripts, exceptions, or artifacts. Use the injection launcher rather than copying a secret into a command string. SSO may require an operator; do not treat an interactive override as completed authentication or weaken authentication to avoid a prompt.

## Checks and operator boundaries

CI installs SecretManagement and PowerCommander, validates both manifests with `Test-ModuleManifest`, and registers a temporary test vault using the example map before metadata enumeration and `Test-SecretVault`. Use an isolated temporary vault name/map; do not clobber an operator's registration. Read `.github/workflows/ci.yml` for exact manifest paths and prerequisite modules. The existence of tests does not establish a passing Pester run.

Imports must use the documented `-WhatIf` preview and preserve LocalStore source entries. Keeper record writes, vault registration, import, dependency-module patches, and Gallery publication need the user's exact authorized scope. Publishing requires a clean checkout, ModuleVersion update, and [docs/PUBLISHING.md](docs/PUBLISHING.md); never print a Gallery API key.
