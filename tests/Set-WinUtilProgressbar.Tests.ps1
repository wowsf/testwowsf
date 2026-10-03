BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'WinUtilTestHelpers.psm1') -Force
    . ([scriptblock]::Create((Get-WinUtilFunctionSource -Name Set-WinUtilProgressbar)))

    # Stub of the UI marshalling helper; the tests run its scriptblocks directly.
    function Invoke-WPFUIThread { param([scriptblock]$ScriptBlock) }
}

Describe 'Set-WinUtilProgressbar' {
    BeforeEach {
        $PARAM_NOUI = $false
        $sync = New-WinUtilSync @{
            progressBarTextBlock = [PSCustomObject]@{ Text = ''; ToolTip = '' }
            ProgressBar          = [PSCustomObject]@{ Value = 0 }
        }
        # Execute the scriptblocks the function hands to the UI thread against the fake elements.
        Mock Invoke-WPFUIThread { & $ScriptBlock }
    }

    It 'writes the label to the progress bar text and tooltip' {
        Set-WinUtilProgressbar -Label 'Installing Chrome' -Percent 40

        $sync.progressBarTextBlock.Text | Should -Be 'Installing Chrome'
        $sync.progressBarTextBlock.ToolTip | Should -Be 'Installing Chrome'
    }

    It 'sets the progress bar value' {
        Set-WinUtilProgressbar -Label 'Working' -Percent 40

        $sync.ProgressBar.Value | Should -Be 40
    }

    It 'raises values below 5 so the bar is never rendered empty' {
        Set-WinUtilProgressbar -Label 'Starting' -Percent 1

        $sync.ProgressBar.Value | Should -Be 5
    }

    It 'accepts the full range' {
        Set-WinUtilProgressbar -Label 'Done' -Percent 100

        $sync.ProgressBar.Value | Should -Be 100
    }

    It 'rejects percentages outside 0-100' {
        { Set-WinUtilProgressbar -Label 'Too much' -Percent 101 } | Should -Throw
        { Set-WinUtilProgressbar -Label 'Too little' -Percent -1 } | Should -Throw
    }

    It 'does nothing when running without a UI' {
        $PARAM_NOUI = $true

        Set-WinUtilProgressbar -Label 'Headless' -Percent 50

        Should -Invoke Invoke-WPFUIThread -Times 0 -Exactly
        $sync.ProgressBar.Value | Should -Be 0
        $sync.progressBarTextBlock.Text | Should -BeNullOrEmpty
    }
}
