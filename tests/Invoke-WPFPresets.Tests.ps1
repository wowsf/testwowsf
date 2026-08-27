BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'WinUtilTestHelpers.psm1') -Force
    . ([scriptblock]::Create((Get-WinUtilFunctionSource -Name Invoke-WPFPresets, Update-WinUtilSelections)))

    # Reset-WPFCheckBoxes only touches WPF controls, so it is stubbed out and mocked.
    function Reset-WPFCheckBoxes { param([bool]$doToggles, [string]$checkboxfilterpattern) }
}

Describe 'Invoke-WPFPresets' {
    BeforeEach {
        Mock Reset-WPFCheckBoxes {}
        Mock Write-Host {}

        $sync = New-WinUtilSync
        $sync.configs.preset = [PSCustomObject]@{
            Standard = @('WPFTweaksHiber', 'WPFTweaksHome')
            Minimal  = @('WPFTweaksHome')
        }
    }

    It 'selects the tweaks of a named preset' {
        Invoke-WPFPresets -preset 'Standard' -imported $false -checkboxfilterpattern 'WPFTweak*'

        $sync.selectedTweaks | Should -Be @('WPFTweaksHiber', 'WPFTweaksHome')
    }

    It 'selects an imported list instead of a named preset' {
        Invoke-WPFPresets -preset @('WPFInstallchrome') -imported $true -checkboxfilterpattern 'WPFInstall*'

        $sync.selectedApps | Should -Be @('WPFInstallchrome')
    }

    It 'replaces the previous tweak selection rather than merging with it' {
        $sync.selectedTweaks.Add('WPFTweaksRestorePoint')

        Invoke-WPFPresets -preset 'Minimal' -imported $false -checkboxfilterpattern 'WPFTweak*'

        $sync.selectedTweaks | Should -Be @('WPFTweaksHome')
    }

    It 'only clears the selection list matching the filter pattern' {
        $sync.selectedApps.Add('WPFInstallchrome')
        $sync.selectedTweaks.Add('WPFTweaksRestorePoint')

        Invoke-WPFPresets -preset 'Minimal' -imported $false -checkboxfilterpattern 'WPFTweak*'

        $sync.selectedApps | Should -Be @('WPFInstallchrome')
    }

    It 'clears the selection even when the preset is empty' {
        $sync.selectedTweaks.Add('WPFTweaksRestorePoint')

        Invoke-WPFPresets -preset $null -imported $false -checkboxfilterpattern 'WPFTweak*'

        $sync.selectedTweaks | Should -BeNullOrEmpty
    }

    It 'refreshes the checkboxes with the given filter and without touching toggles' {
        Invoke-WPFPresets -preset 'Standard' -imported $false -checkboxfilterpattern 'WPFTweak*'

        Should -Invoke Reset-WPFCheckBoxes -Times 1 -Exactly -ParameterFilter {
            $doToggles -eq $false -and $checkboxfilterpattern -eq 'WPFTweak*'
        }
    }

    It 'defaults to the catch-all checkbox filter' {
        Invoke-WPFPresets

        Should -Invoke Reset-WPFCheckBoxes -Times 1 -Exactly -ParameterFilter { $checkboxfilterpattern -eq '**' }
    }

    It 'accepts the parameters positionally' {
        Invoke-WPFPresets @('WPFTweaksHome') $true 'WPFTweak*'

        $sync.selectedTweaks | Should -Be @('WPFTweaksHome')
    }
}
