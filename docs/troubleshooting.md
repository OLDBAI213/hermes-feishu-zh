# 故障排除

## 找不到 Hermes 目录

设置 `HERMES_HOME` 或通过参数指定：

```powershell
$env:HERMES_HOME = "C:\Users\<你的用户名>\.hermes"
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

## lark-cli doctor 失败

将 `lark-cli` 绑定到 Hermes 飞书应用：

```powershell
lark-cli config bind --source hermes --identity bot-only
```

如果只显示 `user_identity` 警告，机器人身份仍可使用。个人文档、日历等用户级资源可能需要配置用户登录。

## Gateway 状态异常

在 Windows 上，Scheduled Task 结果可能在进程分离或停止后显示非零值。建议使用以下命令检查：

```powershell
hermes gateway status
Get-Content "$env:HERMES_HOME\gateway_state.json"
```

正常状态应为 `gateway_state = running` 且 `platforms.feishu.state = connected`。

## 增强模式补丁失败

使用 stable 模式：

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Profile stable
```

增强模式会修改 Hermes 源码。如果 Hermes 更新了飞书适配器，替换标记可能不再匹配。

## 中文显示未生效

运行验证脚本：

```powershell
powershell -ExecutionPolicy Bypass -File .\verify.ps1
```

检查配置是否正确合并、插件是否加载、源码标签是否替换成功。
