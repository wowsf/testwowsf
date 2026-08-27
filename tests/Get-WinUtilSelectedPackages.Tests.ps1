BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'WinUtilTestHelpers.psm1') -Force
    Add-WinUtilPackageManagersEnum
    . ([scriptblock]::Create((Get-WinUtilFunctionSource -Name Get-WinUtilSelectedPackages)))

    # Stub of the UI helper the function marshals taskbar updates through, so it can be mocked.
    function Invoke-WPFUIThread { param([scriptblock]$ScriptBlock) }

    function New-Package {
        param([string]$Content, [string]$Winget, [string]$Choco)
        [PSCustomObject]@{ content = $Content; winget = $Winget; choco = $Choco }
    }
}

Describe 'Get-WinUtilSelectedPackages' {
    BeforeEach {
        Mock Invoke-WPFUIThread {}
        Mock Write-Host {}

        $chrome = New-Package -Content 'Chrome' -Winget 'Google.Chrome' -Choco 'googlechrome'
        $wingetOnly = New-Package -Content 'WingetOnly' -Winget 'Some.Package' -Choco 'na'
        $chocoOnly = New-Package -Content 'ChocoOnly' -Winget 'na' -Choco 'some.package'
    }

    It 'prefers WinGet for packages available in both managers' {
        $packages = Get-WinUtilSelectedPackages -PackageList @($chrome) -Preference ([PackageManagers]::Winget)

        $packages[[PackageManagers]::Winget] | Should -Be @('Google.Chrome')
        $packages[[PackageManagers]::Choco] | Should -BeNullOrEmpty
    }

    It 'prefers Chocolatey for packages available in both managers' {
        $packages = Get-WinUtilSelectedPackages -PackageList @($chrome) -Preference ([PackageManagers]::Choco)

        $packages[[PackageManagers]::Choco] | Should -Be @('googlechrome')
        $packages[[PackageManagers]::Winget] | Should -BeNullOrEmpty
    }

    It 'falls back to Chocolatey when the package has no WinGet id' {
        $packages = Get-WinUtilSelectedPackages -PackageList @($chocoOnly) -Preference ([PackageManagers]::Winget)

        $packages[[PackageManagers]::Choco] | Should -Be @('some.package')
        $packages[[PackageManagers]::Winget] | Should -BeNullOrEmpty
    }

    It 'falls back to WinGet when the package has no Chocolatey id' {
        $packages = Get-WinUtilSelectedPackages -PackageList @($wingetOnly) -Preference ([PackageManagers]::Choco)

        $packages[[PackageManagers]::Winget] | Should -Be @('Some.Package')
        $packages[[PackageManagers]::Choco] | Should -BeNullOrEmpty
    }

    It 'splits a mixed package list across both managers' {
        $packages = Get-WinUtilSelectedPackages -PackageList @($chrome, $chocoOnly) -Preference ([PackageManagers]::Winget)

        $packages[[PackageManagers]::Winget] | Should -Be @('Google.Chrome')
        $packages[[PackageManagers]::Choco] | Should -Be @('some.package')
    }

    It 'always returns a bucket for each package manager' {
        $packages = Get-WinUtilSelectedPackages -PackageList @() -Preference ([PackageManagers]::Winget)

        $packages.Keys | Should -HaveCount 2
        $packages[[PackageManagers]::Winget].GetType() | Should -Be ([System.Collections.ArrayList])
        $packages[[PackageManagers]::Choco].GetType() | Should -Be ([System.Collections.ArrayList])
        $packages[[PackageManagers]::Winget].Count | Should -Be 0
        $packages[[PackageManagers]::Choco].Count | Should -Be 0
    }

    It 'shows an indeterminate taskbar state for a single package' {
        Get-WinUtilSelectedPackages -PackageList @($chrome) -Preference ([PackageManagers]::Winget) | Out-Null

        Should -Invoke Invoke-WPFUIThread -Times 1 -Exactly -ParameterFilter {
            $ScriptBlock.ToString() -match 'Indeterminate'
        }
    }

    It 'shows a normal taskbar state for multiple packages' {
        Get-WinUtilSelectedPackages -PackageList @($chrome, $wingetOnly) -Preference ([PackageManagers]::Winget) | Out-Null

        Should -Invoke Invoke-WPFUIThread -Times 1 -Exactly -ParameterFilter {
            $ScriptBlock.ToString() -match 'Normal'
        }
    }

    It 'requires a valid package manager preference' {
        { Get-WinUtilSelectedPackages -PackageList @($chrome) -Preference 'Scoop' } | Should -Throw
    }
}
