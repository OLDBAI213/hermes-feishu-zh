# 别再忍受英文飞书了！Hermes Agent 中文化一键搞定

> **🚀 项目地址：[https://github.com/OLDBAI213/hermes-feishu-zh](https://github.com/OLDBAI213/hermes-feishu-zh)**
> 
> ⭐ 如果对你有帮助，点个 Star 支持一下

## 痛点：飞书里的英文看得头疼

你是不是也遇到过这种情况：

在飞书里跟 Hermes Agent 对话，突然弹出一个审批框：

```
⚠️ Command Approval Required
✅ Allow Once    ✅ Session    ✅ Always    ❌ Deny
```

一脸懵逼——这些按钮是什么意思？点错了怎么办？

或者更糟，明明配置了 `FEISHU_ALLOWED_USERS`，结果日志里显示：

```
WARNING gateway.run: Unauthorized user: 3b8g3185 (焦富桐) on feishu
```

配了也不让用？？？

## 解决方案：一行命令搞定

```powershell
iex (irm https://raw.githubusercontent.com/OLDBAI213/hermes-feishu-zh/main/install.ps1)
```

**👉 项目地址：[https://github.com/OLDBAI213/hermes-feishu-zh](https://github.com/OLDBAI213/hermes-feishu-zh)**

安装后，所有英文界面变成中文：

| 安装前 | 安装后 |
|--------|--------|
| `✅ Allow Once` | `✅ 仅本次` |
| `❌ Deny` | `❌ 拒绝` |
| `send failed` | `发送失败` |
| `Not connected` | `未连接` |
| `⚕ Update Needs Your Input` | `⚕ 更新需要你确认` |

## 它到底做了什么？

这个扩展做了 4 件事：

### 1. 配置合并（不破坏你现有的配置）

把飞书中文显示配置写入 `config.yaml`，但保留你现有的 API key、模型配置、飞书凭证等。

### 2. 安装 lark-cli 工具箱（12 个飞书工具）

- 文档搜索/读取
- 消息搜索
- 任务管理
- 日历查询
- 多维表格查询
- ...

### 3. 源码中文化（44 条替换规则）

把 `feishu.py` 和 `run.py` 里的英文标签替换成中文。

### 4. 自动备份 + 一键回滚

安装前自动备份，出问题了：

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Rollback latest
```

## 踩坑记录：Feishu 鉴权问题

这个坑我一定要分享出来，因为官方文档没写清楚。

### 问题

飞书有三种用户 ID：
- `open_id`（app-scoped）：每个应用不同
- `user_id`（tenant-scoped）：公司内稳定
- `union_id`（developer-scoped）：开发者维度

`hermes gateway setup` 写入的是 `open_id`（比如 `ou_737e5de120c44084850daf3483098ec1`），但运行时用 `user_id` 做鉴权（比如 `3b8g3185`）。

结果：配置了允许列表，但用户还是被拒绝。

### 解决

在 `.env` 里同时写入两个 ID：

```bash
FEISHU_ALLOWED_USERS=ou_xxxxx,3b8g3185
```

### 怎么找到你的 user_id？

看 gateway 日志：

```
[Feishu] Inbound dm message received: ... sender=user:ou_xxxxx ...
WARNING gateway.run: Unauthorized user: 3b8g3185 (你的名字) on feishu
```

那个 `3b8g3185` 就是你的 user_id。

我已经在 Hermes 官方仓库提了 issue：[NousResearch/hermes-agent#26183](https://github.com/NousResearch/hermes-agent/issues/26183)

## 两种模式怎么选？

| 模式 | 改什么 | 安全性 | 升级影响 |
|------|--------|--------|----------|
| **Stable**（默认） | 只改配置 | ✅ 安全 | 不受影响 |
| **Enhanced** | 改配置 + 改源码 | ⚠️ 有风险 | 可能需要重新打补丁 |

**建议**：先用 Stable，觉得不够再切 Enhanced。

## 卸载

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Uninstall
```

## 项目结构

```
hermes-feishu-zh/
├── install.ps1              # 安装器（安装/卸载/回滚/验证）
├── verify.ps1               # 验证脚本
├── patches/
│   ├── stable.config.yaml           # stable 模式配置
│   ├── enhanced.config.yaml         # enhanced 模式配置
│   ├── feishu-card-zh.replacements.json  # 44 条中文替换规则
│   └── feishu-display-upgrade.replacements.json
├── plugins/
│   └── lark-cli-toolbox/    # 12 个飞书工具
├── docs/                    # 中文文档
└── tests/                   # 测试脚本
```

## 相关链接

| 链接 | 说明 |
|------|------|
| **[hermes-feishu-zh](https://github.com/OLDBAI213/hermes-feishu-zh)** | 👈 本项目 |
| [Hermes Agent](https://github.com/NousResearch/hermes-agent) | 官方仓库（159k+ stars） |
| [lark-cli](https://github.com/larksuite/cli) | 飞书 CLI 工具 |
| [Issue #26183](https://github.com/NousResearch/hermes-agent/issues/26183) | 鉴权问题讨论 |
| [awesome-hermes-agent](https://github.com/0xNyk/awesome-hermes-agent) | Hermes 生态资源汇总 |

---

*这是一个社区项目，不是 Hermes 官方出品。欢迎提 [Issue](https://github.com/OLDBAI213/hermes-feishu-zh/issues) 和 [PR](https://github.com/OLDBAI213/hermes-feishu-zh/pulls)。*
