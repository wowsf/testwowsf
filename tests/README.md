# winutil.ps1 unit tests

Pester 5 unit tests for the functions inside `winutil.ps1`.

## Running

```powershell
Install-Module Pester -RequiredVersion 5.7.1 -Force -Scope CurrentUser -SkipPublisherCheck

./tests/Invoke-Tests.ps1              # run all tests
./tests/Invoke-Tests.ps1 -CI          # also write tests/testResults.xml (JUnit) and exit non-zero on failure
./tests/Get-CoverageReport.ps1        # per-function coverage report
./tests/Get-CoverageReport.ps1 -Uncovered   # untested functions, largest first
```

The tests run on Windows and on Linux/macOS PowerShell 7, because no function under test
requires WPF or the Windows registry.

## How functions are loaded

`winutil.ps1` is a single compiled script: dot-sourcing it relaunches itself as Administrator,
loads WPF assemblies, starts a transcript and shows the GUI. `WinUtilTestHelpers.psm1` therefore
parses the script and extracts only the requested function definitions:

```powershell
. ([scriptblock]::Create((Get-WinUtilFunctionSource -Name Get-WPFObjectName)))
```

Helpers available:

- `Get-WinUtilFunctionSource -Name <names>` – source text of the named functions.
- `Get-WinUtilFunctionAst` – all function definition ASTs, keyed by name.
- `New-WinUtilSync [hashtable]` – a `$sync` state hashtable like the one the script builds at
  startup, optionally seeded with fake UI elements.
- `Add-WinUtilPackageManagersEnum` – defines the `PackageManagers` enum the script adds via `Add-Type`.

Because functions are loaded from extracted source rather than from the file itself, Pester
cannot attach coverage breakpoints to `winutil.ps1`; `Get-CoverageReport.ps1` reports coverage per
function instead.

## Coverage status

Before these tests the repository had no tests at all, so all 100 functions in `winutil.ps1`
were uncovered. Covered now:

| Function | What is asserted |
| --- | --- |
| `Get-WPFObjectName` | prefixing and stripping of characters invalid in variable names |
| `Get-WinUtilVariables` | `WPF*` key filtering and filtering by control type |
| `Update-WinUtilSelections` | prefix routing, sorting, de-duplication, JSON imports, unknown keys |
| `Invoke-WPFPresets` | named vs. imported presets, per-pattern clearing, checkbox refresh |
| `Invoke-WPFPopup` | show/hide/toggle, parameter-set validation, missing popups |
| `Get-WinUtilSelectedPackages` | manager preference, fallback when an id is `na`, taskbar state |
| `Test-WinUtilPackageManager` | winget/choco detection results |
| `Invoke-WinUtilScript` | scriptblock invocation and the exception branches |
| `Set-WinUtilProgressbar` | label/value updates, the 5% floor, `-Noui` short circuit |

The remaining functions are dominated by WPF UI construction, DISM/ISO handling, the registry and
service control (`Invoke-WPFUIElements`, `Invoke-WinUtilISO*`, `Invoke-WPFFixesUpdate`, ...). They
need either a WPF host or an elevated Windows session, so they are out of scope for unit tests and
would be better served by integration tests on a Windows runner.
