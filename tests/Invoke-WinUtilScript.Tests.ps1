BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'WinUtilTestHelpers.psm1') -Force
    . ([scriptblock]::Create((Get-WinUtilFunctionSource -Name Invoke-WinUtilScript)))
}

Describe 'Invoke-WinUtilScript' {
    BeforeEach {
        Mock Write-Host {}
        Mock Write-Warning {}
    }

    It 'runs the given scriptblock' {
        $script:invoked = $false

        Invoke-WinUtilScript -Name 'Hello World' -scriptblock { $script:invoked = $true }

        $script:invoked | Should -BeTrue
    }

    It 'announces the script it is running' {
        Invoke-WinUtilScript -Name 'Hello World' -scriptblock { }

        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -eq 'Running Script for Hello World' }
    }

    It 'passes the scriptblock output through' {
        Invoke-WinUtilScript -Name 'Output' -scriptblock { 'result' } | Should -Be 'result'
    }

    It 'warns instead of throwing when the command does not exist' {
        { Invoke-WinUtilScript -Name 'Missing' -scriptblock { ThisCommandDoesNotExist } } | Should -Not -Throw

        Should -Invoke Write-Warning -ParameterFilter { $Message -eq 'The specified command was not found.' }
    }

    It 'warns instead of throwing on a runtime exception' {
        { Invoke-WinUtilScript -Name 'Runtime' -scriptblock { 1 / 0 } } | Should -Not -Throw

        Should -Invoke Write-Warning -ParameterFilter { $Message -eq 'A runtime exception occurred.' }
    }

    It 'warns instead of throwing on an unauthorized access exception' {
        { Invoke-WinUtilScript -Name 'Denied' -scriptblock { throw [UnauthorizedAccessException]::new('nope') } } | Should -Not -Throw

        Should -Invoke Write-Warning -ParameterFilter {
            $Message -eq 'Access denied. You do not have permission to perform this operation.'
        }
    }

    It 'rejects a non-scriptblock argument' {
        { Invoke-WinUtilScript -Name 'NotAScript' -scriptblock 42 } | Should -Throw
    }
}
