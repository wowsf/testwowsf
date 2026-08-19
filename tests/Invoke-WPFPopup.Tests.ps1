BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'WinUtilTestHelpers.psm1') -Force
    . ([scriptblock]::Create((Get-WinUtilFunctionSource -Name Invoke-WPFPopup)))
}

Describe 'Invoke-WPFPopup' {
    BeforeEach {
        # winutil.ps1 stores WPF Popup controls in $sync under "<name>Popup"; only IsOpen is used here.
        $sync = New-WinUtilSync @{
            selectedAppsPopup = [PSCustomObject]@{ IsOpen = $false }
            settingsPopup     = [PSCustomObject]@{ IsOpen = $true }
        }
    }

    It 'opens a popup' {
        Invoke-WPFPopup -Action 'Show' -Popups @('selectedApps')

        $sync.selectedAppsPopup.IsOpen | Should -BeTrue
    }

    It 'closes a popup' {
        Invoke-WPFPopup -Action 'Hide' -Popups @('settings')

        $sync.settingsPopup.IsOpen | Should -BeFalse
    }

    It 'toggles each popup independently' {
        Invoke-WPFPopup -Action 'Toggle' -Popups @('selectedApps', 'settings')

        $sync.selectedAppsPopup.IsOpen | Should -BeTrue
        $sync.settingsPopup.IsOpen | Should -BeFalse
    }

    It 'applies a different action per popup via PopupActionTable' {
        Invoke-WPFPopup -PopupActionTable @{ selectedApps = 'Show'; settings = 'Hide' }

        $sync.selectedAppsPopup.IsOpen | Should -BeTrue
        $sync.settingsPopup.IsOpen | Should -BeFalse
    }

    It 'rejects an invalid action in PopupActionTable' {
        { Invoke-WPFPopup -PopupActionTable @{ selectedApps = 'Open' } } | Should -Throw
    }

    It 'rejects an invalid Action value' {
        { Invoke-WPFPopup -Action 'Open' -Popups @('selectedApps') } | Should -Throw
    }

    It 'requires either PopupActionTable or both Action and Popups' {
        { Invoke-WPFPopup } | Should -Throw "Provide either 'PopupActionTable' or both 'Action' and 'Popups'."
        { Invoke-WPFPopup -Action 'Show' } | Should -Throw "Provide either 'PopupActionTable' or both 'Action' and 'Popups'."
        { Invoke-WPFPopup -Popups @('selectedApps') } | Should -Throw "Provide either 'PopupActionTable' or both 'Action' and 'Popups'."
    }

    It 'refuses to combine PopupActionTable with Action or Popups' {
        { Invoke-WPFPopup -Action 'Show' -PopupActionTable @{ settings = 'Hide' } } |
            Should -Throw "Use 'PopupActionTable' on its own, or 'Action' with 'Popups'."
        { Invoke-WPFPopup -Popups @('selectedApps') -PopupActionTable @{ settings = 'Hide' } } |
            Should -Throw "Use 'PopupActionTable' on its own, or 'Action' with 'Popups'."
    }

    It 'throws listing the popups that do not exist' {
        { Invoke-WPFPopup -Action 'Show' -Popups @('doesNotExist') } |
            Should -Throw 'Could not find the following popups: doesNotExistPopup'
    }

    It 'still applies the action to the popups that exist before throwing' {
        { Invoke-WPFPopup -Action 'Show' -Popups @('selectedApps', 'doesNotExist') } | Should -Throw

        $sync.selectedAppsPopup.IsOpen | Should -BeTrue
    }
}
