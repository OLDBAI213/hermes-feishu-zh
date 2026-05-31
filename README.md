# hermes-feishu-zh

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Hermes Agent](https://img.shields.io/badge/Hermes_Agent-%3E%3D0.14.0-9B59B6.svg)](https://github.com/NousResearch/hermes-agent)
[![Feishu](https://img.shields.io/badge/Feishu-%E4%B8%AD%E6%96%87-4ECDC4.svg)](https://github.com/OLDBAI213/hermes-feishu-zh)
[![Version](https://img.shields.io/badge/version-0.2.3-blue.svg)](https://github.com/OLDBAI213/hermes-feishu-zh/releases)

> **让 Hermes Agent 在飞书里说中文。** 一键安装，114 条中文化规则，不改你现有配置。

---

## 2026-05-29 复审结论

当前 `E:\AI\hermes\hermes-agent` 已更新到 Hermes Agent v0.15.1。基础配置、插件、源码中文化规则和 Feishu 出站模式已按当前 Hermes 重新适配。

- `verify.ps1` 已修复 PowerShell 误报：Python 子检查失败时现在会直接失败，不再继续打印“verification passed”。
- 当前复审命令：`pwsh -ExecutionPolicy Bypass -File E:\AI\github\hermes-feishu-zh\verify.ps1 -HermesHome E:\AI\hermes -SkipGateway`。
- 当前结果：配置、插件、`lark-cli doctor`、114 条源码中文化规则、飞书用户可见英文审计、`text/post/card` 出站模式检查全部通过。

结论：本包在老白本机 Hermes v0.15.1 上可用，等级 B。还不能升到 A，因为没有补真实飞书 PC/手机截图验收，也还没有把审计脚本作为通用安装内容发布。

---

## 痛点

Hermes Agent 默认在飞书里输出英文 — 错误信息看不懂、界面元素是英文、Webhook 报错全是英文。对于中文用户来说，每次看到 `[Rich text message]`、`Rate limit exceeded` 这些提示都很懵。

## 解决方案

**hermes-feishu-zh** 是一个社区扩展，定位是"飞书中文化包"。它把 114 处飞书输出整理成中文，同时提供稳定的 `post` 输出格式和 `lark-cli` 工具箱。

### 安装前 vs 安装后

| 场景 | 安装前 | 安装后 |
|------|--------|--------|
| 消息占位符 | `[Rich text message]` | `[富文本消息]` |
| Webhook 错误 | `Rate limit exceeded` | `请求过于频繁` |
| Webhook 错误 | `Payload too large` | `请求体过大` |
| 评论默认标题 | `Untitled document` | `未命名文档` |
| 图片/文件下载失败 | 静默丢失或不清楚 | 明确中文提示失败原因 |
| `/usage`、`/resume` | 英文或半英文状态 | 中文状态说明 |
| `/status` | 英文或半英文状态 | 中文状态说明 |
| CLI 输出 | 英文规则描述 | 中文规则描述 |

---

## 一键安装

```powershell
iex (irm https://raw.githubusercontent.com/OLDBAI213/hermes-feishu-zh/main/bootstrap.ps1)
```

安装器会：
- ✅ 将中文配置合并到 `config.yaml`（保留你现有配置）
- ✅ 安装 `lark-cli-toolbox` 插件
- ✅ 设置飞书 `post` 输出格式（稳定显示 Markdown）
- ✅ 保留原版飞书显示顺序，不牺牲图片/文件、状态和工具调用信息
- ✅ 自动备份，可随时回滚

---

## 功能特性

### 🔤 114 条中文化规则

覆盖飞书消息占位符、Webhook 错误、CLI 输出、评论系统、媒体失败提示、`/usage`、`/resume` 和 `/status` 等用户可见文案。完整列表见 [汉化规则文档](docs/)。

### 🧾 汉化总账

本机 Hermes 现在增加了飞书用户可见英文审计：`scripts/feishu_localization_audit.py` 会扫描飞书相关源码，只有未翻译英文为 `0` 才算通过；允许保留的英文必须写在 `locales/feishu_zh_audit_allowlist.yaml` 并说明原因。

### 📦 lark-cli 工具箱

飞书 API 命令行工具，支持文档操作、消息管理、日历查询等。中文输出。

```bash
# 示例：查询日历
lark-cli calendar agenda

# 示例：搜索文档
lark-cli docs search "关键词"

# 示例：发送消息
lark-cli messages send --chat "oc_xxx" --text "你好"
```

### 🛡️ 安全安装

- 安装前自动备份
- 不修改 API 密钥、飞书凭证、用户 ID
- 可一键回滚、一键卸载

### 🔄 增强模式（可选）

额外补丁 Hermes 源码，补齐更多中文化标记。增强显示、美化和适配能力会拆到独立项目，不在这个包里继续混写。

---

## 快速命令

| 操作 | 命令 |
|------|------|
| **安装** | `iex (irm https://raw.githubusercontent.com/OLDBAI213/hermes-feishu-zh/main/bootstrap.ps1)` |
| **验证** | `powershell -ExecutionPolicy Bypass -File .\verify.ps1` |
| **回滚** | `powershell -ExecutionPolicy Bypass -File .\install.ps1 -Rollback latest` |
| **卸载** | `powershell -ExecutionPolicy Bypass -File .\install.ps1 -Uninstall` |

---

## 飞书套件

这是 **hermes-feishu-zh**，飞书套件的基础包。完整飞书体验需要安装套件的三个包：

| 包 | 定位 | 说明 |
|----|------|------|
| **hermes-feishu-zh** | 中文化 | 基础包，必装 |
| [hermes-feishu-display-plus](https://github.com/OLDBAI213/hermes-feishu-display-plus) | 显示增强 | 工具调用记录、状态显示、结构化正文 |
| [hermes-feishu-adapter-optimization](https://github.com/OLDBAI213/hermes-feishu-adapter-optimization) | 适配优化 | 图片、文件、音视频、忙碌队列 |

项目边界：
- 本项目负责：飞书中文化、配置合并、`lark-cli-toolbox`、安装/验证/回滚。
- `hermes-feishu-display-plus` 负责：工具记录、状态栏、结构化正文等显示优化。
- `hermes-feishu-adapter-optimization` 负责：图片、文件、混合消息、忙碌队列、上下文连续性等飞书适配能力。
- 任何项目都不能拆东墙补西墙：中文化不能打乱原版显示，显示优化不能丢图片、文件、状态和工具调用信息，适配优化不能改变用户已有配置。

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
├── audit/               # 飞书用户可见英文审计脚本和白名单
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
