# hermes-feishu-zh v0.20.0 汉化移植 — 方案与进度记录

工作区：`AI/feishu-zh-v20/`（Desktop 下，用户指定）
目标源码：Hermes Agent v0.20.0 (2026.8.3)，commit `1be70d6`
汉化包原仓库：v0.2.3（适配到 Hermes v0.15.1）
创建日期：2026-08-05

---

## 一、背景

Hermes 已于 2026-08-05 从 v0.18.2 升级到 v0.20.0。飞书实现从旧路径
`gateway/platforms/feishu.py` 重构为 `plugins/platforms/feishu/`
（adapter.py + feishu_comment.py + feishu_comment_rules.py + feishu_meeting_invite.py）。
原汉化包 114 条替换规则全部指向旧文件，已全部失效。

本次任务：**在原有汉化包基础上，把飞书中文化移植/适配到 v0.20.0 新结构，并做优化。**

## 二、结构说明

```
ai/feishu-zh-v20/
├── README-方案.md          ← 本文件（方案+进度）
├── 04_运行记录.md          ← 每一步实际操作记录（证据）
├── audit/                  ← 审计脚本与产出
│   ├── feishu_localization_audit.py
│   ├── feishu_zh_audit_v18_allowlist.yaml
│   └── out/                ← 生成报告
│       ├── REPORT_v20.0.md     （完整缺口审计 125 处）
│       ├── V20_RESEARCH.md     （研判清单：可复用/需新翻/误报）
│       └── v20_audit.json      （机器可读 JSON）
├── patches/                ← 替换规则（改造中）
│   ├── feishu-card-zh.replacements.json     （114 条，需迁移到 v0.20.0）
│   └── feishu-display-upgrade.replacements.json （显示增强）
├── plugins/lark-cli-toolbox/  ← 需装回 v0.20.0
├── install.ps1 / verify.ps1   ← 需适配新路径
└── tests/                   ← 测试（先测试后写码）
```

## 三、缺口研判结论（自动 + 抽查验证）

125 处未中文化 = **可复用旧翻译 55 + 需新翻译 67 + 误报 3**

| 文件 | 缺口 | 说明 |
|---|---|---|
| plugins/platforms/feishu/adapter.py | 80 | 主适配器，含 55 处可复用 中的大部分 |
| plugins/platforms/feishu/feishu_comment_rules.py | 33 | 评论规则 CLI 输出，多可复用 |
| plugins/platforms/feishu/feishu_meeting_invite.py | 9 | 全新文件，全部需新翻 |
| plugins/platforms/feishu/feishu_comment.py | 3 | 实体转义，误报为主 |

额外发现：v0.20.0 的 `_APPROVAL_LABEL_MAP` 多了 `"deny": "Denied"` 键（旧翻译没有）。

## 四、执行计划（分批）

- [x] Step 0：现状盘点、审计脚本运行、缺口研判报告生成
- [x] Step 1：迁移「可复用旧翻译」55 处到 v0.20.0 新文件（改 file 路径 + 更新上下文）
- [x] Step 2：新增翻译 67 处（会议邀请、登录 QR、webhook 错误、fallback 占位符等）
- [x] Step 3：补 `_APPROVAL_LABEL_MAP.deny` 等遗漏 + 处理误报（allowlist 豁免）
- [x] Step 4：lark-cli 安装 + lark-cli-toolbox 插件装回 + config 适配 + user-default 绑定授权
- [x] Step 5：适配 install.ps1 / verify.ps1 / manifest.json 到 v0.20.0 新路径
- [x] Step 6：应用 102 条规则到真实 Hermes 源码（备份）+ verify.ps1 全量通过
- [x] Step 7：更新 CHANGELOG / manifest 版本号（v0.3.0），提交推送回 GitHub

> **最终进度（2026-08-05 22:00，全部完成）**：
> - **中文化 102 条**已应用到真实 Hermes 源码（adapter 59 + comment_rules 34 + meeting_invite 9），
>   语法通过、审计 unapproved=0。
> - **显示优化**：display.platforms.feishu config（streaming/tool_progress/tool_preview_length/runtime_footer）
>   + post payload title 增强，已在真实环境生效。
> - **lark-cli**：v1.0.83 安装 + lark-cli-toolbox 插件启用（12工具）+ user-default 绑定 + 设备授权完成
>   （用户 焦富桐），doctor 全绿。
> - **兼容优化**：adapter-optimization/media/don-image-routing 等能力 v0.20.0 已原生覆盖，验证后不重复打补丁。
> - **verify.ps1 全量通过**：`hermes-feishu-zh verification passed.`（gateway running, feishu connected）。
> - **仓库**：v0.3.0（README/manifest/CHANGELOG 已对齐），GitHub 已推送（最新 commit `b31ef38`）。

## 五、铁律（来自 AGENTS.md）

1. 先测试后写码 — 有失败测试才写实现
2. 完成前必须验证 — 跑 verify.ps1 通过才算完成
3. 中文优先 — 用户可见内容中文，代码/命令/路径英文
4. 备份再改 — 改 config/源码前备份
5. 不提交 API key / 敏感信息

## 六、源代码位置

- 汉化包代码：本工作区 `AI/feishu-zh-v20/`
- Hermes 目标源码：`C:\Users\Administrator\AppData\Local\hermes\hermes-agent\plugins\platforms\feishu\`
- 注意：汉化包以「替换规则」形式工作，不直接改 Hermes 源码目录；规则存于本工作区 `patches/`
