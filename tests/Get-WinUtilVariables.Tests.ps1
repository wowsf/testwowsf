BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'WinUtilTestHelpers.psm1') -Force
    . ([scriptblock]::Create((Get-WinUtilFunctionSource -Name Get-WinUtilVariables)))
}

Describe 'Get-WinUtilVariables' {
    BeforeEach {
        $sync = New-WinUtilSync @{
            WPFInstallchrome  = 'a string'
            WPFInstallbrave   = 42
            WPFTweaksHiber    = [PSCustomObject]@{ Name = 'toggle' }
            NotAWPFKey        = 'ignored'
            WPFNullValue      = $null
        }
    }

    It 'returns every key starting with WPF' {
        $keys = Get-WinUtilVariables
        $keys | Should -Contain 'WPFInstallchrome'
        $keys | Should -Contain 'WPFInstallbrave'
        $keys | Should -Contain 'WPFTweaksHiber'
        $keys | Should -Contain 'WPFNullValue'
    }

    It 'excludes keys that do not start with WPF' {
        Get-WinUtilVariables | Should -Not -Contain 'NotAWPFKey'
    }

    It 'filters by the type name of the stored object' {
        Get-WinUtilVariables -Type 'String' | Should -Be @('WPFInstallchrome')
    }

    It 'accepts multiple types' {
        $keys = Get-WinUtilVariables -Type 'String', 'Int32'
        $keys | Should -HaveCount 2
        $keys | Should -Contain 'WPFInstallchrome'
        $keys | Should -Contain 'WPFInstallbrave'
    }

    It 'skips values whose type cannot be resolved instead of failing' {
        { Get-WinUtilVariables -Type 'String' } | Should -Not -Throw
        Get-WinUtilVariables -Type 'String' | Should -Not -Contain 'WPFNullValue'
    }

    It 'returns nothing when no value matches the requested type' {
        Get-WinUtilVariables -Type 'CheckBox' | Should -BeNullOrEmpty
    }

    It 'returns an empty result for an empty sync state' {
        $sync = New-WinUtilSync
        Get-WinUtilVariables | Should -BeNullOrEmpty
    }
}
