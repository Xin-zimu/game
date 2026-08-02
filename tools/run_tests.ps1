[CmdletBinding()]
param(
    [string]$GodotBin = $env:GODOT_BIN,
    [string]$PythonBin = $env:PYTHON_BIN,
    [string]$RuntimeRoot = (Join-Path ([System.IO.Path]::GetTempPath()) 'infinite-frontier-godot-runtime')
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$LogRoot = Join-Path $RuntimeRoot 'logs'

function Resolve-Executable {
    param([string]$ExplicitPath, [string[]]$Candidates, [string]$Label)
    if ($ExplicitPath) {
        $resolved = Resolve-Path -LiteralPath $ExplicitPath -ErrorAction SilentlyContinue
        if ($resolved) { return $resolved.Path }
        throw "$Label executable does not exist: $ExplicitPath"
    }
    foreach ($candidate in $Candidates) {
        $command = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($command) { return $command.Source }
    }
    throw "$Label executable was not found. Pass -${Label}Bin with an absolute path."
}

function Invoke-GodotCheck {
    param([string]$Name, [string[]]$Arguments)
    $logPath = Join-Path $LogRoot "$Name.log"
    & $script:ResolvedGodot @Arguments 2>&1 | Tee-Object -FilePath $logPath
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "Godot check '$Name' exited with code $exitCode. See $logPath"
    }
    $logText = Get-Content -Raw -LiteralPath $logPath
    if ($logText -match '(?m)SCRIPT ERROR|^ERROR:|CrashHandlerException' -or
        $logText -match '=== [0-9]+ passed, [1-9][0-9]* failed ===' -or
        $logText -match 'ObjectDB instances were leaked') {
        throw "Godot check '$Name' reported an error, failed assertion, or object leak. See $logPath"
    }
}

$script:ResolvedGodot = Resolve-Executable $GodotBin @('godot4', 'godot') 'Godot'
$resolvedPython = Resolve-Executable $PythonBin @('python', 'python3') 'Python'
New-Item -ItemType Directory -Force -Path $LogRoot | Out-Null

$previousAppData = $env:APPDATA
$previousLocalAppData = $env:LOCALAPPDATA
$env:APPDATA = Join-Path $RuntimeRoot 'AppData\Roaming'
$env:LOCALAPPDATA = Join-Path $RuntimeRoot 'AppData\Local'
New-Item -ItemType Directory -Force -Path $env:APPDATA, $env:LOCALAPPDATA | Out-Null

try {
	& $resolvedPython (Join-Path $ProjectRoot 'tools\verify_project.py')
	if ($LASTEXITCODE -ne 0) { throw 'Structural verification failed.' }

	Invoke-GodotCheck 'import' @('--headless', '--path', $ProjectRoot, '--editor', '--quit')
	Invoke-GodotCheck 'tests' @('--headless', '--path', $ProjectRoot, 'res://tests/test_runner.tscn')
	Invoke-GodotCheck 'main-smoke' @('--headless', '--path', $ProjectRoot, '--quit-after', '3')
	Invoke-GodotCheck 'game-smoke' @('--headless', '--path', $ProjectRoot, '--scene', 'res://scenes/main/game.tscn', '--quit-after', '3')

	Write-Host 'Infinite Frontier Windows test gate passed.'
} finally {
	$env:APPDATA = $previousAppData
	$env:LOCALAPPDATA = $previousLocalAppData
}
