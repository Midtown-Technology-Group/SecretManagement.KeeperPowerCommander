@{
    RootModule = 'SecretManagement.KeeperPowerCommander.Extension.psm1'
    ModuleVersion = '0.1.0'
    GUID = '5a73885a-d630-42ef-86ca-1409c2e6aef9'
    Author = 'Midtown Technology Group'
    CompanyName = 'Midtown Technology Group'
    Copyright = '(c) 2026 Midtown Technology Group'
    Description = 'Implementation module for SecretManagement.KeeperPowerCommander.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @('Set-Secret','Set-SecretInfo','Get-Secret','Remove-Secret','Get-SecretInfo','Unlock-SecretVault','Test-SecretVault')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
}
