<#
.SYNOPSIS
    Runs the winutil.ps1 unit tests with Pester.

.DESCRIPTION
    Runs every *.Tests.ps1 file in this directory. Pester's line based code coverage is not
    used: the tests load functions out of winutil.ps1 through the AST (see WinUtilTestHelpers.psm1)
    rather than dot-sourcing the file, so no breakpoints can be attached to it. Run
    Get-CoverageReport.ps1 for a function level coverage report instead.

.PARAMETER CI
    Emit a JUnit test result file (tests/testResults.xml) and fail the process on test failures.

.EXAMPLE
    pwsh -File tests/Invoke-Tests.ps1 -CI
#>
param(
    [switch]$CI
)

$ErrorActionPreference = 'Stop'

Import-Module Pester -MinimumVersion 5.5.0

$configuration = New-PesterConfiguration
$configuration.Run.Path = $PSScriptRoot
$configuration.Output.Verbosity = 'Detailed'

if ($CI) {
    $configuration.TestResult.Enabled = $true
    $configuration.TestResult.OutputFormat = 'JUnitXml'
    $configuration.TestResult.OutputPath = Join-Path $PSScriptRoot 'testResults.xml'
    $configuration.Run.Exit = $true
}

Invoke-Pester -Configuration $configuration
