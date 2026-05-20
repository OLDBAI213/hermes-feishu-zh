# hermes-feishu-zh

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Hermes Agent](https://img.shields.io/badge/Hermes_Agent-%3E%3D0.14.0-9B59B6.svg)](https://github.com/NousResearch/hermes-agent)
[![Platform](https://img.shields.io/badge/Platform-Windows-blue.svg)](https://github.com/OLDBAI213/hermes-feishu-zh)
[![Feishu](https://img.shields.io/badge/Feishu-中文-4ECDC4.svg)](https://github.com/OLDBAI213/hermes-feishu-zh)

Hermes Agent 社区扩展：飞书中文显示 + lark-cli 工具箱。

这不是 Hermes Agent 官方项目，是社区扩展。帮助 Windows 上的 Hermes 用户一键开启飞书中文显示、稳定的 `post` 输出格式，以及可选的 `lark-cli` 工具箱，不会覆盖你现有的 Hermes 配置。

## 安装

```powershell
iex (irm https://raw.githubusercontent.com/OLDBAI213/hermes-feishu-zh/main/install.ps1)
```

本地安装：

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

默认使用 `stable` 模式，会：

- 将飞书中文显示配置 deep-merge 进 `config.yaml`
- 保留你现有的模型、API、飞书凭证、会话和 `.env` 配置
- 安装并启用 `lark-cli-toolbox` 插件
- 使用飞书 `post` 输出格式，稳定显示 Markdown
- 安装前自动备份
- 安装后自动验证

## 增强模式

增强模式会额外补丁 Hermes 飞书源码，支持更丰富的卡片输出。

```powershell
iex (irm https://raw.githubusercontent.com/OLDBAI213/hermes-feishu-zh/main/install.ps1) -Profile enhanced
```

增强模式会修改源码，Hermes 升级后可能需要重新打补丁。安装器会自动备份原文件并验证结果。

## 验证

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -VerifyOnly
```

或：

```powershell
powershell -ExecutionPolicy Bypass -File .\verify.ps1
```

验证检查包括：Hermes CLI、飞书显示配置、源码中文标签、`lark-cli` 插件、飞书输出模式、Gateway 连接状态。

## 回滚

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Rollback latest
```

备份存放在：

```text
<HERMES_HOME>\backups\hermes-feishu-zh-<timestamp>
```

## 卸载

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Uninstall
```

会执行：

- 删除 `lark-cli-toolbox` 插件
- 清理 config.yaml（移除 lark_cli 工具集、重置显示设置）
- 从备份恢复源码文件（如有）

卸载后重启 Gateway：

```powershell
hermes gateway restart
```

## 环境要求

- Windows PowerShell 或 PowerShell 7
- Hermes Agent 已安装且正常运行
- `HERMES_HOME` 已设置，或通过 `hermes.exe` 能找到 Hermes
- 飞书 Gateway 已在 Hermes 中配置
- 可选：`lark-cli` 已安装并绑定到 Hermes（用于工具箱功能）

绑定 `lark-cli`：

```powershell
lark-cli config bind --source hermes --identity bot-only
```

`bot-only` 即可用于机器人 API 访问。个人日历、私有文档等用户级资源可能需要后续配置用户登录。

## 修改范围

安装器可能修改：

- `<HERMES_HOME>\config.yaml`
- `<HERMES_HOME>\plugins\lark-cli-toolbox`
- `<HERMES_HOME>\hermes-agent\gateway\platforms\feishu.py`

不包含也不传输 API 密钥、飞书密钥、用户 ID、会话或令牌。

## 文档

- [安装指南](docs/install.md)
- [升级说明](docs/upgrade.md)
- [故障排除](docs/troubleshooting.md)
