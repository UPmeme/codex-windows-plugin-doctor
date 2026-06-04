param(
    [switch]$Json,
    [string]$OutFile,
    [switch]$Repair,
    [switch]$Apply,
    [string]$PluginSourcePath
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

function Add-RepairAction {
    param(
        [string]$Id,
        [string]$Title,
        [string]$Reason,
        [string]$Command,
        [string]$Risk = "low"
    )

    $repairActions.Add([pscustomobject]@{
        id = $Id
        title = $Title
        reason = $Reason
        command = $Command
        risk = $Risk
        applied = $false
        result = ""
    })
}

function Get-CodexBundledSourceCandidate {
    $candidates = New-Object System.Collections.Generic.List[string]

    if ($PluginSourcePath) {
        $candidates.Add($PluginSourcePath)
    }

    try {
        Get-Process -Name "Codex" -ErrorAction SilentlyContinue |
            Where-Object { $_.Path } |
            ForEach-Object {
                $processPath = $_.Path
                $root = Split-Path -Parent $processPath
                $candidate = Join-Path $root "resources\plugins\openai-bundled"
                $candidates.Add($candidate)
            }
    }
    catch {
    }

    $windowsApps = Join-Path $env:ProgramFiles "WindowsApps"
    if (Test-Path $windowsApps) {
        Get-ChildItem -Path $windowsApps -Directory -Filter "OpenAI.Codex_*" -ErrorAction SilentlyContinue |
            ForEach-Object {
                $candidate = Join-Path $_.FullName "app\resources\plugins\openai-bundled"
                $candidates.Add($candidate)
            }
    }

    return $candidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
}

function Invoke-External {
    param([string]$FilePath, [string[]]$Arguments)

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $FilePath
    foreach ($arg in $Arguments) {
        [void]$psi.ArgumentList.Add($arg)
    }
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $process = [System.Diagnostics.Process]::Start($psi)
    $process.WaitForExit()
    return [pscustomobject]@{
        exit_code = $process.ExitCode
        stdout = $process.StandardOutput.ReadToEnd()
        stderr = $process.StandardError.ReadToEnd()
    }
}

function Copy-DirectoryBytes {
    param(
        [string]$Source,
        [string]$Destination
    )

    if (-not (Test-Path $Source)) {
        throw "Source directory does not exist: $Source"
    }

    New-Item -ItemType Directory -Force $Destination | Out-Null

    Get-ChildItem -Path $Source -Recurse -Directory -ErrorAction Stop | ForEach-Object {
        $relative = $_.FullName.Substring($Source.Length).TrimStart("\", "/")
        $target = Join-Path $Destination $relative
        New-Item -ItemType Directory -Force $target | Out-Null
    }

    Get-ChildItem -Path $Source -Recurse -File -ErrorAction Stop | ForEach-Object {
        $relative = $_.FullName.Substring($Source.Length).TrimStart("\", "/")
        $target = Join-Path $Destination $relative
        $targetDirectory = Split-Path -Parent $target
        if ($targetDirectory -and -not (Test-Path $targetDirectory)) {
            New-Item -ItemType Directory -Force $targetDirectory | Out-Null
        }
        [System.IO.File]::WriteAllBytes($target, [System.IO.File]::ReadAllBytes($_.FullName))
    }
}

$codexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE ".codex" }
$configPath = Join-Path $codexHome "config.toml"
$pluginsRoot = Join-Path $codexHome "plugins"
$cacheRoot = Join-Path $pluginsRoot "cache"
$checks = New-Object System.Collections.Generic.List[object]
$repairActions = New-Object System.Collections.Generic.List[object]

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

        $skillMatches = Get-ChildItem -Path $cacheRoot -Recurse -File -Filter "SKILL.md" -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -match "\\$plugin\\" } |
            Select-Object -First 3

        Add-Check `
            -Id "skill-plugin-$plugin" `
            -Title "Discoverable skill files: $plugin" `
            -Status $(if ($skillMatches) { "ok" } else { "warn" }) `
            -Detail $(if ($skillMatches) { ($skillMatches | ForEach-Object FullName) -join "; " } else { "No SKILL.md found for $plugin in plugin cache." }) `
            -Suggestion $(if ($skillMatches) { "" } else { "The plugin cache may be incomplete. Reinstall or refresh the $plugin plugin." })
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

$warnCount = @($checks | Where-Object { $_.status -eq "warn" }).Count
$computerUseLocalOk = @($checks | Where-Object {
    $_.id -in @("config-plugin-computer-use", "cache-plugin-computer-use", "skill-plugin-computer-use") -and $_.status -eq "ok"
}).Count -eq 3

$repairPlan = New-Object System.Collections.Generic.List[string]
if ($warnCount -eq 0) {
    $repairPlan.Add("Local plugin signals look healthy. If Computer Use is still unavailable in the active thread, restart Codex Desktop and create a fresh thread before changing files.")
}
else {
    $repairPlan.Add("Fix warn items from top to bottom before deleting caches or restoring backups.")
}

if ($computerUseLocalOk) {
    $repairPlan.Add("Computer Use config, cache, and skill files are present locally. If @computer is unavailable, the likely issue is active-thread tool exposure, plugin runtime attachment, workspace policy, or product rollout state.")
}
else {
    $repairPlan.Add("Computer Use local state is incomplete. Re-enable or reinstall the Computer Use plugin in Codex settings, then rerun this diagnostic.")
}

if (-not $hasExtension) {
    $repairPlan.Add("Chrome extension was not found in common profiles. Install the Codex Chrome extension if Chrome control is part of the failure.")
}

if (-not $hasNativeHosts) {
    $repairPlan.Add("Chrome native messaging host was not found. Reconnect the Chrome plugin from Codex settings after installing the extension.")
}

if ($Repair) {
    $backupDir = Join-Path $codexHome ("backups\plugin-doctor-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
    Add-RepairAction `
        -Id "backup-codex-state" `
        -Title "Back up Codex configuration" `
        -Reason "Repair should preserve config.toml and global state before changing plugin marketplace or plugin installation." `
        -Command "New-Item -ItemType Directory -Force `"$backupDir`"; Copy-Item `"$configPath`" `"$backupDir`" -Force; Copy-Item `"$codexHome\codex-global-state.json`" `"$backupDir`" -Force -ErrorAction SilentlyContinue"

    $bundledSource = Get-CodexBundledSourceCandidate
    $fixedSource = Join-Path $codexHome "plugins\sources\openai-bundled-fixed"
    if ($bundledSource) {
        Add-RepairAction `
            -Id "mirror-bundled-source" `
            -Title "Mirror OpenAI bundled plugin source to user directory" `
            -Reason "WindowsApps package files may be protected. Mirroring the bundled plugin source avoids direct install from protected app package paths." `
            -Command "Byte-copy `"$bundledSource`" to `"$fixedSource`"." `
            -Risk "medium"
    }
    else {
        Add-RepairAction `
            -Id "mirror-bundled-source" `
            -Title "Mirror OpenAI bundled plugin source to user directory" `
            -Reason "No bundled plugin source path was found automatically." `
            -Command "Rerun with -PluginSourcePath pointing at app\resources\plugins\openai-bundled." `
            -Risk "medium"
    }

    $codexCommand = Get-Command "codex" -ErrorAction SilentlyContinue
    if ($codexCommand) {
        Add-RepairAction `
            -Id "register-fixed-marketplace" `
            -Title "Register fixed bundled marketplace" `
            -Reason "Codex needs an accessible marketplace source before chrome@openai-bundled and computer-use@openai-bundled can be installed." `
            -Command "codex plugin marketplace remove openai-bundled; codex plugin marketplace add `"$fixedSource`"" `
            -Risk "medium"

        Add-RepairAction `
            -Id "install-core-plugins" `
            -Title "Install Browser, Chrome, and Computer Use plugins" `
            -Reason "Reinstalling the three related bundled plugins can repair missing tool exposure after marketplace/cache corruption." `
            -Command "codex plugin add browser@openai-bundled; codex plugin add chrome@openai-bundled; codex plugin add computer-use@openai-bundled" `
            -Risk "medium"
    }
    else {
        Add-RepairAction `
            -Id "codex-cli-missing" `
            -Title "Codex CLI not found" `
            -Reason "Marketplace repair requires the codex CLI command." `
            -Command "Install or expose the codex CLI in PATH, then rerun repair." `
            -Risk "low"
    }

    Add-RepairAction `
        -Id "restart-codex" `
        -Title "Restart Codex Desktop" `
        -Reason "Plugin tools are attached when Codex starts and when a thread is created." `
        -Command "Restart Codex Desktop, then create a fresh thread and mention @computer." `
        -Risk "low"
}

if ($Repair -and $Apply) {
    $backupAction = $repairActions | Where-Object { $_.id -eq "backup-codex-state" } | Select-Object -First 1
    try {
        New-Item -ItemType Directory -Force $backupDir | Out-Null
        if (Test-Path $configPath) {
            Copy-Item $configPath $backupDir -Force
        }
        $globalState = Join-Path $codexHome "codex-global-state.json"
        if (Test-Path $globalState) {
            Copy-Item $globalState $backupDir -Force
        }
        $backupAction.applied = $true
        $backupAction.result = "Backed up to $backupDir"
    }
    catch {
        $backupAction.result = $_.Exception.Message
    }

    $bundledSource = Get-CodexBundledSourceCandidate
    if ($bundledSource) {
        $mirrorAction = $repairActions | Where-Object { $_.id -eq "mirror-bundled-source" } | Select-Object -First 1
        try {
            if (Test-Path $fixedSource) {
                $previousSource = $fixedSource + ".previous-" + (Get-Date -Format "yyyyMMdd-HHmmss")
                Move-Item $fixedSource $previousSource -Force
            }
            Copy-DirectoryBytes -Source $bundledSource -Destination $fixedSource
            $mirrorAction.applied = $true
            $mirrorAction.result = "Mirrored from $bundledSource"
        }
        catch {
            $mirrorAction.result = $_.Exception.Message
        }
    }

    $codexCommand = Get-Command "codex" -ErrorAction SilentlyContinue
    if ($codexCommand -and (Test-Path $fixedSource)) {
        $marketAction = $repairActions | Where-Object { $_.id -eq "register-fixed-marketplace" } | Select-Object -First 1
        try {
            [void](Invoke-External -FilePath $codexCommand.Source -Arguments @("plugin", "marketplace", "remove", "openai-bundled"))
            $addResult = Invoke-External -FilePath $codexCommand.Source -Arguments @("plugin", "marketplace", "add", $fixedSource)
            $marketAction.applied = $addResult.exit_code -eq 0
            $marketAction.result = if ($addResult.exit_code -eq 0) { "Registered $fixedSource" } else { $addResult.stderr }
        }
        catch {
            $marketAction.result = $_.Exception.Message
        }

        $installAction = $repairActions | Where-Object { $_.id -eq "install-core-plugins" } | Select-Object -First 1
        try {
            $pluginResults = @()
            foreach ($plugin in @("browser@openai-bundled", "chrome@openai-bundled", "computer-use@openai-bundled")) {
                $result = Invoke-External -FilePath $codexCommand.Source -Arguments @("plugin", "add", $plugin)
                $pluginResults += "$plugin exit=$($result.exit_code)"
            }
            $installAction.applied = $true
            $installAction.result = $pluginResults -join "; "
        }
        catch {
            $installAction.result = $_.Exception.Message
        }
    }
}

$summary = [pscustomobject]@{
    tool = "codex-windows-plugin-doctor"
    version = "0.1.0"
    generated_at = (Get-Date).ToString("s")
    platform = [System.Environment]::OSVersion.VersionString
    codex_home = $codexHome
    checks = $checks
    repair_plan = $repairPlan
    repair_actions = $repairActions
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
    $lines.Add("Repair plan:")
    foreach ($step in $repairPlan) {
        $lines.Add("  - $step")
    }
    if ($Repair) {
        $lines.Add("")
        if ($Apply) {
            $lines.Add("Repair actions applied:")
        }
        else {
            $lines.Add("Repair actions (dry run; rerun with -Repair -Apply to execute):")
        }
        foreach ($action in $repairActions) {
            $lines.Add("[$($action.risk)] $($action.title)")
            $lines.Add("  Reason: $($action.reason)")
            $lines.Add("  Command: $($action.command)")
            if ($action.result) {
                $lines.Add("  Result: $($action.result)")
            }
            $lines.Add("")
        }
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
