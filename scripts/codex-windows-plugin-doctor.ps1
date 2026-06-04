param(
    [switch]$Json,
    [string]$OutFile
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-TruthyLine {
    param(
        [string]$Text,
        [string]$Pattern
    )

    return [regex]::IsMatch($Text, $Pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Multiline)
}

function New-Check {
    param(
        [string]$Id,
        [string]$Title,
        [string]$Status,
        [string]$Detail,
        [string]$Suggestion = ""
    )

    [pscustomobject]@{
        id = $Id
        title = $Title
        status = $Status
        detail = $Detail
        suggestion = $Suggestion
    }
}

function Add-Check {
    param(
        [string]$Id,
        [string]$Title,
        [string]$Status,
        [string]$Detail,
        [string]$Suggestion = ""
    )

    $checks.Add((New-Check -Id $Id -Title $Title -Status $Status -Detail $Detail -Suggestion $Suggestion))
}

$codexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE ".codex" }
$configPath = Join-Path $codexHome "config.toml"
$pluginsRoot = Join-Path $codexHome "plugins"
$cacheRoot = Join-Path $pluginsRoot "cache"
$checks = New-Object System.Collections.Generic.List[object]

$codexHomeExists = Test-Path $codexHome
Add-Check `
    -Id "codex-home" `
    -Title "Codex home directory" `
    -Status $(if ($codexHomeExists) { "ok" } else { "warn" }) `
    -Detail $codexHome `
    -Suggestion $(if ($codexHomeExists) { "" } else { "Start Codex once, then rerun this diagnostic." })

if (Test-Path $configPath) {
    $configText = Get-Content -Path $configPath -Raw
    Add-Check -Id "config" -Title "Codex config.toml" -Status "ok" -Detail $configPath

    $expectedPlugins = @("browser", "chrome", "computer-use")
    foreach ($plugin in $expectedPlugins) {
        $pattern = "plugins\.`"$([regex]::Escape($plugin))@openai-bundled`""
        $found = Test-TruthyLine -Text $configText -Pattern $pattern
        Add-Check `
            -Id "config-plugin-$plugin" `
            -Title "Configured bundled plugin: $plugin" `
            -Status $(if ($found) { "ok" } else { "warn" }) `
            -Detail $(if ($found) { "Found in config.toml." } else { "Not found in config.toml." }) `
            -Suggestion $(if ($found) { "" } else { "Install or re-enable the $plugin plugin from Codex settings." })
    }

    $marketplaceFound = Test-TruthyLine -Text $configText -Pattern "marketplaces\.openai-bundled"
    Add-Check `
        -Id "bundled-marketplace" `
        -Title "OpenAI bundled marketplace" `
        -Status $(if ($marketplaceFound) { "ok" } else { "warn" }) `
        -Detail $(if ($marketplaceFound) { "Configured." } else { "Not found in config.toml." }) `
        -Suggestion $(if ($marketplaceFound) { "" } else { "Reinstall or re-enable bundled plugins from Codex settings." })
}
else {
    Add-Check `
        -Id "config" `
        -Title "Codex config.toml" `
        -Status "warn" `
        -Detail "Missing: $configPath" `
        -Suggestion "Start Codex and install the Browser, Chrome, and Computer Use plugins before rerunning."
}

if (Test-Path $cacheRoot) {
    Add-Check -Id "plugin-cache" -Title "Plugin cache directory" -Status "ok" -Detail $cacheRoot
    foreach ($plugin in @("browser", "chrome", "computer-use")) {
        $matches = Get-ChildItem -Path $cacheRoot -Recurse -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -eq $plugin -or $_.FullName -match "\\$plugin\\" } |
            Select-Object -First 3

        Add-Check `
            -Id "cache-plugin-$plugin" `
            -Title "Cached plugin files: $plugin" `
            -Status $(if ($matches) { "ok" } else { "warn" }) `
            -Detail $(if ($matches) { ($matches | ForEach-Object FullName) -join "; " } else { "No cached directory found." }) `
            -Suggestion $(if ($matches) { "" } else { "Reinstall the $plugin plugin in Codex settings." })
    }
}
else {
    Add-Check `
        -Id "plugin-cache" `
        -Title "Plugin cache directory" `
        -Status "warn" `
        -Detail "Missing: $cacheRoot" `
        -Suggestion "Install at least one Codex plugin, then rerun."
}

$nativeHostKeys = @(
    "HKCU:\Software\Google\Chrome\NativeMessagingHosts",
    "HKLM:\Software\Google\Chrome\NativeMessagingHosts",
    "HKCU:\Software\Chromium\NativeMessagingHosts",
    "HKLM:\Software\Chromium\NativeMessagingHosts"
)

$nativeHostHits = New-Object System.Collections.Generic.List[string]
foreach ($key in $nativeHostKeys) {
    if (Test-Path $key) {
        Get-ChildItem -Path $key -ErrorAction SilentlyContinue |
            Where-Object { $_.PSChildName -match "codex|openai" } |
            ForEach-Object { $nativeHostHits.Add($_.Name) }
    }
}

$hasNativeHosts = $nativeHostHits.Count -gt 0
Add-Check `
    -Id "chrome-native-host-registry" `
    -Title "Chrome native messaging host registry entries" `
    -Status $(if ($hasNativeHosts) { "ok" } else { "warn" }) `
    -Detail $(if ($hasNativeHosts) { $nativeHostHits -join "; " } else { "No Codex/OpenAI native host entries found in common Chrome registry locations." }) `
    -Suggestion $(if ($hasNativeHosts) { "" } else { "If the Chrome plugin says Connected but Codex cannot control Chrome, reinstall the Chrome plugin and extension." })

$chromeExtensionRoots = @(
    (Join-Path $env:LOCALAPPDATA "Google\Chrome\User Data\Default\Extensions"),
    (Join-Path $env:LOCALAPPDATA "Google\Chrome\User Data\Profile 1\Extensions"),
    (Join-Path $env:LOCALAPPDATA "Google\Chrome\User Data\Profile 2\Extensions")
)

$extensionHits = New-Object System.Collections.Generic.List[string]
foreach ($root in $chromeExtensionRoots) {
    if (Test-Path $root) {
        Get-ChildItem -Path $root -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -eq "hehggadaopoacecdllhhajmbjkdcmajg" } |
            ForEach-Object { $extensionHits.Add($_.FullName) }
    }
}

$hasExtension = $extensionHits.Count -gt 0
Add-Check `
    -Id "chrome-extension" `
    -Title "Codex Chrome extension" `
    -Status $(if ($hasExtension) { "ok" } else { "warn" }) `
    -Detail $(if ($hasExtension) { $extensionHits -join "; " } else { "Extension id hehggadaopoacecdllhhajmbjkdcmajg not found in common Chrome profiles." }) `
    -Suggestion $(if ($hasExtension) { "" } else { "Install the Codex Chrome extension from the Chrome Web Store and connect it from Codex settings." })

$summary = [pscustomobject]@{
    tool = "codex-windows-plugin-doctor"
    version = "0.1.0"
    generated_at = (Get-Date).ToString("s")
    platform = [System.Environment]::OSVersion.VersionString
    codex_home = $codexHome
    checks = $checks
}

if ($Json) {
    $output = $summary | ConvertTo-Json -Depth 6
}
else {
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("Codex Windows Plugin Doctor")
    $lines.Add("Generated: $($summary.generated_at)")
    $lines.Add("Platform: $($summary.platform)")
    $lines.Add("Codex home: $codexHome")
    $lines.Add("")
    foreach ($check in $checks) {
        $lines.Add("[$($check.status)] $($check.title)")
        $lines.Add("  $($check.detail)")
        if ($check.suggestion) {
            $lines.Add("  Suggestion: $($check.suggestion)")
        }
        $lines.Add("")
    }
    $output = $lines -join [Environment]::NewLine
}

if ($OutFile) {
    $directory = Split-Path -Parent $OutFile
    if ($directory -and -not (Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory | Out-Null
    }
    Set-Content -Path $OutFile -Value $output -Encoding UTF8
}

Write-Output $output
