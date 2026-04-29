@{
    NestedModules = @('.\SecretManagement.KeeperPowerCommander.Extension')
    RequiredModules = @(
        @{
            ModuleName = 'Microsoft.PowerShell.SecretManagement'
            ModuleVersion = '1.1.2'
        }
    )
    ModuleVersion = '0.3.3'
    GUID = 'f7acb793-1f9b-4dd3-a512-4bb263735982'
    Author = 'Midtown Technology Group'
    CompanyName = 'Midtown Technology Group'
    Copyright = '(c) 2026 Midtown Technology Group'
    Description = 'SecretManagement extension vault backed by Keeper PowerCommander.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @()
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('SecretManagement', 'Keeper', 'PowerCommander', 'Vault')
            LicenseUri = 'https://www.gnu.org/licenses/agpl-3.0.txt'
            LicenseExpression = 'AGPL-3.0-or-later'
            ProjectUri = 'https://github.com/Midtown-Technology-Group/SecretManagement.KeeperPowerCommander'
            ReleaseNotes = 'Avoid forced SSO refresh during normal secret reads and surface a clear visible-shell command when Keeper auth is required from noninteractive sessions.'
        }
    }
}
