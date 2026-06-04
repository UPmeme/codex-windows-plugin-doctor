Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$script = Join-Path $root "scripts\codex-windows-plugin-doctor.ps1"

if (-not (Test-Path $script)) {
    throw "Diagnostic script not found: $script"
}

Write-Output "Running text output smoke test..."
$text = & $script
if ($text -notmatch "Codex Windows Plugin Doctor") {
    throw "Text output did not include expected title."
}

Write-Output "Running JSON output smoke test..."
$jsonText = & $script -Json
$json = $jsonText | ConvertFrom-Json
if ($json.tool -ne "codex-windows-plugin-doctor") {
    throw "JSON output did not include expected tool id."
}
if (-not $json.checks) {
    throw "JSON output did not include checks."
}

Write-Output "Running output file smoke test..."
$outDir = Join-Path $root ".tmp"
$outFile = Join-Path $outDir "smoke-report.txt"
& $script -OutFile $outFile | Out-Null
if (-not (Test-Path $outFile)) {
    throw "OutFile was not created."
}

Write-Output "Smoke tests passed."
