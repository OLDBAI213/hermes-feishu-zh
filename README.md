# hermes-feishu-zh

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Hermes Agent](https://img.shields.io/badge/Hermes_Agent-%3E%3D0.14.0-9B59B6.svg)](https://github.com/NousResearch/hermes-agent)
[![Feishu](https://img.shields.io/badge/Feishu-%E4%B8%AD%E6%96%87-4ECDC4.svg)](https://github.com/OLDBAI213/hermes-feishu-zh)
[![Version](https://img.shields.io/badge/version-0.2.1-blue.svg)](https://github.com/OLDBAI213/hermes-feishu-zh/releases)

> **让 Hermes Agent 在飞书里说中文。** 一键安装，102 条汉化/适配规则，不改你现有配置。

[English](#english) | 中文

---

## 这是什么？

Hermes Agent 默认在飞书里输出英文 — 错误信息看不懂、界面元素是英文、Webhook 报错全是英文。

**hermes-feishu-zh** 是一个社区扩展，定位是“飞书中文化 + 基础适配”。它把 102 处飞书输出和必要移动端适配点整理成中文，同时提供稳定的 `post` 输出格式和 `lark-cli` 工具箱。

项目边界：

- 本项目负责：中文化、基础飞书适配、配置合并、`lark-cli-toolbox`、安装/验证/回滚。
- 后续独立项目 `hermes-feishu-plus` 负责：显示美化、交互体验增强、加载动画、状态栏升级、更多移动端布局优化。
- 两者不能互相牺牲：中文化不能打乱原版显示，体验增强也不能丢图片、文件、状态和工具调用信息。

### 安装前 vs 安装后

| 场景 | 安装前 | 安装后 |
|------|--------|--------|
| 消息占位符 | `[Rich text message]` | `[富文本消息]` |
| Webhook 错误 | `Rate limit exceeded` | `请求过于频繁` |
| Webhook 错误 | `Payload too large` | `请求体过大` |
| 评论默认标题 | `Untitled document` | `未命名文档` |
| 图片/文件下载失败 | 静默丢失或不清楚 | 明确提示失败原因 |
| `/usage`、`/resume` | 桌面式长输出 | 飞书移动端紧凑中文 |
| `/status` | 桌面式长状态 | 飞书移动端紧凑中文状态 |
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
- ✅ 保留原版飞书显示顺序，不牺牲图片/文件、状态和工具调用信息
- ✅ 自动备份，可随时回滚

---

## 功能特性

### 🔤 102 条中文替换和适配规则

覆盖飞书消息占位符、Webhook 错误、CLI 输出、评论系统、媒体失败提示、移动端 `/usage`、`/resume` 和 `/status` 显示等。完整列表见 [汉化规则文档](docs/)。

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
├── patches/             # 配置和源码替换规则
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

A community extension that replaces 77 English outputs with Chinese translations in Hermes Agent's Feishu integration. One-click install, preserves your existing config.

### Quick Install

```powershell
iex (irm https://raw.githubusercontent.com/OLDBAI213/hermes-feishu-zh/main/install.ps1)
```

### Features

- 🔤 77 Chinese translation rules for Feishu messages, webhooks, CLI output
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
