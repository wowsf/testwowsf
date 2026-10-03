BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'WinUtilTestHelpers.psm1') -Force
    . ([scriptblock]::Create((Get-WinUtilFunctionSource -Name Test-WinUtilPackageManager)))
}

Describe 'Test-WinUtilPackageManager' {
    BeforeEach {
        Mock Write-Host {}
    }

    It 'reports winget as installed when the command resolves' {
        Mock Get-Command { [PSCustomObject]@{ Name = 'winget' } } -ParameterFilter { $Name -eq 'winget' }

        Test-WinUtilPackageManager -winget | Should -Be 'installed'
    }

    It 'reports winget as not installed when the command is missing' {
        Mock Get-Command { } -ParameterFilter { $Name -eq 'winget' }

        Test-WinUtilPackageManager -winget | Should -Be 'not-installed'
    }

    It 'reports choco as installed when the command resolves' {
        Mock Get-Command { [PSCustomObject]@{ Name = 'choco' } } -ParameterFilter { $Name -eq 'choco' }

        Test-WinUtilPackageManager -choco | Should -Be 'installed'
    }

    It 'reports choco as not installed when the command is missing' {
        Mock Get-Command { } -ParameterFilter { $Name -eq 'choco' }

        Test-WinUtilPackageManager -choco | Should -Be 'not-installed'
    }

    It 'returns the choco status last when both managers are queried' {
        Mock Get-Command { [PSCustomObject]@{ Name = 'winget' } } -ParameterFilter { $Name -eq 'winget' }
        Mock Get-Command { } -ParameterFilter { $Name -eq 'choco' }

        Test-WinUtilPackageManager -winget -choco | Should -Be 'not-installed'
    }

    It 'returns nothing when neither switch is passed' {
        Test-WinUtilPackageManager | Should -BeNullOrEmpty
    }
}
