# hermes-feishu-zh

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Hermes Agent](https://img.shields.io/badge/Hermes_Agent-v0.20.0-9B59B6.svg)](https://github.com/NousResearch/hermes-agent)
[![Feishu](https://img.shields.io/badge/Feishu-%E4%B8%AD%E6%96%87-4ECDC4.svg)](https://github.com/OLDBAI213/hermes-feishu-zh)
[![Version](https://img.shields.io/badge/version-0.4.0-blue.svg)](https://github.com/OLDBAI213/hermes-feishu-zh/releases)

> **让 Hermes Agent 在飞书里说中文，并把真实运行过程清楚地显示出来。** 适配 Hermes Agent v0.20.0。

---

## 2026-08-05 适配结论

本包已适配 **Hermes Agent v0.20.0 (2026.8.3)**。Hermes 飞书源码从旧的 `gateway/platforms/feishu.py`
重构为 `plugins/platforms/feishu/{adapter,feishu_comment,feishu_comment_rules,feishu_meeting_invite}.py`，
原 114 条规则已重写为 **102 条 v0.20.0 兼容规则**。

- `verify.ps1` 已适配 v0.20.0：移除废弃配置检查（`gateway_locale`/`outbound_format`/`card_mode`），
  改用「飞书平台实际解析 toolset」验证。
- 当前结果：中文化 102 条全部应用、飞书用户可见英文审计 `unapproved=0`、Config/Plugin/lark-cli 检查通过。
- 审计脚本已作为标准安装内容落位（`scripts/feishu_localization_audit.py` + `locales/feishu_zh_audit_allowlist.yaml`）。
- 飞书实时显示已按 Hermes `1be70d6` 专项适配：一张状态卡持续编辑、一张执行过程卡累积真实工具事件，最终回复独立发送。
- 模型、服务商和上下文占用从当前 agent 读取；没有真实 token 数据时不显示上下文，不填假值。
- 适配优化（media mirror / image_input_mode / image routing / media_refs）已被 v0.20.0 原生吸收，不重复打补丁。

---

## 痛点

Hermes Agent 默认在飞书里输出英文 — 错误信息看不懂、界面元素是英文、Webhook 报错全是英文。对于中文用户来说，每次看到 `[Rich text message]`、`Rate limit exceeded` 这些提示都很懵。

## 解决方案

**hermes-feishu-zh** 是一个社区扩展。它把 102 处飞书输出整理成中文，提供 `lark-cli` 工具箱，并把 Hermes 的真实运行阶段和工具事件整理成紧凑的飞书消息。

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
- ✅ 安装实时状态渲染器并应用 v0.20.0 显示补丁
- ✅ 关闭重复 footer、长任务提醒和中途碎片消息
- ✅ 保留图片、文件和最终回复的原生发送路径
- ✅ 自动备份，可随时回滚

---

## 功能特性

### 🔤 102 条中文化规则（v0.20.0）

覆盖飞书消息占位符、Webhook 错误、CLI 输出、评论系统、会议邀请、媒体失败提示、`/usage`、`/resume` 和 `/status` 等用户可见文案。完整列表见 [汉化规则文档](docs/)。

### 🧾 汉化总账

本机 Hermes 现在增加了飞书用户可见英文审计：`scripts/feishu_localization_audit.py` 会扫描飞书相关源码，只有未翻译英文为 `0` 才算通过；允许保留的英文必须写在 `locales/feishu_zh_audit_allowlist.yaml` 并说明原因。

### 实时显示

- 状态卡：收到消息后创建一次，随思考、执行、整理回复、完成或失败阶段原地更新。
- 执行过程卡：只记录 Hermes 实际发出的工具开始、完成和失败事件，按发生顺序编号并在同一张消息里更新。
- 最终回复：独立发送，不重复模型、上下文或工作目录。
- 降噪：编辑失败时不补发孤立工具气泡，不发送周期性长任务提醒。

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

### 增强模式（可选）

稳定版和增强版都启用实时显示；增强版只把工具预览长度从 120 提高到 180。两者都使用同一套 v0.20.0 源码补丁和回滚机制。

---

## 快速命令

| 操作 | 命令 |
|------|------|
| **安装** | `iex (irm https://raw.githubusercontent.com/OLDBAI213/hermes-feishu-zh/main/bootstrap.ps1)` |
| **验证** | `pwsh -NoProfile -File .\verify.ps1` |
| **回滚** | `pwsh -NoProfile -File .\install.ps1 -Rollback latest` |
| **卸载** | `pwsh -NoProfile -File .\install.ps1 -Uninstall` |

---

## 飞书套件

当前仓库已经包含中文化与本项目需要的实时显示能力：

| 包 | 定位 | 说明 |
|----|------|------|
| **hermes-feishu-zh** | 中文化 | 基础包，必装 |
| **本仓库实时显示补丁** | 显示增强 | 实时状态、工具调用记录、独立最终回复 |
| [hermes-feishu-adapter-optimization](https://github.com/OLDBAI213/hermes-feishu-adapter-optimization) | 适配优化 | 图片、文件、音视频、忙碌队列 |

项目边界：
- 本项目负责：飞书中文化、实时状态/工具过程显示、配置合并、`lark-cli-toolbox`、安装/验证/回滚。
- `hermes-feishu-adapter-optimization` 负责：图片、文件、混合消息、忙碌队列、上下文连续性等飞书适配能力。
- 任何项目都不能拆东墙补西墙：中文化不能打乱原版显示，显示优化不能丢图片、文件、状态和工具调用信息，适配优化不能改变用户已有配置。

---

## 环境要求

- PowerShell 7（`pwsh`）；旧 Windows PowerShell 5.1 不支持本包的 UTF-8 脚本
- Hermes Agent v0.20.0 已安装
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
