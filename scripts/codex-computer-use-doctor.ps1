param(
    [switch]$Json,
    [string]$OutFile,
    [switch]$Repair,
    [switch]$Apply,
    [string]$PluginSourcePath
)

$script = Join-Path $PSScriptRoot "codex-windows-plugin-doctor.ps1"

& $script @PSBoundParameters
