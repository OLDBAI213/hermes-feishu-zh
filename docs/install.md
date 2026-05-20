# 安装指南

`hermes-feishu-zh` 面向 Windows 平台，需要先安装好 Hermes Agent。

## 在线安装

发布后将 `<owner>` 替换为 GitHub 仓库所有者：

```powershell
iex (irm https://raw.githubusercontent.com/OLDBAI213/hermes-feishu-zh/main/install.ps1)
```

## 本地安装

从本仓库：

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

## 参数选项

稳定模式（默认）：

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Profile stable
```

增强模式：

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Profile enhanced
```

仅验证：

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -VerifyOnly
```

回滚：

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Rollback latest
```

安装后重启 Gateway：

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -RestartGateway
```

卸载：

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Uninstall
```

## 模式说明

`stable` 是默认模式。它会合并配置、安装 `lark-cli-toolbox` 插件，并使用飞书 `post` 输出格式。

`enhanced` 会额外补丁 Hermes 飞书源码，让普通回复也能使用交互式卡片输出。仅在你接受 Hermes 升级后可能需要重新打补丁的情况下使用。

## lark-cli 绑定

插件可以不依赖 `lark-cli` 加载，但工具需要 CLI 安装并绑定才能使用：

```powershell
lark-cli config bind --source hermes --identity bot-only
```

`bot-only` 足够用于机器人/应用 API 访问。个人日历、私有文档等用户级资源可能需要后续配置用户登录。
