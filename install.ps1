param(
    [string]$HermesHome = $(if ($env:HERMES_HOME) { $env:HERMES_HOME } else { "" }),
    [ValidateSet("stable", "enhanced")]
    [string]$Profile = "stable",
    [switch]$VerifyOnly,
    [string]$Rollback = "",
    [switch]$Uninstall,
    [switch]$RestartGateway,
    [switch]$NoLarkCliToolbox,
    [switch]$NoSourceZh,
    [switch]$NoVerify
)

$ErrorActionPreference = "Stop"

$PackageName = "hermes-feishu-zh"
$PackRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

function Write-Step {
    param([string]$Message)
    Write-Host "== $Message =="
}

function Resolve-HermesHome {
    param([string]$Requested)

    $candidates = @()
    if ($Requested) { $candidates += $Requested }
    if ($env:HERMES_HOME) { $candidates += $env:HERMES_HOME }

    $hermesCommand = Get-Command hermes -ErrorAction SilentlyContinue
    if ($hermesCommand -and -not $hermesCommand.Source) {
        $hermesCommand = Get-Command hermes.exe -ErrorAction SilentlyContinue
    }
    if ($hermesCommand) {
        $hermesPath = if ($hermesCommand.Source) { $hermesCommand.Source } elseif ($hermesCommand.Path) { $hermesCommand.Path } else { "" }
        if ($hermesPath) {
            $scriptsDir = Split-Path -Parent $hermesPath
            $agentRoot = Split-Path -Parent (Split-Path -Parent $scriptsDir)
            $detectedHome = Split-Path -Parent $agentRoot
            if ($detectedHome) { $candidates += $detectedHome }
        }
    }

    # Note: $HermesRoot is script-scope, not available inside this function.
    # The fallback path is handled by the candidates loop above.

    foreach ($candidate in $candidates) {
        if (-not $candidate) { continue }
        try {
            $full = [System.IO.Path]::GetFullPath($candidate)
        } catch {
            continue
        }
        if ((Test-Path -LiteralPath (Join-Path $full "config.yaml")) -and
            (Test-Path -LiteralPath (Join-Path $full "hermes-agent"))) {
            return $full
        }
    }

    throw "Cannot find Hermes home. Set HERMES_HOME or pass -HermesHome <path>."
}

function Get-AgentRoot {
    param([string]$HermesRoot)
    $agentRoot = Join-Path $HermesRoot "hermes-agent"
    if (-not (Test-Path -LiteralPath $agentRoot)) {
        throw "hermes-agent not found: $agentRoot"
    }
    return $agentRoot
}

function Get-HermesPython {
    param([string]$AgentRoot)
    $candidates = @(
        (Join-Path $AgentRoot "venv\Scripts\python.exe"),
        (Join-Path $AgentRoot ".venv\Scripts\python.exe")
    )
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) { return $candidate }
    }
    $python = Get-Command python -ErrorAction SilentlyContinue
    if ($python) { return $python.Source }
    throw "Python not found. Expected Hermes venv under $AgentRoot."
}

function Set-HermesProcessEnv {
    param([string]$HermesRoot, [string]$AgentRoot)
    $scripts = Join-Path $AgentRoot "venv\Scripts"
    if (-not (Test-Path -LiteralPath $scripts)) {
        $scripts = Join-Path $AgentRoot ".venv\Scripts"
    }
    $env:HERMES_HOME = $HermesRoot
    if ((Test-Path -LiteralPath $scripts) -and -not (($env:Path -split ';') -contains $scripts)) {
        $env:Path = $scripts + ";" + $env:Path
    }
}

function New-Backup {
    param([string]$HermesRoot)
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupRoot = Join-Path $HermesRoot "backups"
    $backupDir = Join-Path $backupRoot "$PackageName-$stamp"
    New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
    return $backupDir
}

function Write-BackupManifest {
    param(
        [string]$BackupDir,
        [string]$HermesRoot,
        [string]$Profile,
        [bool]$PluginExisted
    )
    $manifest = [ordered]@{
        package = $PackageName
        created_at = (Get-Date).ToString("o")
        hermes_home = $HermesRoot
        profile = $Profile
        plugin_existed = $PluginExisted
    }
    $manifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $BackupDir "backup-manifest.json") -Encoding UTF8
}

function Copy-IfExists {
    param([string]$Path, [string]$Destination)
    if (Test-Path -LiteralPath $Path) {
        Copy-Item -LiteralPath $Path -Destination $Destination -Force
    }
}

function Copy-DirIfExists {
    param([string]$Path, [string]$Destination)
    if (Test-Path -LiteralPath $Path) {
        Copy-Item -LiteralPath $Path -Destination $Destination -Recurse -Force
    }
}

function Merge-Config {
    param(
        [string]$Python,
        [string]$ConfigPath,
        [string]$PatchPath,
        [bool]$InstallLark
    )

    $installLarkText = if ($InstallLark) { "true" } else { "false" }
    $mergeScript = @'
import sys
from pathlib import Path
from ruamel.yaml import YAML

config_path = Path(sys.argv[1])
patch_path = Path(sys.argv[2])
install_lark = sys.argv[3].strip().lower() in {"1", "true", "yes", "on"}

yaml = YAML()
yaml.preserve_quotes = True
config = yaml.load(config_path.read_text(encoding="utf-8")) or {}
patch = yaml.load(patch_path.read_text(encoding="utf-8")) or {}

def merge(dst, src):
    for key, value in src.items():
        if isinstance(value, dict) and isinstance(dst.get(key), dict):
            merge(dst[key], value)
        else:
            dst[key] = value

def ensure_list_path(root, path):
    cur = root
    for key in path[:-1]:
        value = cur.get(key)
        if not isinstance(value, dict):
            value = {}
            cur[key] = value
        cur = value
    leaf = cur.get(path[-1])
    if not isinstance(leaf, list):
        leaf = []
        cur[path[-1]] = leaf
    return leaf

def append_unique(items, value):
    if value not in items:
        items.append(value)

merge(config, patch)

display = config.setdefault("display", {})
display["tui_auto_resume_recent"] = True

if install_lark:
    append_unique(ensure_list_path(config, ["plugins", "enabled"]), "lark-cli-toolbox")
    append_unique(ensure_list_path(config, ["platform_toolsets", "cli"]), "lark_cli")
    append_unique(ensure_list_path(config, ["platform_toolsets", "feishu"]), "lark_cli")
    append_unique(ensure_list_path(config, ["toolsets"]), "lark_cli")

with config_path.open("w", encoding="utf-8") as f:
    yaml.dump(config, f)
'@
    $mergeScript | & $Python - $ConfigPath $PatchPath $installLarkText
}

function Apply-Replacements {
    param(
        [string]$JsonPath,
        [string]$RootPath,
        [string]$BackupDir
    )

    $items = Get-Content -LiteralPath $JsonPath -Raw | ConvertFrom-Json
    foreach ($item in $items) {
        $target = Join-Path $RootPath $item.file
        if (-not (Test-Path -LiteralPath $target)) {
            throw "Patch target not found: $target"
        }
        $backupName = ($item.file -replace '[\\/]', '__') + ".bak"
        $backupPath = Join-Path $BackupDir $backupName
        if (-not (Test-Path -LiteralPath $backupPath)) {
            Copy-IfExists -Path $target -Destination $backupPath
        }

        $text = Get-Content -LiteralPath $target -Raw -Encoding UTF8
        if ($text.Contains($item.find)) {
            $text = $text.Replace($item.find, $item.replace)
            Set-Content -LiteralPath $target -Value $text -Encoding UTF8 -NoNewline
            continue
        }
        if ($text.Contains($item.replace)) {
            continue
        }
        throw "Patch marker not found in $target"
    }
}

function Get-LatestBackup {
    param([string]$HermesRoot)
    $backupRoot = Join-Path $HermesRoot "backups"
    if (-not (Test-Path -LiteralPath $backupRoot)) { return $null }
    Get-ChildItem -LiteralPath $backupRoot -Directory -Filter "$PackageName-*" |
        Sort-Object Name -Descending |
        Select-Object -First 1
}

function Restore-Backup {
    param([string]$HermesRoot, [string]$Name)

    $backupRoot = Join-Path $HermesRoot "backups"
    if ($Name -eq "latest") {
        $backup = Get-LatestBackup -HermesRoot $HermesRoot
        if (-not $backup) { throw "No $PackageName backup found under $backupRoot." }
        $backupDir = $backup.FullName
    } else {
        $backupDir = Join-Path $backupRoot $Name
    }

    if (-not (Test-Path -LiteralPath $backupDir)) {
        throw "Backup not found: $backupDir"
    }

    Write-Step "Rollback"
    Copy-IfExists -Path (Join-Path $backupDir "config.yaml") -Destination (Join-Path $HermesRoot "config.yaml")

    $backupManifestPath = Join-Path $backupDir "backup-manifest.json"
    $pluginExisted = $true
    if (Test-Path -LiteralPath $backupManifestPath) {
        $backupManifest = Get-Content -LiteralPath $backupManifestPath -Raw | ConvertFrom-Json
        $pluginExisted = [bool]$backupManifest.plugin_existed
    }

    $pluginBackup = Join-Path $backupDir "lark-cli-toolbox.bak"
    $pluginTarget = Join-Path $HermesRoot "plugins\lark-cli-toolbox"
    if (Test-Path -LiteralPath $pluginBackup) {
        if (Test-Path -LiteralPath $pluginTarget) {
            Remove-Item -LiteralPath $pluginTarget -Recurse -Force
        }
        Copy-Item -LiteralPath $pluginBackup -Destination $pluginTarget -Recurse -Force
    } elseif (-not $pluginExisted -and (Test-Path -LiteralPath $pluginTarget)) {
        Remove-Item -LiteralPath $pluginTarget -Recurse -Force
    }

    Get-ChildItem -LiteralPath $backupDir -File -Filter "*.bak" | ForEach-Object {
        if ($_.Name -eq "lark-cli-toolbox.bak") { return }
        $relative = $_.BaseName -replace '__', '\'
        $target = Join-Path $HermesRoot $relative
        $parent = Split-Path -Parent $target
        if ($parent -and -not (Test-Path -LiteralPath $parent)) {
            New-Item -ItemType Directory -Force -Path $parent | Out-Null
        }
        Copy-Item -LiteralPath $_.FullName -Destination $target -Force
    }

    Write-Host "Restored backup: $backupDir"
}

function Invoke-Verify {
    param([string]$HermesRoot)
    $verify = Join-Path $PackRoot "verify.ps1"
    if (-not (Test-Path -LiteralPath $verify)) {
        throw "verify.ps1 not found: $verify"
    }
    & $verify -HermesHome $HermesRoot
}

function Remove-Installation {
    param([string]$HermesRoot)
    Write-Step "Uninstall hermes-feishu-zh"

    # 1. Remove lark-cli-toolbox plugin
    $pluginPath = Join-Path $HermesRoot "plugins\lark-cli-toolbox"
    if (Test-Path -LiteralPath $pluginPath) {
        Remove-Item -LiteralPath $pluginPath -Recurse -Force
        Write-Host "  Removed plugin: lark-cli-toolbox"
    }

    # 2. Remove lark_cli from config
    $configPath = Join-Path $HermesRoot "config.yaml"
    if (Test-Path -LiteralPath $configPath) {
        $python = $Python
        $removeScript = @'
import sys
from pathlib import Path
from ruamel.yaml import YAML

config_path = Path(sys.argv[1])
yaml = YAML()
yaml.preserve_quotes = True
config = yaml.load(config_path.read_text(encoding="utf-8")) or {}

# Remove lark-cli-toolbox from plugins.enabled
plugins = config.get("plugins", {})
enabled = plugins.get("enabled", [])
if "lark-cli-toolbox" in enabled:
    enabled.remove("lark-cli-toolbox")
    plugins["enabled"] = enabled

# Remove lark_cli from platform_toolsets
pts = config.get("platform_toolsets", {})
for key in ["cli", "feishu"]:
    lst = pts.get(key, [])
    if "lark_cli" in lst:
        lst.remove("lark_cli")
        pts[key] = lst

# Remove lark_cli from toolsets
ts = config.get("toolsets", [])
if "lark_cli" in ts:
    ts.remove("lark_cli")
    config["toolsets"] = ts

# Reset display settings to defaults
display = config.get("display", {})
display.pop("gateway_locale", None)
display.pop("language", None)
display.pop("tui_auto_resume_recent", None)
feishu_display = display.get("platforms", {}).get("feishu", {})
feishu_display.pop("streaming", None)
feishu_display.pop("tool_progress", None)
feishu_display.pop("tool_preview_length", None)
feishu_display.pop("runtime_footer", None)
feishu_display.pop("interim_assistant_messages", None)
feishu_display.pop("show_reasoning", None)
feishu_display.pop("cleanup_progress", None)

# Reset feishu platform extra
feishu_platform = config.get("platforms", {}).get("feishu", {}).get("extra", {})
feishu_platform.pop("card_mode", None)
feishu_platform.pop("outbound_format", None)

with config_path.open("w", encoding="utf-8") as f:
    yaml.dump(config, f)

print("Config cleaned")
'@
        $removeScript | & $python - $configPath
        Write-Host "  Cleaned config.yaml"
    }

    # 3. Revert source patches (restore from backup if available)
    $backupDir = Get-LatestBackup -HermesRoot $HermesRoot
    if ($backupDir) {
        Write-Host "  Restoring source files from backup: $($backupDir.Name)"
        Get-ChildItem -LiteralPath $backupDir.FullName -File -Filter "*.bak" | ForEach-Object {
            $relative = $_.BaseName -replace '__', '\'
            $target = Join-Path $HermesRoot $relative
            if (Test-Path -LiteralPath $target) {
                Copy-Item -LiteralPath $_.FullName -Destination $target -Force
            }
        }
    }

    Write-Host ""
    Write-Host "Uninstalled. Restart gateway to apply:"
    Write-Host "  hermes gateway restart"
}

$HermesHome = Resolve-HermesHome -Requested $HermesHome
$AgentRoot = Get-AgentRoot -HermesRoot $HermesHome
$Python = Get-HermesPython -AgentRoot $AgentRoot
Set-HermesProcessEnv -HermesRoot $HermesHome -AgentRoot $AgentRoot

if ($VerifyOnly) {
    Invoke-Verify -HermesRoot $HermesHome
    return
}

if ($Rollback) {
    Restore-Backup -HermesRoot $HermesHome -Name $Rollback
    if (-not $NoVerify) {
        Invoke-Verify -HermesRoot $HermesHome
    }
    return
}

if ($Uninstall) {
    Remove-Installation -HermesRoot $HermesHome
    return
}

$ConfigPath = Join-Path $HermesHome "config.yaml"
$EnvPath = Join-Path $HermesHome ".env"
$PatchPath = Join-Path $PackRoot "patches\$Profile.config.yaml"
$PluginSourceRoot = Join-Path $PackRoot "plugins\lark-cli-toolbox"
$PluginTargetRoot = Join-Path $HermesHome "plugins\lark-cli-toolbox"

if (-not (Test-Path -LiteralPath $PatchPath)) {
    throw "Profile patch not found: $PatchPath"
}

Write-Step "Preflight"
Write-Host "HermesHome: $HermesHome"
Write-Host "Profile: $Profile"
if (-not (Test-Path -LiteralPath $ConfigPath)) { throw "config.yaml not found: $ConfigPath" }
if (-not (Test-Path -LiteralPath $EnvPath)) { Write-Host "Warning: .env not found: $EnvPath" }

$backupDir = New-Backup -HermesRoot $HermesHome
$pluginExistedBefore = Test-Path -LiteralPath $PluginTargetRoot
Write-BackupManifest -BackupDir $backupDir -HermesRoot $HermesHome -Profile $Profile -PluginExisted $pluginExistedBefore
Copy-IfExists -Path $ConfigPath -Destination (Join-Path $backupDir "config.yaml")
Copy-IfExists -Path $EnvPath -Destination (Join-Path $backupDir ".env")
Copy-DirIfExists -Path $PluginTargetRoot -Destination (Join-Path $backupDir "lark-cli-toolbox.bak")

Write-Step "Merge config"
Merge-Config -Python $Python -ConfigPath $ConfigPath -PatchPath $PatchPath -InstallLark (-not $NoLarkCliToolbox)

if (-not $NoLarkCliToolbox) {
    Write-Step "Install lark-cli toolbox"
    if (-not (Test-Path -LiteralPath $PluginSourceRoot)) {
        throw "Pack plugin not found: $PluginSourceRoot"
    }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $PluginTargetRoot) | Out-Null
    if (Test-Path -LiteralPath $PluginTargetRoot) {
        Remove-Item -LiteralPath $PluginTargetRoot -Recurse -Force
    }
    Copy-Item -LiteralPath $PluginSourceRoot -Destination $PluginTargetRoot -Recurse -Force
}

if (-not $NoSourceZh) {
    Write-Step "Apply Feishu Chinese source labels"
    Apply-Replacements -JsonPath (Join-Path $PackRoot "patches\feishu-card-zh.replacements.json") -RootPath $HermesHome -BackupDir $backupDir
}

if ($Profile -eq "enhanced") {
    Write-Step "Apply enhanced Feishu display patch"
    Apply-Replacements -JsonPath (Join-Path $PackRoot "patches\feishu-display-upgrade.replacements.json") -RootPath $HermesHome -BackupDir $backupDir
}

if ($RestartGateway) {
    Write-Step "Restart Gateway"
    hermes gateway stop | Out-Host
    hermes gateway start --all | Out-Host
}

Write-Step "Installed"
Write-Host "Backup: $backupDir"

if (-not $NoVerify) {
    Invoke-Verify -HermesRoot $HermesHome
}
