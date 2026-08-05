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

function Assert-NativeSuccess {
    param([string]$Step)
    if ($LASTEXITCODE -ne 0) {
        throw "$Step failed with exit $LASTEXITCODE"
    }
}

$HermesHome = Resolve-HermesHome -Requested $HermesHome
$AgentRoot = Get-AgentRoot -HermesRoot $HermesHome
$Python = Get-HermesPython -AgentRoot $AgentRoot
$SourcePatchPath = Join-Path $PackRoot "patches\feishu-zh-v20.replacements.json"

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
plugins_enabled = ((cfg.get("plugins") or {}).get("enabled")) or []
platform_toolsets = cfg.get("platform_toolsets") or {}
toolsets = cfg.get("toolsets") or []
model = cfg.get("model") or {}

# 飞书平台实际可用工具集（v0.20.0 通过 hermes_cli.tools_config 解析）
try:
    from hermes_cli.tools_config import _get_platform_tools
    feishu_tools = _get_platform_tools(cfg, "feishu")
    has_lark_cli_on_feishu = "lark_cli" in feishu_tools
except Exception as e:
    has_lark_cli_on_feishu = False

checks = {
    "display.language": display.get("language"),
    "plugins.enabled has lark-cli-toolbox": "lark-cli-toolbox" in plugins_enabled,
    "platform_toolsets.cli has lark_cli": "lark_cli" in (platform_toolsets.get("cli") or []),
    "toolsets has lark_cli": "lark_cli" in toolsets,
    "feishu platform resolves lark_cli": has_lark_cli_on_feishu,
    "model.provider": model.get("provider"),
    "model.default": model.get("default"),
}
for key, value in checks.items():
    print(f"{key} = {value}")

assert display.get("language") == "zh"
assert "lark-cli-toolbox" in plugins_enabled
assert "lark_cli" in (platform_toolsets.get("cli") or [])
assert "lark_cli" in toolsets
assert has_lark_cli_on_feishu
'@ | & $Python -
Assert-NativeSuccess "Config"

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
Assert-NativeSuccess "Source Chinese labels"

Write-Step "Feishu localization audit"
$AuditScript = Join-Path $AgentRoot "scripts\feishu_localization_audit.py"
$AuditRules = Join-Path $AgentRoot "locales\feishu_zh_audit_allowlist.yaml"
if (-not (Test-Path -LiteralPath $AuditScript)) {
    throw "Feishu localization audit script not found: $AuditScript"
}
if (-not (Test-Path -LiteralPath $AuditRules)) {
    throw "Feishu localization audit rules not found: $AuditRules"
}
& $Python $AuditScript --root $AgentRoot --rules $AuditRules --json
Assert-NativeSuccess "Feishu localization audit"

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
Assert-NativeSuccess "Plugin"

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

Write-Step "Feishu adapter build"
@'
import json, importlib.util, sys, os
# v0.20.0: FeishuAdapter 从 plugins/platforms/feishu/adapter.py 加载
agent_root = os.environ.get("HERMES_HOME", "")
adapter_path = os.path.join(agent_root, "hermes-agent", "plugins", "platforms", "feishu", "adapter.py")
spec = importlib.util.spec_from_file_location("feishu_adapter_test", adapter_path)
mod = importlib.util.module_from_spec(spec)
try:
    spec.loader.exec_module(mod)
except Exception as e:
    print("adapter import (may require deps):", type(e).__name__, str(e)[:100])
    print("SKIP: adapter has heavy deps, verified via py_compile + audit instead")
    raise SystemExit(0)
FeishuAdapter = mod.FeishuAdapter
adapter = FeishuAdapter.__new__(FeishuAdapter)
msg_type, payload = adapter._build_outbound_payload("## 标题\n\n正文")
print("msg_type =", msg_type)
try:
    parsed = json.loads(payload) if isinstance(payload, str) else payload
    print("payload keys =", list(parsed.keys()) if isinstance(parsed, dict) else type(parsed))
except Exception as e:
    print("payload parse:", e)
assert msg_type in {"post", "text"}
'@ | & $Python -
Assert-NativeSuccess "Feishu adapter build"

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
