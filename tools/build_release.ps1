[CmdletBinding()]
param(
    [string]$GodotBin = $env:GODOT_BIN,
    [string]$PythonBin = $env:PYTHON_BIN,
    [string]$BuildRoot,
    [switch]$SkipTests
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $PSScriptRoot
if (-not $BuildRoot) { $BuildRoot = Join-Path $ProjectRoot 'build' }
$WindowsRoot = Join-Path $BuildRoot 'windows'
$OutputExe = Join-Path $WindowsRoot 'InfiniteFrontier.exe'
$RuntimeRoot = Join-Path ([System.IO.Path]::GetTempPath()) 'infinite-frontier-release-runtime'

if (-not $GodotBin) {
    foreach ($candidate in @('godot4', 'godot')) {
        $command = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($command) { $GodotBin = $command.Source; break }
    }
}
$resolvedGodot = Resolve-Path -LiteralPath $GodotBin -ErrorAction SilentlyContinue
if (-not $resolvedGodot) { throw 'Godot executable was not found. Pass -GodotBin with an absolute path.' }
$GodotBin = $resolvedGodot.Path

if (-not $SkipTests) {
    $testArgs = @{ GodotBin = $GodotBin }
    if ($PythonBin) { $testArgs.PythonBin = $PythonBin }
    & (Join-Path $PSScriptRoot 'run_tests.ps1') @testArgs
    if ($LASTEXITCODE -ne 0) { throw 'Windows test gate failed before export.' }
}

New-Item -ItemType Directory -Force -Path $WindowsRoot, $RuntimeRoot | Out-Null
& $GodotBin --headless --path $ProjectRoot --export-release 'Windows Desktop' $OutputExe
if ($LASTEXITCODE -ne 0) { throw "Windows export failed with code $LASTEXITCODE." }
if (-not (Test-Path -LiteralPath $OutputExe -PathType Leaf)) { throw "Windows export was not created: $OutputExe" }

$bytes = [System.IO.File]::ReadAllBytes($OutputExe)
if ($bytes.Length -lt 512 -or $bytes[0] -ne 0x4D -or $bytes[1] -ne 0x5A) { throw 'Windows export is not a valid MZ executable.' }
$peOffset = [BitConverter]::ToInt32($bytes, 0x3C)
if ($peOffset -lt 0 -or $peOffset + 6 -ge $bytes.Length) { throw 'Windows export has an invalid PE header offset.' }
$signature = [Text.Encoding]::ASCII.GetString($bytes, $peOffset, 4)
$machine = [BitConverter]::ToUInt16($bytes, $peOffset + 4)
if ($signature -ne "PE`0`0" -or $machine -ne 0x8664) { throw 'Windows export is not a PE32+ x64 executable.' }

$versionSource = Get-Content -Raw -LiteralPath (Join-Path $ProjectRoot 'scripts\core\game_version.gd')
if ($versionSource -notmatch 'const VERSION := "([^"]+)"') { throw 'Could not read the game version.' }
$expectedVersion = $Matches[1]
$consoleExe = Join-Path $WindowsRoot 'InfiniteFrontier.console.exe'
$smokeExe = if (Test-Path -LiteralPath $consoleExe) { $consoleExe } else { $OutputExe }
$smokeLog = Join-Path $RuntimeRoot 'windows-smoke.log'
& $smokeExe --headless --audio-driver Dummy --quit-after 3 2>&1 | Tee-Object -FilePath $smokeLog
if ($LASTEXITCODE -ne 0) { throw 'Exported Windows build failed its smoke test.' }
$smokeText = Get-Content -Raw -LiteralPath $smokeLog
if ($smokeText -match '(?m)SCRIPT ERROR|^ERROR:|CrashHandlerException|ObjectDB instances were leaked' -or $smokeText -notmatch "version $([regex]::Escape($expectedVersion))") {
    throw 'Exported Windows build logged an error or the wrong version.'
}

$hash = Get-FileHash -Algorithm SHA256 -LiteralPath $OutputExe
Write-Host "Windows release build passed for v$expectedVersion."
Write-Host "SHA256 $($hash.Hash)  $OutputExe"
