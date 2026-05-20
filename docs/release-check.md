# 发布检查

上次本地验证：2026-05-20

在 Windows + Hermes Agent v0.14.0 上验证通过。

已通过的检查：

- 包结构检查
- PowerShell 语法检查（`install.ps1`、`verify.ps1`、`tests/check-package.ps1`）
- 发布文件中无本地路径或敏感信息
- `install.ps1 -VerifyOnly` 验证现有 Hermes 目录
- `install.ps1 -Profile stable` 安装
- 重复安装不会产生重复配置条目
- `install.ps1 -Rollback latest` 回滚
- 回滚后验证

已知说明：

- 远程安装命令中的 `<owner>` 在仓库发布后需替换为实际 GitHub 用户名
- `lark-cli doctor` 显示 `user_identity` 警告是 `bot-only` 绑定的正常现象
- 增强模式会修改 Hermes 源码，Hermes 飞书适配器更新后需重新验证
