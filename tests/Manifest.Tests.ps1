Describe "SecretManagement.KeeperPowerCommander manifest" {
    It "imports the module manifest" {
        $modulePath = Join-Path $PSScriptRoot "..\SecretManagement.KeeperPowerCommander\SecretManagement.KeeperPowerCommander.psd1"
        Test-ModuleManifest -Path $modulePath | Should Not BeNullOrEmpty
    }
}
