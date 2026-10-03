# Helpers for unit testing winutil.ps1.
#
# winutil.ps1 is a single compiled script: dot-sourcing it would relaunch itself as
# Administrator, load WPF assemblies, start a transcript and show the GUI. Instead the
# script is parsed and only the requested function definitions are extracted, so a test
# can load exactly the functions under test and mock everything around them.

Set-StrictMode -Version Latest

$script:functionAstCache = $null

function Get-WinUtilScriptPath {
    <#
        .SYNOPSIS
            Returns the full path of winutil.ps1 in the repository root.
    #>
    [OutputType([string])]
    param()

    $path = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath 'winutil.ps1'
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Could not find winutil.ps1 at '$path'."
    }
    return $path
}

function Get-WinUtilFunctionAst {
    <#
        .SYNOPSIS
            Returns the function definition ASTs of winutil.ps1, keyed by function name.
    #>
    [OutputType([hashtable])]
    param()

    if ($null -eq $script:functionAstCache) {
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile((Get-WinUtilScriptPath), [ref]$tokens, [ref]$errors)
        if ($errors.Count -gt 0) {
            throw "winutil.ps1 could not be parsed: $($errors[0].Message)"
        }

        $script:functionAstCache = @{}
        foreach ($function in $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)) {
            # Nested helpers may repeat names (e.g. Log); the outermost definition wins.
            if (-not $script:functionAstCache.ContainsKey($function.Name)) {
                $script:functionAstCache[$function.Name] = $function
            }
        }
    }

    return $script:functionAstCache
}

function Get-WinUtilFunctionSource {
    <#
        .SYNOPSIS
            Returns the source text of the named winutil.ps1 functions.

        .PARAMETER Name
            One or more function names to extract.

        .EXAMPLE
            . ([scriptblock]::Create((Get-WinUtilFunctionSource -Name Get-WPFObjectName)))
    #>
    [OutputType([string])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string[]]$Name
    )

    $functions = Get-WinUtilFunctionAst
    $sources = foreach ($functionName in $Name) {
        if (-not $functions.ContainsKey($functionName)) {
            throw "winutil.ps1 does not define a function named '$functionName'."
        }
        $functions[$functionName].Extent.Text
    }

    return ($sources -join [Environment]::NewLine)
}

function New-WinUtilSync {
    <#
        .SYNOPSIS
            Creates a synchronized hashtable shaped like the $sync state winutil.ps1 builds at startup.

        .PARAMETER Entries
            Additional entries to merge into the hashtable, e.g. fake UI elements.
    #>
    [OutputType([hashtable])]
    param(
        [Parameter(Position = 0)]
        [hashtable]$Entries = @{}
    )

    $sync = [hashtable]::Synchronized(@{})
    $sync.configs = @{}
    $sync.preferences = @{}
    $sync.ProcessRunning = $false
    $sync.currentTab = 'Install'
    $sync.selectedApps = [System.Collections.Generic.List[string]]::new()
    $sync.selectedTweaks = [System.Collections.Generic.List[string]]::new()
    $sync.selectedToggles = [System.Collections.Generic.List[string]]::new()
    $sync.selectedFeatures = [System.Collections.Generic.List[string]]::new()

    foreach ($entry in $Entries.GetEnumerator()) {
        $sync[$entry.Key] = $entry.Value
    }

    return $sync
}

function Add-WinUtilPackageManagersEnum {
    <#
        .SYNOPSIS
            Defines the PackageManagers enum that winutil.ps1 creates via Add-Type at startup.
    #>
    [OutputType([void])]
    param()

    if (-not ('PackageManagers' -as [type])) {
        Add-Type -TypeDefinition @'
public enum PackageManagers
{
    Winget,
    Choco
}
'@
    }
}

Export-ModuleMember -Function Get-WinUtilScriptPath, Get-WinUtilFunctionAst, Get-WinUtilFunctionSource, New-WinUtilSync, Add-WinUtilPackageManagersEnum
