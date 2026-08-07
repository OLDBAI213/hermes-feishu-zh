param(
    [string]$ProjectRoot = $(Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
)

$ErrorActionPreference = "Stop"

$required = @(
    "install.ps1",
    "verify.ps1",
    "manifest.json",
    "README.md",
    "LICENSE",
    "audit\feishu_localization_audit.py",
    "audit\feishu_zh_audit_allowlist.yaml",
    "patches\stable.config.yaml",
    "patches\enhanced.config.yaml",
    "patches\feishu-zh-v20.replacements.json",
    "patches\display-plus-v20.replacements.json",
    "patches\display-plus\feishu_realtime_display.py",
    "plugins\lark-cli-toolbox\plugin.yaml",
    "plugins\lark-cli-toolbox\__init__.py",
    "docs\README.md",
    "docs\install.md",
    "docs\upgrade.md",
    "docs\troubleshooting.md"
)

foreach ($rel in $required) {
    $path = Join-Path $ProjectRoot $rel
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing required file: $rel"
    }
}

$manifest = Get-Content -LiteralPath (Join-Path $ProjectRoot "manifest.json") -Raw | ConvertFrom-Json
if ($manifest.name -ne "hermes-feishu-zh") {
    throw "Unexpected manifest name: $($manifest.name)"
}
if (-not ($manifest.target.platforms -contains "windows")) {
    throw "Manifest must include windows target platform."
}

Get-Content -LiteralPath (Join-Path $ProjectRoot "patches\feishu-zh-v20.replacements.json") -Raw | ConvertFrom-Json | Out-Null
Get-Content -LiteralPath (Join-Path $ProjectRoot "patches\display-plus-v20.replacements.json") -Raw | ConvertFrom-Json | Out-Null

$secretPatterns = @(
    "FEISHU_APP_SECRET\s*=",
    "XIAOMI_API_KEY\s*=",
    "sk-[A-Za-z0-9_-]{16,}",
    "xox[baprs]-"
)

$relativeFiles = & git -C $ProjectRoot ls-files --cached --others --exclude-standard
if ($LASTEXITCODE -ne 0) {
    throw "Cannot enumerate package files with git."
}
$files = $relativeFiles |
    ForEach-Object { Join-Path $ProjectRoot ($_ -replace '/', '\') } |
    Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } |
    ForEach-Object { Get-Item -LiteralPath $_ }
foreach ($file in $files) {
    $text = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction SilentlyContinue
    foreach ($pattern in $secretPatterns) {
        if ($text -match $pattern) {
            throw "Potential secret pattern '$pattern' found in $($file.FullName)"
        }
    }
}

Write-Host "Package check passed: $ProjectRoot"
