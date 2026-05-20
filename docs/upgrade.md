# 升级说明

安装器是幂等的。重复运行不会重复添加 `plugins.enabled`、`platform_toolsets` 或 `toolsets` 条目。

## 更新本扩展

如果通过 git checkout 安装：

```powershell
git pull --ff-only
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

如果使用一键远程安装命令，仓库更新后重新运行相同的安装命令即可。

## Hermes 升级后

先运行验证：

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -VerifyOnly
```

如果验证失败（源码补丁标记位置变化），重新安装 stable 模式：

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Profile stable
```

确认新版 Hermes 支持后再使用 enhanced 模式。

## 回滚

恢复最新的备份：

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Rollback latest
```

备份存放在：

```text
<HERMES_HOME>\backups\hermes-feishu-zh-<timestamp>
```

每个备份包含 `backup-manifest.json` 和安装前的原始文件。

## 兼容性说明

- stable 模式使用配置和插件接口，通常能承受 Hermes 正常升级
- enhanced 模式在 Hermes 修改 `gateway/platforms/feishu.py` 后可能需要重新打补丁
- 本仓库不存储密钥。现有的 `.env` 值保留在用户的 Hermes 目录中
