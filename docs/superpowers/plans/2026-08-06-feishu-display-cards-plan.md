# 飞书实时显示卡片 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 Hermes v0.20.0 中实现与参考图片一致的飞书实时状态卡、执行过程卡和最终回复卡。

**Architecture:** 复用 gateway 的状态回调、工具进度队列和 Feishu 编辑接口。新增一个无副作用的显示渲染模块负责实时文本格式化；gateway 负责事件驱动和每轮消息 ID，Feishu adapter 只负责发送/编辑状态卡。配置将实时卡片设为飞书专属开关，并关闭重复 footer、长任务气泡和中途助手碎片消息。

**Tech Stack:** Python 3.11, Hermes gateway, Feishu post/text message API, PowerShell installer, pytest.

---

### Task 1: 固定实时渲染行为

**Files:**
- Create: `patches/display-plus/feishu_realtime_display.py`
- Test: `tests/test-feishu-realtime-display.py`

- [ ] **Step 1: Write failing tests** for real model/provider/context rendering, missing token stats, phase transitions, numbered process entries, and failed tool entries.
- [ ] **Step 2: Run `python -m pytest tests/test-feishu-realtime-display.py -q` and confirm the new tests fail because the renderer does not exist.
- [ ] **Step 3: Implement pure `render_status_card()` and `render_process_card()` helpers with no network or filesystem access.
- [ ] **Step 4: Re-run the focused tests and then the package Python tests.**

### Task 2: Add one editable Feishu status card per turn

**Files:**
- Modify: `plugins/platforms/feishu/adapter.py` through `patches/display-plus-v20.replacements.json`
- Modify: `gateway/run.py` through `patches/display-plus-v20.replacements.json`
- Modify: `gateway/turn_context.py` through `patches/display-plus-v20.replacements.json`
- Test: `tests/test-feishu-realtime-display.py`

- [ ] **Step 1: Add a failing adapter test for send-then-edit status behavior keyed by the current turn, including edit failure without a duplicate send.**
- [ ] **Step 2: Run the focused test and observe the expected missing behavior.**
- [ ] **Step 3: Add the bounded per-turn status-message state and async send/edit path.**
- [ ] **Step 4: Wire the gateway to create the initial status card after the real agent is resolved, update it on tool and lifecycle events, and use a unique key per turn.**
- [ ] **Step 5: Re-run adapter/gateway tests and compile the patched source.**

### Task 3: Make execution progress real-time and compact

**Files:**
- Modify: `gateway/run.py` through `patches/display-plus-v20.replacements.json`
- Modify: `patches/stable.config.yaml`
- Modify: `patches/enhanced.config.yaml`
- Modify: `install.ps1`
- Modify: `tests/test-zh-display.ps1`

- [ ] **Step 1: Add failing tests for all real tool events, one editable process card, step numbering, and no periodic long-running bubbles.**
- [ ] **Step 2: Implement structured started/completed/failed queue markers and render every real step in one accumulated Feishu card.**
- [ ] **Step 3: Replace stale v0.15.1 display fields with v0.20.0 fields and set `tool_progress: all`, `runtime_footer.enabled: false`, `long_running_notifications: false`, and `busy_ack_detail: false` for Feishu.**
- [ ] **Step 4: Install the renderer asset with backup/rollback support and add uninstall cleanup.**
- [ ] **Step 5: Run `verify.ps1 -HermesHome C:\Users\Administrator\AppData\Local\hermes -SkipGateway`, all focused tests, and the package checks.**

### Task 4: Synchronize and audit

**Files:**
- Modify: `README.md`, `README-方案.md`, `06_交接检查_CODEX.md`, `CHANGELOG.md`

- [ ] **Step 1: Document the image-based acceptance criteria and v0.20.0 compatibility boundary.
- [ ] **Step 2: Review the patch against current Hermes source `1be70d6` and ensure no old display-plus or adapter-optimization patch is installed.
- [ ] **Step 3: Run the full verification command and inspect `git diff` for credentials or unrelated files.
- [ ] **Step 4: Commit the branch and push it to the GitHub repository for review; do not apply the production patch until the repository verification is green.
