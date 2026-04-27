@{
    NestedModules = @('.\SecretManagement.KeeperPowerCommander.Extension')
    RequiredModules = @('Microsoft.PowerShell.SecretManagement')
    ModuleVersion = '0.1.0'
    GUID = 'f7acb793-1f9b-4dd3-a512-4bb263735982'
    Author = 'Midtown Technology Group'
    CompanyName = 'Midtown Technology Group'
    Copyright = '(c) 2026 Midtown Technology Group'
    Description = 'Read-only SecretManagement extension vault backed by Keeper PowerCommander.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @()
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('SecretManagement', 'Keeper', 'PowerCommander', 'Vault')
            LicenseUri = 'https://www.gnu.org/licenses/agpl-3.0.txt'
            ProjectUri = 'https://github.com/Midtown-Technology-Group/SecretManagement.KeeperPowerCommander'
        }
    }
}
