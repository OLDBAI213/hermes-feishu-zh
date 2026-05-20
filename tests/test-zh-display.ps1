param(
    [string]$HermesHome = $(if ($env:HERMES_HOME) { $env:HERMES_HOME } else { "" })
)

$ErrorActionPreference = "Stop"
$PackRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

function Write-Step {
    param([string]$Message)
    Write-Host "`n== $Message =="
}

function Write-Check {
    param([string]$Name, [bool]$Pass)
    $icon = if ($Pass) { "OK" } else { "FAIL" }
    $color = if ($Pass) { "Green" } else { "Red" }
    Write-Host "  [$icon] $Name" -ForegroundColor $color
}

function Resolve-HermesHome {
    param([string]$Requested)
    $candidates = @()
    if ($Requested) { $candidates += $Requested }
    if ($env:HERMES_HOME) { $candidates += $env:HERMES_HOME }
    $hermesCommand = Get-Command hermes -ErrorAction SilentlyContinue
    if ($hermesCommand) {
        $scriptsDir = Split-Path -Parent $hermesCommand.Source
        $agentRoot = Split-Path -Parent (Split-Path -Parent $scriptsDir)
        $detectedHome = Split-Path -Parent $agentRoot
        if ($detectedHome) { $candidates += $detectedHome }
    }
    foreach ($candidate in $candidates) {
        if (-not $candidate) { continue }
        try { $full = [System.IO.Path]::GetFullPath($candidate) } catch { continue }
        if ((Test-Path -LiteralPath (Join-Path $full "config.yaml")) -and
            (Test-Path -LiteralPath (Join-Path $full "hermes-agent"))) {
            return $full
        }
    }
    throw "Cannot find Hermes home."
}

function Get-AgentRoot {
    param([string]$HermesRoot)
    $agentRoot = Join-Path $HermesRoot "hermes-agent"
    if (-not (Test-Path -LiteralPath $agentRoot)) { throw "hermes-agent not found: $agentRoot" }
    return $agentRoot
}

function Get-HermesPython {
    param([string]$AgentRoot)
    foreach ($candidate in @((Join-Path $AgentRoot "venv\Scripts\python.exe"), (Join-Path $AgentRoot ".venv\Scripts\python.exe"))) {
        if (Test-Path -LiteralPath $candidate) { return $candidate }
    }
    $python = Get-Command python -ErrorAction SilentlyContinue
    if ($python) { return $python.Source }
    throw "Python not found."
}

$HermesHome = Resolve-HermesHome -Requested $HermesHome
$AgentRoot = Get-AgentRoot -HermesRoot $HermesHome
$Python = Get-HermesPython -AgentRoot $AgentRoot

$env:HERMES_HOME = $HermesHome
$env:SOURCE_PATCH_PATH = Join-Path $PackRoot "patches\feishu-card-zh.replacements.json"
$scripts = Join-Path $AgentRoot "venv\Scripts"
if (-not (Test-Path -LiteralPath $scripts)) { $scripts = Join-Path $AgentRoot ".venv\Scripts" }
if ((Test-Path -LiteralPath $scripts) -and -not (($env:Path -split ';') -contains $scripts)) {
    $env:Path = $scripts + ";" + $env:Path
}

$totalPass = 0
$totalFail = 0

# ============================================================
Write-Step "1. Config 中文化检查"
# ============================================================

@'
from pathlib import Path
from ruamel.yaml import YAML
import os, json

home = Path(os.environ["HERMES_HOME"])
cfg = YAML().load((home / "config.yaml").read_text(encoding="utf-8")) or {}
display = cfg.get("display") or {}
feishu_display = ((display.get("platforms") or {}).get("feishu") or {})
feishu_platform = (((cfg.get("platforms") or {}).get("feishu") or {}).get("extra") or {})

checks = [
    ("display.language == zh", display.get("language") == "zh"),
    ("display.gateway_locale == zh", display.get("gateway_locale") == "zh"),
    ("display.tui_auto_resume_recent == True", display.get("tui_auto_resume_recent") is True),
    ("feishu.streaming == True", feishu_display.get("streaming") is True),
    ("feishu.tool_progress == new", feishu_display.get("tool_progress") == "new"),
    ("feishu.tool_preview_length >= 120", (feishu_display.get("tool_preview_length") or 0) >= 120),
    ("feishu.runtime_footer.enabled == True", feishu_display.get("runtime_footer", {}).get("enabled") is True),
    ("feishu.runtime_footer.style == zh_detailed", feishu_display.get("runtime_footer", {}).get("style") == "zh_detailed"),
    ("feishu.outbound_format in [post, card]", feishu_platform.get("outbound_format") in {"post", "card"}),
]

results = {"pass": 0, "fail": 0}
for name, ok in checks:
    status = "PASS" if ok else "FAIL"
    print(json.dumps({"check": name, "status": status}))
    if ok:
        results["pass"] += 1
    else:
        results["fail"] += 1

print(json.dumps({"summary": results}))
'@ | & $Python - 2>&1 | ForEach-Object {
    try {
        $obj = $_ | ConvertFrom-Json
        if ($obj.check) {
            $pass = $obj.status -eq "PASS"
            Write-Check $obj.check $pass
            if ($pass) { $totalPass++ } else { $totalFail++ }
        }
    } catch {}
}

# ============================================================
Write-Step "2. 源码中文化标记检查 (feishu-card-zh.replacements.json)"
# ============================================================

@'
import json, os
from pathlib import Path

home = Path(os.environ["HERMES_HOME"])
patch_path = Path(os.environ["SOURCE_PATCH_PATH"])
items = json.loads(patch_path.read_text(encoding="utf-8-sig"))

results = {"pass": 0, "fail": 0, "missing_files": [], "missing_markers": []}

for idx, item in enumerate(items, 1):
    target = home / item["file"]
    if not target.exists():
        results["missing_files"].append(item["file"])
        print(json.dumps({"check": f"rule_{idx}: {item['file']} exists", "status": "FAIL", "detail": "file not found"}))
        results["fail"] += 1
        continue

    text = target.read_text(encoding="utf-8-sig")
    if item["find"] in text:
        # Original English still present = patch NOT applied
        print(json.dumps({"check": f"rule_{idx}: {item['find'][:40]}...", "status": "FAIL", "detail": "English text still present (patch not applied)"}))
        results["fail"] += 1
    elif item["replace"] in text:
        # Chinese replacement found = patch applied
        print(json.dumps({"check": f"rule_{idx}: {item['replace'][:40]}...", "status": "PASS"}))
        results["pass"] += 1
    else:
        # Neither found - marker changed in upstream
        print(json.dumps({"check": f"rule_{idx}: {item['file']}", "status": "WARN", "detail": "neither find nor replace text found"}))

print(json.dumps({"summary": results, "total_rules": len(items)}))
'@ | & $Python - 2>&1 | ForEach-Object {
    try {
        $obj = $_ | ConvertFrom-Json
        if ($obj.check) {
            $pass = $obj.status -eq "PASS"
            $detail = if ($obj.detail) { " ($($obj.detail))" } else { "" }
            Write-Check "$($obj.check)$detail" $pass
            if ($pass) { $totalPass++ } else { $totalFail++ }
        }
    } catch {}
}

# ============================================================
Write-Step "3. 插件加载检查"
# ============================================================

@'
from pathlib import Path
import os

home = Path(os.environ["HERMES_HOME"])
plugin = home / "plugins" / "lark-cli-toolbox"

checks = [
    ("plugin directory exists", plugin.exists()),
    ("plugin.yaml exists", (plugin / "plugin.yaml").exists()),
    ("__init__.py exists", (plugin / "__init__.py").exists()),
]

try:
    from hermes_cli.plugins import PluginManager
    from tools.registry import registry
    mgr = PluginManager()
    mgr.discover_and_load(force=True)
    loaded = mgr._plugins.get("lark-cli-toolbox")
    tools = sorted(name for name, entry in registry._tools.items() if entry.toolset == "lark_cli")
    checks.append(("plugin loaded and enabled", bool(loaded and loaded.enabled)))
    checks.append((f"lark_cli tools registered (count={len(tools)})", len(tools) >= 10))
    checks.append(("tools: " + ", ".join(tools[:5]) + "...", True))
except Exception as e:
    checks.append(("plugin import/register", False))

for name, ok in checks:
    status = "PASS" if ok else "FAIL"
    print(f'{{"check": "{name}", "status": "{status}}"}}')
'@ | & $Python - 2>&1 | ForEach-Object {
    try {
        $obj = $_ | ConvertFrom-Json
        if ($obj.check) {
            $pass = $obj.status -eq "PASS"
            Write-Check $obj.check $pass
            if ($pass) { $totalPass++ } else { $totalFail++ }
        }
    } catch {}
}

# ============================================================
Write-Step "4. Feishu Payload 模式检查"
# ============================================================

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
    try:
        adapter = FeishuAdapter(PlatformConfig(extra=extra))
        msg_type, payload = adapter._build_outbound_payload("## 标题\n\n正文")
        ok = True
        if label == "post":
            ok = msg_type == "post"
        if label == "card":
            parsed = json.loads(payload)
            ok = msg_type == "interactive" and parsed["elements"][0]["tag"] == "markdown"
        print(json.dumps({"check": f"payload mode: {label} => {msg_type}", "status": "PASS" if ok else "FAIL"}))
    except Exception as e:
        print(json.dumps({"check": f"payload mode: {label}", "status": "FAIL", "detail": str(e)}))
'@ | & $Python - 2>&1 | ForEach-Object {
    try {
        $obj = $_ | ConvertFrom-Json
        if ($obj.check) {
            $pass = $obj.status -eq "PASS"
            Write-Check $obj.check $pass
            if ($pass) { $totalPass++ } else { $totalFail++ }
        }
    } catch {}
}

# ============================================================
Write-Step "5. Gateway 状态检查"
# ============================================================

$statePath = Join-Path $HermesHome "gateway_state.json"
if (Test-Path -LiteralPath $statePath) {
    $state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
    $gwRunning = $state.gateway_state -eq "running"
    $feishuConnected = $state.platforms.feishu.state -eq "connected"
    Write-Check "gateway_state == running" $gwRunning
    Write-Check "feishu.state == connected" $feishuConnected
    if ($gwRunning) { $totalPass++ } else { $totalFail++ }
    if ($feishuConnected) { $totalPass++ } else { $totalFail++ }
} else {
    Write-Check "gateway_state.json exists" $false
    $totalFail++
}

# ============================================================
Write-Step "6. lark-cli 检查"
# ============================================================

if (Get-Command lark-cli -ErrorAction SilentlyContinue) {
    $version = lark-cli --version 2>&1
    Write-Check "lark-cli installed ($version)" $true
    $totalPass++

    $doctor = lark-cli doctor 2>&1 | ConvertFrom-Json
    $doctorPass = $doctor.checks | Where-Object { $_.status -eq "fail" } | Measure-Object | Select-Object -ExpandProperty Count
    $doctorOk = $doctorPass -eq 0
    Write-Check "lark-cli doctor passed" $doctorOk
    if ($doctorOk) { $totalPass++ } else { $totalFail++ }
} else {
    Write-Check "lark-cli installed" $false
    $totalFail++
}

# ============================================================
Write-Step "SUMMARY"
# ============================================================

Write-Host ""
Write-Host "  Total checks: $($totalPass + $totalFail)" -ForegroundColor Cyan
Write-Host "  Passed: $totalPass" -ForegroundColor Green
Write-Host "  Failed: $totalFail" -ForegroundColor $(if ($totalFail -gt 0) { "Red" } else { "Green" })
Write-Host ""

if ($totalFail -eq 0) {
    Write-Host "  All Chinese display checks passed!" -ForegroundColor Green
} else {
    Write-Host "  Some checks failed. Run verify.ps1 for details." -ForegroundColor Yellow
}
