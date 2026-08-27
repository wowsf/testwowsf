BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'WinUtilTestHelpers.psm1') -Force
    . ([scriptblock]::Create((Get-WinUtilFunctionSource -Name Update-WinUtilSelections)))
}

Describe 'Update-WinUtilSelections' {
    BeforeEach {
        $sync = New-WinUtilSync
    }

    It 'routes each key into the list matching its prefix' {
        Update-WinUtilSelections -flatJson @('WPFInstallchrome', 'WPFTweaksHiber', 'WPFToggleDarkMode', 'WPFFeaturesdotnet3')

        $sync.selectedApps | Should -Be @('WPFInstallchrome')
        $sync.selectedTweaks | Should -Be @('WPFTweaksHiber')
        $sync.selectedToggles | Should -Be @('WPFToggleDarkMode')
        $sync.selectedFeatures | Should -Be @('WPFFeaturesdotnet3')
    }

    It 'keeps the app list sorted' {
        Update-WinUtilSelections -flatJson @('WPFInstallvscode', 'WPFInstallbrave', 'WPFInstallchrome')

        $sync.selectedApps | Should -Be @('WPFInstallbrave', 'WPFInstallchrome', 'WPFInstallvscode')
    }

    It 'keeps the app list typed when a single app is selected' {
        Update-WinUtilSelections -flatJson @('WPFInstallbrave')

        $sync.selectedApps | Should -BeOfType ([string])
        $sync.selectedApps.Count | Should -Be 1
    }

    It 'does not add duplicates on repeated calls' {
        Update-WinUtilSelections -flatJson @('WPFInstallchrome', 'WPFTweaksHiber')
        Update-WinUtilSelections -flatJson @('WPFInstallchrome', 'WPFTweaksHiber')

        $sync.selectedApps | Should -HaveCount 1
        $sync.selectedTweaks | Should -HaveCount 1
    }

    It 'merges new selections into existing ones' {
        $sync.selectedApps.Add('WPFInstallchrome')

        Update-WinUtilSelections -flatJson @('WPFInstallbrave')

        $sync.selectedApps | Should -Be @('WPFInstallbrave', 'WPFInstallchrome')
    }

    It 'warns about keys with an unknown prefix without selecting them' {
        Mock Write-Host {}

        Update-WinUtilSelections -flatJson @('SomethingElse')

        Should -Invoke Write-Host -Times 1 -Exactly
        $sync.selectedApps | Should -BeNullOrEmpty
        $sync.selectedTweaks | Should -BeNullOrEmpty
        $sync.selectedToggles | Should -BeNullOrEmpty
        $sync.selectedFeatures | Should -BeNullOrEmpty
    }

    It 'treats deserialized JSON values as strings' {
        $imported = ConvertFrom-Json '["WPFInstallchrome","WPFTweaksHiber"]'

        Update-WinUtilSelections -flatJson $imported

        $sync.selectedApps | Should -Be @('WPFInstallchrome')
        $sync.selectedTweaks | Should -Be @('WPFTweaksHiber')
    }

    It 'does nothing for an empty selection' {
        Update-WinUtilSelections -flatJson @()

        $sync.selectedApps | Should -BeNullOrEmpty
        $sync.selectedTweaks | Should -BeNullOrEmpty
    }
}
