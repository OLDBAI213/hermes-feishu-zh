# 交接 / 检查要点 — hermes-feishu-zh v0.4.0 实时显示适配 v0.20.0

生成：2026-08-05 22:10
目的：供 Codex 或后续维护者独立检查本次飞书汉化适配工作
工作区：`Desktop/AI/feishu-zh-v20/`
GitHub：`OLDBAI213/hermes-feishu-zh`，当前工作分支 `codex/feishu-display-cards`；生产基线 commit `1be70d635`

---

## 一、这次改了什么（一句话）

把 hermes-feishu-zh 汉化包从适配 Hermes v0.15.1 全面升级到 Hermes v0.20.0：
飞书源码重构从 `gateway/platforms/feishu.py` → `plugins/platforms/feishu/`，
原 114 条失效规则重写为 102 条 v0.20.0 新规则，并完成实时状态卡、执行过程卡、最终回复卡、lark-cli 集成和 verify 适配。

## 二、关键文件清单

| 文件 | 作用 |
|------|------|
| `patches/feishu-zh-v20.replacements.json` | **102 条 v0.20.0 中文化规则**（adapter 59 + comment_rules 34 + meeting_invite 9） |
| `patches/display-plus-v20.replacements.json` | **22 条实时显示规则**（adapter/run/turn context） |
| `patches/display-plus/feishu_realtime_display.py` | 无副作用的状态卡和执行过程卡渲染器 |
| `patches/display-plus/stable.config.yaml` | realtime_cards/tool_progress/quiet heartbeat 配置 |
| `audit/feishu_zh_audit_v18_allowlist.yaml` | 审计白名单（新增正则/类型/HTML实体豁免） |
| `install.ps1` | 改：主规则指向 v20 文件 |
| `verify.ps1` | 改：Config 检查移除废弃项、Feishu adapter build 改 importlib |
| `manifest.json` | v0.4.0、实时显示资产、PowerShell 7 验证命令 |
| `README.md` / `CHANGELOG.md` | 对齐实时卡片能力和验证边界 |
| `04_运行记录.md` | **完整操作证据链 R1-R13** |
| `05_套件研究_TRIAGE.md` | 三套件→v0.20.0 能力映射与最终判定 |

## 三、验证证据（仓库侧已跑）

1. **实时显示测试**：`12 passed`，覆盖真实模型/provider/context、阶段变化、工具编号/成功/失败、安装器与验证器静态契约。
2. **语法**：`install.ps1`、`verify.ps1`、`tests/check-package.ps1` 通过 PowerShell 7 解析；渲染器和 patched Python 可编译。
3. **隔离安装**：22 条实时显示规则全部应用；重复安装幂等；第一次备份回滚恢复源文件、配置并移除新渲染器。
4. **包检查**：只扫描 Git 已跟踪和未忽略文件，未发现凭据模式。
5. **既有中文化基线**：102 条中文规则、英文审计 `unapproved=0`、lark-cli-toolbox 12 个工具均已在 v0.3.0 生产环境验证。

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
- `lark-cli config show` → workspace hermes，应用和身份已解析
- 绑定文件：`C:\Users\Administrator\.lark-cli\hermes\config.json`
- 插件：`hermes plugins list` 显示 lark-cli-toolbox enabled；`hermes tools list` 显示 lark_cli enabled
- config：plugins.enabled 含 lark-cli-toolbox，toolsets/platform_toolsets.cli 含 lark_cli

### E. 实时显示
- config：`realtime_cards=true`、`tool_progress=all`、`tool_progress_grouping=accumulate`
- `runtime_footer.enabled=false`、`long_running_notifications=false`、`busy_ack_detail=false`
- `gateway/feishu_realtime_display.py` 只渲染实际传入的模型/provider/token 数据；无 token 时不显示上下文。
- `run.py` 每轮状态卡只发送一次并编辑；执行过程卡消费真实工具队列事件；最终回复不重复运行元数据。

## 五、已知边界 / 待确认（诚实记录）

1. **飞书真实 UI 效果**：仓库和隔离副本已验证；生产 Hermes 尚未在本轮应用，仍需应用后由用户在飞书肉眼确认截图样式。
2. **gateway 进程**：多次经手动后台启动（因 `hermes gateway restart` 有 Windows 信号 bug，见 R5）。
   当前 gateway PID 可能随 Hermes 自启而变化。重启机器后需重新拉起（Hermes 有 login item）。
3. **旧字段**：`outbound_format`/`card_mode`/`gateway_locale` 不参与 v0.20.0 实时显示配置；安装器不会写入，卸载会清理残留。
4. **PowerShell**：必须使用 PowerShell 7 (`pwsh`)；Windows PowerShell 5.1 对仓库 UTF-8 脚本的解析不受支持。
5. **adapter-optimization**：media mirror / image_input_mode / image routing / media_refs 在 v0.20.0
   已原生实现，验证 find 不命中后决定不重复打补丁（避免冲突）。

## 六、敏感信息提醒

- 绑定含 app secret（config.json 中 ****），不要提交到公开仓库。
- config.yaml 的飞书凭证未纳入 git（.gitignore 已忽略）。
- 本工作区 `验证/` 目录含备份/副本，已 .gitignore 忽略。
