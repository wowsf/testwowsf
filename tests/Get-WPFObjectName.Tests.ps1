BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'WinUtilTestHelpers.psm1') -Force
    . ([scriptblock]::Create((Get-WinUtilFunctionSource -Name Get-WPFObjectName)))
}

Describe 'Get-WPFObjectName' {
    It 'prefixes the type and name with WPF' {
        Get-WPFObjectName -type 'Label' -name 'MicrosoftTools' | Should -Be 'WPFLabelMicrosoftTools'
    }

    It 'strips characters that are invalid in a PowerShell variable name' {
        Get-WPFObjectName -type 'Label' -name 'Microsoft Tools (Legacy) - 2!' | Should -Be 'WPFLabelMicrosoftToolsLegacy2'
    }

    It 'accepts the type and name positionally' {
        Get-WPFObjectName 'CheckBox' 'Browsers' | Should -Be 'WPFCheckBoxBrowsers'
    }

    It 'returns only the prefixed type when no name is given' {
        Get-WPFObjectName -type 'Button' | Should -Be 'WPFButton'
    }

    It 'sanitizes the type as well as the name' {
        Get-WPFObjectName -type 'Toggle Switch' -name 'Dark_Mode' | Should -Be 'WPFToggleSwitchDarkMode'
    }

    It 'returns identical names for inputs that differ only in invalid characters' {
        Get-WPFObjectName -type 'Label' -name 'Web Browsers' |
            Should -Be (Get-WPFObjectName -type 'Label' -name 'Web-Browsers')
    }

    It 'requires the type parameter' {
        { Get-WPFObjectName -name 'NoType' -ErrorAction Stop } | Should -Throw
    }
}
