# 飞书套件三件套 → Hermes v0.20.0 能力映射与落地评估

日期：2026-08-05
目标源码：Hermes Agent v0.20.0 (2026.8.3), commit `1be70d6`
汉化仓库：`AI/feishu-zh-v20/`

> 本报告基于对 v0.20.0 **实际源码逐项核实**（非推测）。结论分三层：中文化 / 显示优化 / 适配优化。

---

## 一、结论先行

| 套件 | 定位 | v0.20.0 状态 | 落地策略 |
|------|------|------------|---------|
| **hermes-feishu-zh** | 中文化 | 102 条规则已验证，缺口 125→0 | ✅ 已就绪，待应用到真实源码 |
| **hermes-feishu-display-plus** | 显示增强 | 宿主函数仍在，增强逻辑可移植 | ⏳ 需重写 find 到新路径后移植 |
| **hermes-feishu-adapter-optimization** | 适配优化 | 部分已被官方吸收 (media mirror / image routing) | ⏳ 逐项核对，吸收的不重复做 |

---

## 二、display-plus（显示增强）7 个增强点 → v0.20.0 映射

### 关键发现
v0.20.0 里旧的 `gateway/platforms/feishu.py` 重构为 `plugins/platforms/feishu/adapter.py`，
`gateway/run.py` 仍在。**绝大多数增强点的宿主函数在新版里原样存在，只是文件路径变了。**

| # | 增强内容 | 旧宿主 | v0.20.0 宿主 | 可移植性 |
|---|---------|--------|-------------|---------|
| 1 | 工具调用记录加 `🧰 工具调用记录` 标题 + 编号 | `gateway/run.py: _progress_text` | `gateway/run.py:3913 _progress_text`（**函数体一模一样**） | ✅ 高度可移植 |
| 2 | 结构化正文加 `_polish_feishu_structured_text` 优化 | `feishu.py: _build_markdown_post_payload` | `adapter.py:592 _build_markdown_post_payload`（**同款函数体**） | ✅ 可移植 |
| 3 | post 加空 title 字段 | 同上 | adapter.py:592 | ✅ 可移植 |
| 4 | 空 text 兜底为空格 `text if text else " "` | feishu.py: `_text_post_element` | adapter.py 用 `tag:"md"` 元素（613/615/627），需适配 | ⚠️ 元素结构不同，需重写目标 |
| 5 | `Xiaomi MiMo` → `小米 MiMo` 显示名 | feishu.py | `plugins/model-providers/xiaomi/` 独立插件；`get_auth_provider_display_name` 待查 | ⚠️ 需确认新版 provider 显示逻辑 |
| 6 | 飞书进度编辑失败抑制兜底行 | `run.py: Transient network errors` | `run.py:4118 "Editing unsupported: send just this line"` 存在 | ✅ 可移植 |
| 7 | 同上（编辑不支持时 continue） | run.py | run.py:4118 附近 | ✅ 可移植 |

### 配套 config
- `runtime_footer`：✅ v0.20.0 config_defaults.py:1275 存在（状态卡片显示）
- `tool_preview_length`：✅ config_defaults.py:1205 存在
- `tool_progress`：✅ 原生支持（gateway/run.py + base.py）
- `gateway_locale`：❌ v0.20.0 已移除（旧显示配置，新版不再读）
- `outbound_format` / `card_mode`：❌ v0.20.0 飞书 adapter 已不读取（新版 `_build_outbound_payload` 内部逻辑）

---

## 三、adapter-optimization（适配优化）5 个增强点 → v0.20.0 映射

### 关键发现
**部分增强已被官方吸收**（主仓库演进快）：

| # | 增强内容 | 旧宿主 | v0.20.0 状态 | 结论 |
|---|---------|--------|-------------|------|
| 1 | 媒体镜像文本 `_describe_media_for_mirror` | `send_message_tool.py` | `tools/send_message_tool.py:444 + 623` **官方已实现同款** | ✅ 已被吸收，无需重复 |
| 2 | `forced_image_mode` 支持 `agent.image_input_mode=native/text` | `run_agent.py` | `agent/image_routing.py` 原生支持 auto/native/text；config_defaults:240 有 `image_input_mode: auto` | ✅ 已被吸收，无需重复 |
| 3 | image routing 文本模型降级 | `image_routing.py` | 同上，原生 | ✅ 已被吸收 |
| 4 | image routing native →text 降级 | `image_routing.py` | `decide_image_input_mode` 原生，逻辑待比对细节 | ⚠️ 可能略不同，需比对 |
| 5 | auxiliary_client 自定义 base_url 保留 provider 名 | `auxiliary_client.py` | `agent/auxiliary_client.py` 原生 | ⚠️ 需比对细节 |

---

## 四、落地建议（按价值/风险排序）

### 第一优先：中文化（已完成，待应用）
- 102 条规则应用到真实 Hermes 飞书源码 → 飞书说中文。核心价值，低风险（已语法验证）。

### 第二优先：display-plus 的「工具进度编号 + 结构化正文 polish」
- 这 2 个增强点（#1 #2）宿主函数在新版原样存在，增强逻辑清晰，能给飞书消息显示带来实质提升。
- 需重写 find 指向新路径，或在验证副本上验证后应用。

### 第三优先：display-plus 其余 + adapter 细节比对
- #4（空text兜底，元素结构变了）、#5（MiMo名）、adapter #4#5 需先比对新版实现再定。
- media mirror / image routing 已被官方吸收 → **不做**（避免重复/冲突）。

### 明确弃置（新版不支持）
- `outbound_format` / `card_mode` / `gateway_locale` config 开关。

---

## 五、需要说明的风险与边界

1. 官方主仓库演进极快，很多"增强"被官方吸收属于正常——**不是汉化包失效，而是上游追上了**。
2. 应用源码补丁会改 Hermes 生产文件，必须先备份、可回滚（汉化包自带了 backup/rollback）。
3. 每次 Hermes 大版本升级，这些源码补丁都可能需要重新适配 —— 这是源码级汉化/增强的固有成本。
4. lark-cli-toolbox 插件强依赖 `lark-cli` 可执行文件（当前系统未安装），装了工具也不可用，需另装 lark-cli 才能生效。

---

## 六、最终落地判定（2026-08-05 补充）

针对 display-plus（显示增强）与 adapter-optimization（适配优化）的**逐项核对结论**：

### adapter-optimization（5 项增强）→ 在 v0.20.0 已全部被官方吸收/原生覆盖

| # | 增强点 | v0.20.0 状态 | 判定 |
|---|--------|-------------|------|
| 1 | media mirror `_describe_media_for_mirror` | `send_message_tool.py` find 不命中，官方已重构 | ❌ 不重复做 |
| 2 | image_input_mode 强制 | `run_agent.py` find 不命中，官方已重构 `image_routing.py` 原生支持 auto/native/text | ❌ 不重复做 |
| 3 | image_routing native 降级 | 原生 `_supports_vision_override` / `model.supports_vision` 更完整 | ❌ 不重复做 |
| 4 | auxiliary provider 保留 | 原生 `_MAIN_RUNTIME_FIELDS` + provider/base_url 处理 | ❌ 不重复做 |
| 5 | 同 1 | 官方已实现 | ❌ 不重复做 |

### display-plus（显示增强）→ 补丁不完整，且 v0.20.0 已有原生替代
- `_polish_feishu_structured_text`、`_feishu_zh_progress` **两个辅助函数在汉化仓库里只被补丁引用、无函数体**（原依赖独立项目，已合并但函数未随迁）
- v0.20.0 的 `_build_markdown_post_rows` 已原生实现 fenced code block 隔离（display-plus 想解决的目标之一）
- v0.20.0 的 `_progress_text` + `_split_progress_groups` 已有成熟进度分组机制
- **强行移植**需自行发明缺失函数 + 适配通用进度逻辑，有引入不稳定风险
- **判定**：📦 作为"可选增强"，待明确需要时再按 v0.20.0 原生机制重新实现；不作为本轮必做项

### 落地进度总表

| 项 | 状态 | 说明 |
|----|------|------|
| ✅ 中文化 102 条 | 已上线 | 真实 Hermes 源码已应用，审计 0 缺口，verify 通过 |
| ✅ install.ps1 / verify.ps1 / manifest | 已适配 | 指向 v20 规则 + 新路径，verify 全绿（除 lark 绑定） |
| ✅ lark-cli + lark-cli-toolbox 插件 | 已装 | 12 工具注册，待老白授权 `config bind` |
| ⏳ lark-cli 绑定 | 待授权 | bot-only / user-default 需用户确认 |
| 📦 display-plus | 暂缓 | 需自行实现缺失函数，原生已覆盖大部分 |
| ❌ adapter-optimization | 不重复做 | 官方已吸收/原生更完整 |

### 诚实结论
"为什么没都做"的答案：**中文化、脚本适配、插件工具这些独立的、有明确增量的都做了；剩下的 display-plus 和 adapter-optimization 在 v0.20.0 要么被官方吸收（重复做反而冲突），要么补丁本身不完整且原生已有替代。** 如实记录，不假装"全部完成"，也不为凑数强行移植可能引入不稳定的代码。
