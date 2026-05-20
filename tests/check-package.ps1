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
    "patches\stable.config.yaml",
    "patches\enhanced.config.yaml",
    "patches\feishu-card-zh.replacements.json",
    "patches\feishu-display-upgrade.replacements.json",
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

Get-Content -LiteralPath (Join-Path $ProjectRoot "patches\feishu-card-zh.replacements.json") -Raw | ConvertFrom-Json | Out-Null
Get-Content -LiteralPath (Join-Path $ProjectRoot "patches\feishu-display-upgrade.replacements.json") -Raw | ConvertFrom-Json | Out-Null

$secretPatterns = @(
    "FEISHU_APP_SECRET\s*=",
    "XIAOMI_API_KEY\s*=",
    "sk-[A-Za-z0-9]",
    "xox[baprs]-"
)

$files = Get-ChildItem -LiteralPath $ProjectRoot -Recurse -File |
    Where-Object { $_.FullName -notmatch '\\.git\\' }
foreach ($file in $files) {
    $text = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction SilentlyContinue
    foreach ($pattern in $secretPatterns) {
        if ($text -match $pattern) {
            throw "Potential secret pattern '$pattern' found in $($file.FullName)"
        }
    }
}

Write-Host "Package check passed: $ProjectRoot"
