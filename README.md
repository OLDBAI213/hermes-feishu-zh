# hermes-feishu-zh

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Hermes Agent](https://img.shields.io/badge/Hermes_Agent-%3E%3D0.14.0-9B59B6.svg)](https://github.com/NousResearch/hermes-agent)
[![Feishu](https://img.shields.io/badge/Feishu-%E4%B8%AD%E6%96%87-4ECDC4.svg)](https://github.com/OLDBAI213/hermes-feishu-zh)
[![Version](https://img.shields.io/badge/version-0.2.1-blue.svg)](https://github.com/OLDBAI213/hermes-feishu-zh/releases)

> **让 Hermes Agent 在飞书里说中文。** 一键安装，85 条汉化规则，不改你现有配置。

[English](#english) | 中文

---

## 这是什么？

Hermes Agent 默认在飞书里输出英文 — 错误信息看不懂、界面元素是英文、Webhook 报错全是英文。

**hermes-feishu-zh** 是一个社区扩展，把 85 处飞书输出替换为中文，同时提供稳定的 `post` 输出格式和 `lark-cli` 工具箱。

### 安装前 vs 安装后

| 场景 | 安装前 | 安装后 |
|------|--------|--------|
| 消息占位符 | `[Rich text message]` | `[富文本消息]` |
| Webhook 错误 | `Rate limit exceeded` | `请求过于频繁` |
| Webhook 错误 | `Payload too large` | `请求体过大` |
| 评论默认标题 | `Untitled document` | `未命名文档` |
| CLI 输出 | 英文规则描述 | 中文规则描述 |

---

## 一键安装

```powershell
iex (irm https://raw.githubusercontent.com/OLDBAI213/hermes-feishu-zh/main/install.ps1)
```

安装器会：
- ✅ 将中文配置合并到 `config.yaml`（保留你现有配置）
- ✅ 安装 `lark-cli-toolbox` 插件
- ✅ 设置飞书 `post` 输出格式（稳定显示 Markdown）
- ✅ 自动备份，可随时回滚

---

## 功能特性

### 🔤 85 条中文替换规则

覆盖飞书消息占位符、Webhook 错误、CLI 输出、评论系统、错误信息、媒体下载等。完整列表见 [汉化规则文档](docs/)。

### 📦 lark-cli 工具箱

飞书 API 命令行工具，支持文档操作、消息管理、日历查询等。中文输出。

```bash
# 示例：查询日历
lark-cli calendar agenda

# 示例：搜索文档
lark-cli docs search "关键词"
```

### 🛡️ 安全安装

- 安装前自动备份
- 不修改 API 密钥、飞书凭证、用户 ID
- 可一键回滚、一键卸载

### 🔄 增强模式（可选）

额外补丁 Hermes 源码，支持更丰富的卡片输出。适合追求极致体验的用户。

---

## 快速命令

| 操作 | 命令 |
|------|------|
| **安装** | `iex (irm https://raw.githubusercontent.com/OLDBAI213/hermes-feishu-zh/main/install.ps1)` |
| **验证** | `powershell -ExecutionPolicy Bypass -File .\verify.ps1` |
| **回滚** | `powershell -ExecutionPolicy Bypass -File .\install.ps1 -Rollback latest` |
| **卸载** | `powershell -ExecutionPolicy Bypass -File .\install.ps1 -Uninstall` |

---

## 环境要求

- Windows PowerShell 或 PowerShell 7
- Hermes Agent >= 0.14.0 已安装
- 飞书 Gateway 已配置
- 可选：`lark-cli` 已安装（用于工具箱功能）

---

## 项目结构

```
hermes-feishu-zh/
├── install.ps1          # 安装/回滚/卸载脚本
├── verify.ps1           # 验证脚本
├── manifest.json        # 扩展清单
├── patches/             # 源码补丁（增强模式）
├── plugins/             # lark-cli-toolbox 插件
├── tools/               # 辅助工具
├── docs/                # 文档
└── tests/               # 测试
```

---

## 贡献

欢迎提交 issue 和 PR！详见 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 许可证

MIT License

---

<div align="center">

**由 [小白 🤖](https://github.com/OLDBAI213) 独立维护** | Hermes Agent 社区扩展

</div>

---

## English

**Make Hermes Agent speak Chinese in Feishu (Lark).**

A community extension that replaces 85 English outputs with Chinese translations in Hermes Agent's Feishu integration. One-click install, preserves your existing config.

### Quick Install

```powershell
iex (irm https://raw.githubusercontent.com/OLDBAI213/hermes-feishu-zh/main/install.ps1)
```

### Features

- 🔤 85 Chinese translation rules for Feishu messages, webhooks, CLI output, error messages
- 📦 `lark-cli` toolbox for Feishu API operations
- 🛡️ Safe install with auto-backup and one-click rollback
- 🔄 Enhanced mode for richer card output (optional)

### Requirements

- Windows PowerShell 5.1+ or PowerShell 7+
- Hermes Agent >= 0.14.0
- Feishu Gateway configured

---

<div align="center">

**Maintained by [XiaoBai 🤖](https://github.com/OLDBAI213)** | Community extension for Hermes Agent

</div>
