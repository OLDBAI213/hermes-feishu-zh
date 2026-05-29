# hermes-feishu

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Hermes Agent](https://img.shields.io/badge/Hermes_Agent-%3E%3D0.14.0-9B59B6.svg)](https://github.com/NousResearch/hermes-agent)
[![Feishu](https://img.shields.io/badge/Feishu-%E4%B8%AD%E6%96%87-4ECDC4.svg)](https://github.com/OLDBAI213/hermes-feishu-zh)

> **Hermes Agent 飞书全套件。** 中文化、显示增强、媒体适配、工具进度、结构化输出，一键安装。

---

## 这是什么

hermes-feishu 把原来分散在三个仓库的功能合并成一个包：

| 功能 | 说明 |
|------|------|
| 🇨🇳 **中文化** | 114 条规则，覆盖飞书消息、Webhook 错误、CLI 输出、评论系统 |
| 📊 **显示增强** | 工具调用记录、三状态显示、结构化正文、移动端可读性 |
| 📎 **媒体适配** | 图片/文件/音视频/混合消息/队列/下载失败诊断 |

---

## 一键安装

```powershell
iex (irm https://raw.githubusercontent.com/OLDBAI213/hermes-feishu-zh/main/bootstrap.ps1)
```

安装器会：
- ✅ 将中文配置合并到 `config.yaml`（保留你现有配置）
- ✅ 安装 `lark-cli-toolbox` 插件
- ✅ 设置飞书 `post` 输出格式（稳定显示 Markdown）
- ✅ 应用媒体适配补丁（图片/文件/音视频正确处理）
- ✅ 自动备份，可随时回滚

---

## 安装前 vs 安装后

| 场景 | 安装前 | 安装后 |
|------|--------|--------|
| 消息占位符 | `[Rich text message]` | `[富文本消息]` |
| Webhook 错误 | `Rate limit exceeded` | `请求过于频繁` |
| 工具调用 | 碎片散落 | 🧰 工具调用记录（编号聚合） |
| 收到消息 | 无反馈 | `已收到，正在思考...` |
| 图片/文件 | 静默丢失或不清楚 | 明确中文提示失败原因 |
| 长时间任务 | 看不到进度 | 已用时间、轮次、当前活动 |

---

## 模块说明

### 中文化核心 (zh)
- 114 条中文化规则
- 飞书消息、Webhook 错误、CLI 输出
- 评论系统中文化
- lark-cli 工具箱

### 显示增强 (display)
- 工具调用记录（编号聚合）
- 三状态显示（思考中/工具调用/完成）
- 结构化正文
- 桌面端和移动端可读性

### 媒体适配 (adapter)
- 图片/文件输入处理
- 混合消息支持
- 队列媒体安全
- 下载失败诊断

---

## 从旧仓库迁移

如果你之前安装了以下仓库，可以迁移到 hermes-feishu：

| 旧仓库 | 新位置 |
|--------|--------|
| hermes-feishu-zh | ✅ 已合并 |
| hermes-feishu-display-plus | ✅ 已合并 |
| hermes-feishu-adapter-optimization | ✅ 已合并 |

迁移方法：重新运行安装脚本即可，它会自动检测并升级。

---

## 验证

```powershell
powershell -ExecutionPolicy Bypass -File .\verify.ps1
```

---

## 回滚

```powershell
.\install.ps1 -Rollback latest
```

---

## 卸载

```powershell
.\install.ps1 -Uninstall
```

---

## 许可证

MIT License

---

## 相关项目

- [Hermes Agent](https://github.com/NousResearch/hermes-agent) — AI Agent 框架
- [hermes-feishu-zh](https://github.com/OLDBAI213/hermes-feishu-zh) — 本项目（旧仓库，已归档）
