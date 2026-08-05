# 交接 / 检查要点 — hermes-feishu-zh v0.3.0 适配 v0.20.0

生成：2026-08-05 22:10
目的：供 Codex 或后续维护者独立检查本次飞书汉化适配工作
工作区：`Desktop/AI/feishu-zh-v20/`
GitHub：`OLDBAI213/hermes-feishu-zh`，版本 v0.3.0（最新 commit `b31ef38`）

---

## 一、这次改了什么（一句话）

把 hermes-feishu-zh 汉化包从适配 Hermes v0.15.1 全面升级到 Hermes v0.20.0：
飞书源码重构从 `gateway/platforms/feishu.py` → `plugins/platforms/feishu/`，
原 114 条失效规则重写为 102 条 v0.20.0 新规则，并完成显示优化、lark-cli 集成、verify 适配。

## 二、关键文件清单

| 文件 | 作用 |
|------|------|
| `patches/feishu-zh-v20.replacements.json` | **102 条 v0.20.0 中文化规则**（adapter 59 + comment_rules 34 + meeting_invite 9） |
| `patches/display-plus-v20.replacements.json` | 显示优化补丁（post payload 加 title） |
| `patches/display-plus/stable.config.yaml` | 显示优化 config（v0.20.0 有效结构） |
| `audit/feishu_zh_audit_v18_allowlist.yaml` | 审计白名单（新增正则/类型/HTML实体豁免） |
| `install.ps1` | 改：主规则指向 v20 文件 |
| `verify.ps1` | 改：Config 检查移除废弃项、Feishu adapter build 改 importlib |
| `manifest.json` | 改：version 0.3.0、source_optional 新路径、version_range>=0.20.0 |
| `README.md` / `CHANGELOG.md` | 对齐 v0.3.0 状态 |
| `04_运行记录.md` | **完整操作证据链 R1-R13** |
| `05_套件研究_TRIAGE.md` | 三套件→v0.20.0 能力映射与最终判定 |

## 三、验证证据（已跑，全过）

1. **中文化审计**：`python scripts/feishu_localization_audit.py --root <hermes-agent>` → `unapproved: 0`（allowed 1879 / ignored 140 / translated 24）
2. **语法**：改过的 adapter.py / comment_rules.py / meeting_invite.py py_compile 全过
3. **verify.ps1 全量**：`hermes-feishu-zh verification passed.`
   - Config：language=zh、lark-cli-toolbox 插件、lark_cli toolsets、飞书平台 toolset 解析——全 True
   - Source Chinese labels：102 条，0 missing
   - Audit：unapproved=0
   - Plugin：lark-cli-toolbox loaded，12 工具注册
   - lark-cli doctor：cli_version/config_file/app_resolved/identity_ready/endpoint 全 pass
   - Gateway：running，feishu connected

## 四、Codex 检查要点（建议逐项核对）

### A. 中文化真的在源码里生效？
```bash
grep -c "未连接" <hermes>/hermes-agent/plugins/platforms/feishu/adapter.py   # 应>0
grep -c "Not connected" <hermes>/hermes-agent/plugins/platforms/feishu/adapter.py  # 应=0
```
（源码实际路径：`C:\Users\Administrator\AppData\Local\hermes\hermes-agent\plugins\platforms\feishu\`）

### B. 102 条规则 find 能命中源文件？
```bash
cd <hermes-agent>
python -c "import json; r=json.load(open(r'Desktop/AI/feishu-zh-v20/patches/feishu-zh-v20.replacements.json')); [open(''.join(x['file']),encoding='utf-8').read() for x in r]"  # 无异常=可命中
```

### C. 审计脚本/白名单已装？
- `<hermes>/hermes-agent/scripts/feishu_localization_audit.py`
- `<hermes>/hermes-agent/locales/feishu_zh_audit_allowlist.yaml`

### D. lark-cli 集成状态
- `lark-cli doctor` → 全 pass
- `lark-cli config show` → workspace hermes，appId cli_a958aefa86389cc0，defaultAs user
- 绑定文件：`C:\Users\Administrator\.lark-cli\hermes\config.json`
- 插件：`hermes plugins list` 显示 lark-cli-toolbox enabled；`hermes tools list` 显示 lark_cli enabled
- config：plugins.enabled 含 lark-cli-toolbox，toolsets/platform_toolsets.cli 含 lark_cli

### E. 显示优化
- config：`display.platforms.feishu` 含 streaming/tool_progress/tool_preview_length/runtime_footer
- `runtime_footer` 字段为 model/context_pct/cwd（v0.20.0 有效字段，非旧 delivery/style）

## 五、已知边界 / 待确认（诚实记录）

1. **飞书真实 UI 效果**：工程层面已验证（config 生效、build_footer_line 输出正确字符串、消息发送成功），
   **但"老白在飞书对话看到的实际显示"尚未由老白肉眼确认**——需在飞书发消息看回复末尾状态行 + 工具进度。
2. **gateway 进程**：多次经手动后台启动（因 `hermes gateway restart` 有 Windows 信号 bug，见 R5）。
   当前 gateway PID 可能随 Hermes 自启而变化。重启机器后需重新拉起（Hermes 有 login item）。
3. **废弃配置项**：`outbound_format`/`card_mode`/`gateway_locale` 在 v0.20.0 已不再被飞书 adapter 读取，
   未迁移（避免无效配置）。README 中"post 输出格式"描述对应 v0.20.0 原生逻辑。
4. **工具进度"🧰+编号"标题美化**：v0.20.0 用 reaction(Typing) 机制，旧版文本美化需改通用 run.py，
   风险高，未做（详见 R9）。
5. **adapter-optimization**：media mirror / image_input_mode / image routing / media_refs 在 v0.20.0
   已原生实现，验证 find 不命中后决定不重复打补丁（避免冲突）。

## 六、敏感信息提醒

- 绑定含 app secret（config.json 中 ****），不要提交到公开仓库。
- config.yaml 的飞书凭证未纳入 git（.gitignore 已忽略）。
- 本工作区 `验证/` 目录含备份/副本，已 .gitignore 忽略。
