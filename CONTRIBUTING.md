# 贡献指南

欢迎提交 Issue 和 Pull Request！

## 开发环境

- Windows PowerShell 或 PowerShell 7
- Hermes Agent 已安装
- Python 3.11+（用于配置合并脚本）

## 本地开发

```powershell
# 克隆仓库
git clone https://github.com/OLDBAI213/hermes-feishu-zh.git
cd hermes-feishu-zh

# 运行包检查
powershell -ExecutionPolicy Bypass -File .\tests\check-package.ps1

# 运行中文化测试
$env:HERMES_HOME = "你的Hermes目录"
python tests/test-zh.py
```

## 提交 PR

1. Fork 本仓库
2. 创建特性分支：`git checkout -b feature/my-feature`
3. 提交更改
4. 推送到你的 Fork：`git push origin feature/my-feature`
5. 创建 Pull Request

## 测试

```powershell
# 完整测试
python tests/test-zh.py

# 只测试配置
python tests/test-zh.py --config

# 只测试源码替换
python tests/test-zh.py --source

# 只测试插件
python tests/test-zh.py --plugin
```

## 注意事项

- 不要提交 API 密钥、飞书密钥或任何敏感信息
- 增强模式的源码补丁需要同时更新 `patches/feishu-display-upgrade.replacements.json`
- 新增的中文字符串需要同步更新到 `patches/feishu-card-zh.replacements.json`
