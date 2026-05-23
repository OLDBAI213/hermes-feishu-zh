param(
    [string]$HermesHome = $(if ($env:HERMES_HOME) { $env:HERMES_HOME } else { "" }),
    [switch]$SkipGateway
)

$ErrorActionPreference = "Stop"
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
    # Note: $HermesRoot is set later in script scope, not available here
    foreach ($candidate in $candidates) {
        if (-not $candidate) { continue }
        try { $full = [System.IO.Path]::GetFullPath($candidate) } catch { continue }
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
    foreach ($candidate in @((Join-Path $AgentRoot "venv\Scripts\python.exe"), (Join-Path $AgentRoot ".venv\Scripts\python.exe"))) {
        if (Test-Path -LiteralPath $candidate) { return $candidate }
    }
    $python = Get-Command python -ErrorAction SilentlyContinue
    if ($python) { return $python.Source }
    throw "Python not found. Expected Hermes venv under $AgentRoot."
}

$HermesHome = Resolve-HermesHome -Requested $HermesHome
$AgentRoot = Get-AgentRoot -HermesRoot $HermesHome
$Python = Get-HermesPython -AgentRoot $AgentRoot
$SourcePatchPath = Join-Path $PackRoot "patches\feishu-card-zh.replacements.json"

$env:HERMES_HOME = $HermesHome
$env:SOURCE_PATCH_PATH = $SourcePatchPath
$scripts = Join-Path $AgentRoot "venv\Scripts"
if (-not (Test-Path -LiteralPath $scripts)) {
    $scripts = Join-Path $AgentRoot ".venv\Scripts"
}
if ((Test-Path -LiteralPath $scripts) -and -not (($env:Path -split ';') -contains $scripts)) {
    $env:Path = $scripts + ";" + $env:Path
}

Write-Step "Hermes"
where.exe hermes
hermes --version

Write-Step "Config"
@'
from pathlib import Path
from ruamel.yaml import YAML
import os

home = Path(os.environ["HERMES_HOME"])
cfg = YAML().load((home / "config.yaml").read_text(encoding="utf-8")) or {}
display = cfg.get("display") or {}
feishu_display = ((display.get("platforms") or {}).get("feishu") or {})
feishu_platform = (((cfg.get("platforms") or {}).get("feishu") or {}).get("extra") or {})
plugins_enabled = ((cfg.get("plugins") or {}).get("enabled")) or []
platform_toolsets = cfg.get("platform_toolsets") or {}
toolsets = cfg.get("toolsets") or []
model = cfg.get("model") or {}

checks = {
    "display.language": display.get("language"),
    "display.gateway_locale": display.get("gateway_locale"),
    "display.tui_auto_resume_recent": display.get("tui_auto_resume_recent"),
    "display.platforms.feishu.tool_progress": feishu_display.get("tool_progress"),
    "display.platforms.feishu.streaming": feishu_display.get("streaming"),
    "platforms.feishu.extra.card_mode": feishu_platform.get("card_mode"),
    "platforms.feishu.extra.outbound_format": feishu_platform.get("outbound_format"),
    "plugins.enabled has lark-cli-toolbox": "lark-cli-toolbox" in plugins_enabled,
    "platform_toolsets.cli has lark_cli": "lark_cli" in (platform_toolsets.get("cli") or []),
    "platform_toolsets.feishu has lark_cli": "lark_cli" in (platform_toolsets.get("feishu") or []),
    "toolsets has lark_cli": "lark_cli" in toolsets,
    "model.provider": model.get("provider"),
    "model.default": model.get("default"),
}
for key, value in checks.items():
    print(f"{key} = {value}")

assert display.get("language") == "zh"
assert display.get("gateway_locale") == "zh"
assert display.get("tui_auto_resume_recent") is True
assert feishu_platform.get("outbound_format") in {"post", "card"}
assert "lark-cli-toolbox" in plugins_enabled
assert "lark_cli" in (platform_toolsets.get("cli") or [])
assert "lark_cli" in (platform_toolsets.get("feishu") or [])
assert "lark_cli" in toolsets
'@ | & $Python -

Write-Step "Source Chinese labels"
@'
import json
import os
from pathlib import Path

home = Path(os.environ["HERMES_HOME"])
patch_path = Path(os.environ["SOURCE_PATCH_PATH"])
items = json.loads(patch_path.read_text(encoding="utf-8-sig"))
missing = []
for idx, item in enumerate(items, 1):
    target = home / item["file"]
    if not target.exists():
        missing.append(f"{idx}: target missing: {target}")
        continue
    text = target.read_text(encoding="utf-8-sig")
    if item["find"] not in text and item["replace"] not in text:
        missing.append(f"{idx}: marker missing: {item['file']}")
print("rule_count =", len(items))
print("missing =", len(missing))
if missing:
    print("\n".join(missing))
raise SystemExit(1 if missing else 0)
'@ | & $Python -

Write-Step "Plugin"
@'
from pathlib import Path
import os

home = Path(os.environ["HERMES_HOME"])
plugin = home / "plugins" / "lark-cli-toolbox"
print("plugin.path =", plugin)
print("plugin.exists =", plugin.exists())
assert (plugin / "plugin.yaml").exists()
assert (plugin / "__init__.py").exists()

from hermes_cli.plugins import PluginManager
from tools.registry import registry
mgr = PluginManager()
mgr.discover_and_load(force=True)
loaded = mgr._plugins.get("lark-cli-toolbox")
tools = sorted(name for name, entry in registry._tools.items() if entry.toolset == "lark_cli")
print("plugin.loaded =", bool(loaded and loaded.enabled))
print("lark_cli.tool_count =", len(tools))
print("lark_cli.tools =", ",".join(tools))
assert loaded and loaded.enabled
assert len(tools) >= 10
'@ | & $Python -

Write-Step "lark-cli"
if (Get-Command lark-cli -ErrorAction SilentlyContinue) {
    lark-cli --version
    $doctorOutput = lark-cli doctor 2>&1
    $doctorOutput | Out-Host
    if ($LASTEXITCODE -ne 0) {
        throw "lark-cli doctor failed. Run: lark-cli config bind --source hermes --identity bot-only"
    }
} else {
    Write-Host "lark-cli not found in PATH. Set LARK_CLI_BIN or install lark-cli before using lark_cli tools."
}

Write-Step "Feishu payload modes"
@'
import json
from gateway.config import PlatformConfig
from gateway.platforms.feishu import FeishuAdapter

cases = [
    ({}, "auto"),
    ({"outbound_format": "text"}, "text"),
    ({"outbound_format": "post"}, "post"),
    ({"card_mode": True}, "card"),
]
for extra, label in cases:
    adapter = FeishuAdapter(PlatformConfig(extra=extra))
    msg_type, payload = adapter._build_outbound_payload("## 标题\n\n正文")
    print(label, "=>", msg_type)
    if label == "post":
        assert msg_type == "post"
    if label == "card":
        parsed = json.loads(payload)
        assert msg_type == "interactive"
        assert parsed["elements"][0]["tag"] == "markdown"
'@ | & $Python -

if (-not $SkipGateway) {
    Write-Step "Gateway"
    $statusText = hermes gateway status
    $statusText | Out-Host
    $statePath = Join-Path $HermesHome "gateway_state.json"
    if (Test-Path -LiteralPath $statePath) {
        $stateText = Get-Content -LiteralPath $statePath -Raw
        $stateText | Write-Host
        $state = $stateText | ConvertFrom-Json
        if ($state.gateway_state -ne "running") {
            throw "Gateway is not running: $($state.gateway_state)"
        }
        if ($state.platforms.feishu.state -ne "connected") {
            throw "Feishu is not connected: $($state.platforms.feishu.state)"
        }
    } else {
        Write-Host "gateway_state.json not found. Gateway may be stopped; skip with -SkipGateway if this is expected."
    }
}

Write-Step "OK"
Write-Host "hermes-feishu-zh verification passed."
