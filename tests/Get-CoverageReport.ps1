<#
.SYNOPSIS
    Reports which winutil.ps1 functions are covered by unit tests.

.DESCRIPTION
    Pester's line based coverage cannot be used here, because the tests extract functions from
    winutil.ps1 through the AST instead of dot-sourcing the file (dot-sourcing would relaunch
    the script as Administrator and open the GUI). This script reports coverage per function
    instead: a function counts as covered when a *.Tests.ps1 file in this directory loads it
    through Get-WinUtilFunctionSource. Command counts are included so the largest untested
    functions can be prioritised.

.PARAMETER Uncovered
    Only list the functions that have no unit tests, largest first.

.EXAMPLE
    pwsh -File tests/Get-CoverageReport.ps1 -Uncovered
#>
param(
    [switch]$Uncovered
)

$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'WinUtilTestHelpers.psm1') -Force

$testedFunctions = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($testFile in Get-ChildItem -Path $PSScriptRoot -Filter '*.Tests.ps1') {
    $content = Get-Content -LiteralPath $testFile.FullName -Raw
    foreach ($match in [regex]::Matches($content, 'Get-WinUtilFunctionSource\s+-Name\s+([^\)]+)\)')) {
        foreach ($name in $match.Groups[1].Value -split ',') {
            $null = $testedFunctions.Add($name.Trim().Trim("'", '"'))
        }
    }
}

$report = foreach ($entry in (Get-WinUtilFunctionAst).GetEnumerator()) {
    $ast = $entry.Value
    [PSCustomObject]@{
        Function = $entry.Key
        Commands = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandBaseAst] }, $true).Count
        Lines    = $ast.Extent.EndLineNumber - $ast.Extent.StartLineNumber + 1
        Tested   = $testedFunctions.Contains($entry.Key)
    }
}

$total = $report.Count
$covered = @($report | Where-Object Tested).Count
$totalCommands = ($report | Measure-Object -Property Commands -Sum).Sum
$coveredCommands = ($report | Where-Object Tested | Measure-Object -Property Commands -Sum).Sum

if ($Uncovered) {
    $report | Where-Object { -not $_.Tested } | Sort-Object Commands -Descending | Format-Table -AutoSize
} else {
    $report | Sort-Object Tested, Commands -Descending | Format-Table -AutoSize
}

'Functions covered : {0}/{1} ({2:P1})' -f $covered, $total, ($covered / $total)
'Commands covered  : {0}/{1} ({2:P1})' -f $coveredCommands, $totalCommands, ($coveredCommands / $totalCommands)
