<# 
.SYNOPSIS
    hermes-feishu-zh 一键安装引导脚本
.DESCRIPTION
    从 GitHub 下载 hermes-feishu-zh 并执行安装。
    用法：iex (irm https://raw.githubusercontent.com/OLDBAI213/hermes-feishu-zh/main/bootstrap.ps1)
#>

$ErrorActionPreference = "Stop"

$RepoUrl = "https://github.com/OLDBAI213/hermes-feishu-zh.git"
$TempDir = Join-Path $env:TEMP "hermes-feishu-zh-$(Get-Date -Format 'yyyyMMddHHmmss')"

try {
    Write-Host "📥 下载 hermes-feishu-zh..." -ForegroundColor Cyan
    
    # 检查 git 是否可用
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw "需要安装 Git。请先安装 Git: https://git-scm.com/"
    }
    
    # 克隆仓库
    git clone --depth 1 $RepoUrl $TempDir 2>&1 | Out-Null
    
    if (-not (Test-Path (Join-Path $TempDir "install.ps1"))) {
        throw "下载失败：找不到 install.ps1"
    }
    
    Write-Host "🔧 开始安装..." -ForegroundColor Cyan
    
    # 执行安装
    $installScript = Join-Path $TempDir "install.ps1"
    & $installScript @args
    
} catch {
    Write-Host "❌ 安装失败: $_" -ForegroundColor Red
    exit 1
} finally {
    # 清理临时目录
    if (Test-Path $TempDir) {
        Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
