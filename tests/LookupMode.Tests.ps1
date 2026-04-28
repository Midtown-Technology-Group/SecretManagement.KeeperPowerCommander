Describe "KeeperPowerCommander lookup modes" {
    BeforeAll {
        $modulePath = Join-Path $PSScriptRoot "..\SecretManagement.KeeperPowerCommander\SecretManagement.KeeperPowerCommander.Extension\SecretManagement.KeeperPowerCommander.Extension.psm1"
        Import-Module Microsoft.PowerShell.SecretManagement -ErrorAction Stop
        Import-Module $modulePath -Force

        function global:Connect-Keeper { }
        function global:Get-KeeperRecord {
            param([string] $Uid)

            [pscustomobject]@{
                Uid = $Uid
                Name = "bifrost/credentials"
                Login = "operator"
                Link = "https://example.test"
                Notes = "notes"
            }
        }
        function global:Get-KeeperRecordPassword {
            param(
                [object] $Record,
                [switch] $Silent
            )

            "secret-for-$($Record.Uid)"
        }
        function global:Get-KeeperChildItem {
            param([string] $ObjectType)

            @(
                [pscustomobject]@{
                    Uid = "uid-bifrost"
                    Name = "bifrost/credentials"
                },
                [pscustomobject]@{
                    Uid = "uid-pax8"
                    Name = "pax8-mcp"
                }
            )
        }
    }

    It "resolves a secret directly from Keeper record title without a map file" {
        $secret = Get-Secret `
            -VaultName KeeperPowerCommander `
            -Name "bifrost/credentials" `
            -VaultParameters @{
                LookupMode = "KeeperTitle"
                SkipConnect = $true
            }

        [System.Net.NetworkCredential]::new("", $secret).Password | Should Be "secret-for-uid-bifrost"
    }

    It "lists Keeper record titles as SecretInformation in KeeperTitle mode" {
        $infos = @(Get-SecretInfo `
            -VaultName KeeperPowerCommander `
            -VaultParameters @{
                LookupMode = "KeeperTitle"
                SkipConnect = $true
            })

        ($infos.Name -contains "bifrost/credentials") | Should Be $true
        ($infos.Name -contains "pax8-mcp") | Should Be $true
        $infos[0].VaultName | Should Be "KeeperPowerCommander"
    }

    It "uses mapped entries before Keeper title discovery in Hybrid mode" {
        $mapPath = Join-Path $TestDrive "keeper-map.json"
        @{
            secrets = @(
                @{
                    name = "bifrost/credentials"
                    uid = "uid-from-map"
                    field = "Password"
                }
            )
        } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $mapPath -Encoding UTF8

        $secret = Get-Secret `
            -VaultName KeeperPowerCommander `
            -Name "bifrost/credentials" `
            -VaultParameters @{
                LookupMode = "Hybrid"
                MapPath = $mapPath
                SkipConnect = $true
            }

        [System.Net.NetworkCredential]::new("", $secret).Password | Should Be "secret-for-uid-from-map"
    }

    It "surfaces Keeper SSO URL output while connecting" {
        $script:hostMessages = @()

        function global:Write-Host {
            param(
                [Parameter(ValueFromRemainingArguments = $true)]
                [object[]] $Object
            )

            $script:hostMessages += ($Object -join " ")
        }

        function global:Import-Module {
            param(
                [Parameter(Position = 0)]
                [string] $Name
            )

            if ($Name -eq "PowerCommander") { return }
            Microsoft.PowerShell.Core\Import-Module @PSBoundParameters
        }

        function global:Connect-Keeper {
            "Open this URL to complete SSO: https://keeper.test/sso"
        }

        Connect-KeeperPowerCommander -VaultParameters @{}

        ($script:hostMessages -join "`n") | Should Match "https://keeper.test/sso"
    }
}
