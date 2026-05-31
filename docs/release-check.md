# 发布检查

上次本地验证：2026-05-29

在 Windows + Hermes Agent v0.15.1 上验证通过。

已通过的检查：

- 包结构检查
- PowerShell 语法检查（`install.ps1`、`verify.ps1`、`tests/check-package.ps1`）
- 发布文件中无本地路径或敏感信息
- `install.ps1 -VerifyOnly` 验证现有 Hermes 目录
- `install.ps1 -Profile stable` 安装
- 重复安装不会产生重复配置条目
- `install.ps1 -Rollback latest` 回滚
- 回滚后验证
- `patches/feishu-card-zh.replacements.json` 覆盖 114 条源码汉化规则
- `audit/feishu_localization_audit.py` 和 `audit/feishu_zh_audit_allowlist.yaml` 会随安装同步到目标 Hermes
- 飞书用户可见英文审计通过：`scripts/feishu_localization_audit.py` 的 `unapproved_count = 0`
- Feishu `outbound_format` / `card_mode` 出站路由验收通过：`auto => post`、`text => text`、`post => post`、`card => interactive`

已知说明：

- 远程安装命令中的 `<owner>` 在仓库发布后需替换为实际 GitHub 用户名
- `lark-cli doctor` 显示 `user_identity` 警告是 `bot-only` 绑定的正常现象
- 增强模式会修改 Hermes 源码，Hermes 飞书适配器更新后必须重新验证

## 2026-05-29 复审记录

当前 `E:\AI\hermes\hermes-agent` 为 Hermes Agent v0.15.1。

验证命令：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\verify.ps1 -HermesHome E:\AI\hermes -SkipGateway
```

结果：

- `Source Chinese labels`：114 条规则，missing 0。
- `Feishu localization audit`：用户可见英文未批准项 0；允许保留项已记录原因。
- `lark-cli doctor`：ok，只有 `user_identity` 和 CLI 版本提示为警告。
- `Feishu payload modes`：`auto => post`、`text => text`、`post => post`、`card => interactive`。
- 结论：本机等级 B，可用但缺真实飞书 PC/手机截图验收，暂不标 A。

## 2026-05-21 后续更新交接

当前 `hermes-feishu-zh` 包已经落后于本机 Hermes 的飞书汉化状态。之后让 Hermes 提交更新前，需要先把这些本机改动同步进包里的补丁、验证脚本和测试。

本机最新来源：

- `E:\AI\hermes\hermes-agent\gateway\platformseishu.py`
- `E:\AI\hermes\hermes-agent\gateway\platformseishu_comment.py`
- `E:\AI\hermes\hermes-agent\gateway\platformseishu_comment_rules.py`
- `E:\AI\hermes\hermes-agent	ests\gateway	est_feishu.py`
- `E:\AI\hermes\hermes-agent	ests\gateway	est_feishu_comment.py`
- `E:\AI\hermes\hermes-agent	ests\gateway	est_feishu_comment_rules.py`

需要补进 `hermes-feishu-zh` 的新增内容：

- 飞书消息占位中文：`[富文本消息]`、`[合并转发消息]`、`[共享聊天]`、`[交互消息]`、`[图片]`、`[附件]`、`[表情]`
- webhook / HTTP 错误中文：`请求过于频繁`、`不支持的媒体类型`、`请求体过大`、`请求超时`、`无效 JSON`、`签名无效`、`暂不支持加密 webhook 请求体`
- 文件注入提示中文：`[文件内容: ...]`
- 飞书注册/扫码流程中文：`正在获取配置结果...`、`正在连接 Feishu / Lark...`、二维码提示、`完成。`
- 飞书评论默认标题：`未命名文档`
- `feishu_comment_rules.py` 的 CLI 输出中文：规则文件、配对文件、顶层配置、文档规则、增删命令和未知命令提示

更新包时的验收要求：

- `patches/feishu-card-zh.replacements.json` 覆盖上述新增源码汉化
- `verify.ps1` / `tests/test-zh.py` 能检查新增关键字符串
- 不写入任何本机密钥、用户 ID、token、缓存日志或绝对私密配置
- 在 Hermes 本机跑飞书相关测试后再发布，当前已知通过口径为 `test_feishu.py`、`test_feishu_comment.py`、`test_feishu_comment_rules.py`

## 2026-05-21 更新记录

已同步新增 14 条汉化规则（44→58）：
- 消息占位符：富文本消息、合并转发消息、共享聊天、交互消息、附件、表情
- Webhook 错误：请求过于频繁、不支持的媒体类型、请求体过大、请求超时、无效 JSON、签名无效、暂不支持加密 webhook 请求体
- feishu_comment 默认标题：未命名文档
