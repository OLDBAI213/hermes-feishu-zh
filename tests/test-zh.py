#!/usr/bin/env python3
"""
hermes-feishu-zh 中文化测试脚本
可在 TUI 或飞书中运行，检查所有中文化是否生效。

用法:
  python tests/test-zh.py                    # 完整测试
  python tests/test-zh.py --config           # 只检查配置
  python tests/test-zh.py --source           # 只检查源码替换
  python tests/test-zh.py --plugin           # 只检查插件
  python tests/test-zh.py --gateway          # 只检查 Gateway
  python tests/test-zh.py --feishu           # 模拟飞书场景
  python tests/test-zh.py --tui              # 模拟 TUI 场景
"""

import json
import os
import subprocess
import sys
from pathlib import Path

HERMES_HOME = Path(os.environ.get("HERMES_HOME", ""))
PACK_ROOT = Path(__file__).parent.parent
PATCH_PATH = PACK_ROOT / "patches" / "feishu-card-zh.replacements.json"
AUDIT_SCRIPT = HERMES_HOME / "hermes-agent" / "scripts" / "feishu_localization_audit.py"
AUDIT_RULES = HERMES_HOME / "hermes-agent" / "locales" / "feishu_zh_audit_allowlist.yaml"

# 颜色输出
GREEN = "\033[92m"
RED = "\033[91m"
YELLOW = "\033[93m"
CYAN = "\033[96m"
RESET = "\033[0m"


def ok(name, detail=""):
    d = f" ({detail})" if detail else ""
    print(f"  {GREEN}✓{RESET} {name}{d}")
    return True


def fail(name, detail=""):
    d = f" ({detail})" if detail else ""
    print(f"  {RED}✗{RESET} {name}{d}")
    return False


def warn(name, detail=""):
    d = f" ({detail})" if detail else ""
    print(f"  {YELLOW}!{RESET} {name}{d}")
    return False


def check(name, condition, detail=""):
    return ok(name, detail) if condition else fail(name, detail)


def section(title):
    print(f"\n{CYAN}== {title} =={RESET}")


# ============================================================
# 1. 配置检查
# ============================================================
def test_config():
    section("1. Config 中文化检查")
    if not HERMES_HOME.exists():
        return fail("HERMES_HOME 不存在", str(HERMES_HOME))

    config_path = HERMES_HOME / "config.yaml"
    if not config_path.exists():
        return fail("config.yaml 不存在")

    try:
        from ruamel.yaml import YAML
        yaml = YAML()
        cfg = yaml.load(config_path.read_text(encoding="utf-8")) or {}
    except Exception as e:
        return fail("config.yaml 解析失败", str(e))

    display = cfg.get("display") or {}
    feishu_display = (display.get("platforms") or {}).get("feishu") or {}
    feishu_platform = ((cfg.get("platforms") or {}).get("feishu") or {}).get("extra") or {}
    plugins_enabled = (cfg.get("plugins") or {}).get("enabled") or []
    toolsets = cfg.get("toolsets") or []

    results = []
    results.append(check("language == zh", display.get("language") == "zh", str(display.get("language"))))
    results.append(check("gateway_locale == zh", display.get("gateway_locale") == "zh", str(display.get("gateway_locale"))))
    results.append(check("tui_auto_resume_recent == True", display.get("tui_auto_resume_recent") is True, str(display.get("tui_auto_resume_recent"))))
    results.append(check("streaming == True", feishu_display.get("streaming") is True, str(feishu_display.get("streaming"))))
    results.append(check("tool_progress in [new, all]", feishu_display.get("tool_progress") in {"new", "all"}, str(feishu_display.get("tool_progress"))))
    results.append(check("tool_preview_length >= 120", (feishu_display.get("tool_preview_length") or 0) >= 120, str(feishu_display.get("tool_preview_length"))))
    results.append(check("runtime_footer.enabled == True", feishu_display.get("runtime_footer", {}).get("enabled") is True, str(feishu_display.get("runtime_footer", {}).get("enabled"))))
    results.append(check("runtime_footer.style == zh_detailed", feishu_display.get("runtime_footer", {}).get("style") == "zh_detailed", str(feishu_display.get("runtime_footer", {}).get("style"))))
    results.append(check("outbound_format in [post, card]", feishu_platform.get("outbound_format") in {"post", "card"}, str(feishu_platform.get("outbound_format"))))
    results.append(check("lark-cli-toolbox in plugins", "lark-cli-toolbox" in plugins_enabled, str("lark-cli-toolbox" in plugins_enabled)))
    results.append(check("lark_cli in toolsets", "lark_cli" in toolsets, str("lark_cli" in toolsets)))

    return all(results)


# ============================================================
# 2. 源码替换检查
# ============================================================
def test_source():
    section("2. 源码中文化标记检查")
    if not PATCH_PATH.exists():
        return fail("替换规则文件不存在", str(PATCH_PATH))

    try:
        items = json.loads(PATCH_PATH.read_text(encoding="utf-8-sig"))
    except Exception as e:
        return fail("替换规则解析失败", str(e))

    pass_count = 0
    fail_count = 0
    warn_count = 0

    for idx, item in enumerate(items, 1):
        target = HERMES_HOME / item["file"]
        if not target.exists():
            fail(f"规则{idx}: {item['file']}", "文件不存在")
            fail_count += 1
            continue

        text = target.read_text(encoding="utf-8-sig")
        if item["replace"] in text:
            pass_count += 1
        elif item["find"] in text:
            fail(f"规则{idx}", f"英文仍存在: {item['find'][:40]}...")
            fail_count += 1
        else:
            warn(f"规则{idx}", "标记未找到（可能上游已改动）")
            warn_count += 1

    print(f"\n  总计: {len(items)} 条规则, {pass_count} 通过, {fail_count} 失败, {warn_count} 警告")
    return fail_count == 0


def test_localization_audit():
    section("2b. 飞书用户可见英文审计")
    if not AUDIT_SCRIPT.exists():
        return fail("审计脚本不存在", str(AUDIT_SCRIPT))
    if not AUDIT_RULES.exists():
        return fail("审计白名单不存在", str(AUDIT_RULES))

    result = subprocess.run(
        [
            sys.executable,
            str(AUDIT_SCRIPT),
            "--root",
            str(HERMES_HOME / "hermes-agent"),
            "--rules",
            str(AUDIT_RULES),
            "--json",
        ],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print(result.stdout)
        print(result.stderr)
        return fail("审计失败", f"exit={result.returncode}")
    data = json.loads(result.stdout)
    return check("未批准英文 == 0", data.get("unapproved_count") == 0, str(data.get("unapproved_count")))


# ============================================================
# 3. 插件检查
# ============================================================
def test_plugin():
    section("3. 插件检查")
    plugin = HERMES_HOME / "plugins" / "lark-cli-toolbox"

    results = []
    results.append(check("插件目录存在", plugin.exists(), str(plugin)))
    results.append(check("plugin.yaml 存在", (plugin / "plugin.yaml").exists(), str((plugin / "plugin.yaml").exists())))
    results.append(check("__init__.py 存在", (plugin / "__init__.py").exists(), str((plugin / "__init__.py").exists())))

    try:
        sys.path.insert(0, str(HERMES_HOME / "hermes-agent"))
        from hermes_cli.plugins import PluginManager
        from tools.registry import registry
        mgr = PluginManager()
        mgr.discover_and_load(force=True)
        loaded = mgr._plugins.get("lark-cli-toolbox")
        tools = sorted(name for name, entry in registry._tools.items() if entry.toolset == "lark_cli")
        results.append(check("插件已加载", bool(loaded and loaded.enabled), str(bool(loaded and loaded.enabled))))
        results.append(check(f"工具已注册 ({len(tools)}个)", len(tools) >= 10, ", ".join(tools[:5])))
    except Exception as e:
        results.append(fail("插件导入失败", str(e)))

    return all(results)


# ============================================================
# 4. Gateway 检查
# ============================================================
def test_gateway():
    section("4. Gateway 状态检查")
    state_path = HERMES_HOME / "gateway_state.json"

    if not state_path.exists():
        return warn("gateway_state.json 不存在", "Gateway 可能未启动")

    try:
        state = json.loads(state_path.read_text(encoding="utf-8"))
        gw_running = state.get("gateway_state") == "running"
        feishu_state = (state.get("platforms") or {}).get("feishu", {}).get("state", "unknown")

        results = []
        results.append(check("Gateway 运行中", gw_running, str(state.get("gateway_state"))))
        results.append(check("飞书已连接", feishu_state == "connected", str(feishu_state)))
        return all(results)
    except Exception as e:
        return fail("状态解析失败", str(e))


# ============================================================
# 5. 飞书场景测试
# ============================================================
def test_feishu_scenario():
    section("5. 飞书场景模拟")
    print("  以下字符串应显示为中文：\n")

    scenarios = [
        ("命令审批按钮", [
            "✅ 仅本次",
            "✅ 本轮会话",
            "✅ 永久允许",
            "❌ 拒绝",
        ]),
        ("审批标题", [
            "⚠️ 需要确认命令",
        ]),
        ("审批内容", [
            "原因:",
            "需要确认的命令",
        ]),
        ("更新确认", [
            "⚕ 更新需要你确认",
            "✓ 是",
            "✗ 否",
            "由 **{user_name}** 回复",
        ]),
        ("默认值提示", [
            "默认值:",
        ]),
        ("错误消息", [
            "未连接",
            "发送失败",
            "更新消息失败",
            "图片文件不存在",
            "图片上传失败",
            "飞书图片上传缺少 image_key",
            "文件不存在",
            "文件上传失败",
            "飞书文件上传缺少 file_key",
            "飞书发送失败",
        ]),
        ("会话交接", [
            "会话刚从 CLI（",
            "上面的历史对话已经加载完成",
        ]),
        ("更新状态", [
            "✅ Hermes 更新完成。",
            "❌ Hermes 更新失败",
            "✅ Hermes 更新已成功完成。",
            "♻ Gateway 已重启成功",
        ]),
        ("破坏性命令确认", [
            "⚠️ **确认 /{command}**",
            "请选择:",
            "• **仅本次批准**",
            "• **永久批准**",
            "• **取消**",
        ]),
        ("危险命令确认", [
            "⚠️ **需要确认命令:**",
            "原因: {desc}",
            "回复 `/approve` 执行",
            "或回复 `/deny` 取消",
        ]),
    ]

    # 读取源码文件检查
    feishu_py = HERMES_HOME / "hermes-agent" / "gateway" / "platforms" / "feishu.py"
    run_py = HERMES_HOME / "hermes-agent" / "gateway" / "run.py"

    feishu_text = feishu_py.read_text(encoding="utf-8-sig") if feishu_py.exists() else ""
    run_text = run_py.read_text(encoding="utf-8-sig") if run_py.exists() else ""

    all_pass = True
    for category, strings in scenarios:
        print(f"  {category}:")
        for s in strings:
            found = s in feishu_text or s in run_text
            if found:
                ok(f'"{s}"')
            else:
                fail(f'"{s}"', "未找到")
                all_pass = False

    return all_pass


# ============================================================
# 6. TUI 场景测试
# ============================================================
def test_tui_scenario():
    section("6. TUI 场景模拟")
    print("  TUI 显示检查（需要手动确认飞书中是否显示中文）：\n")

    checks = [
        "工具进度显示为中文",
        "运行时脚注显示模型/提供商/上下文",
        "流式输出正常工作",
        "审批按钮显示中文",
        "错误消息显示中文",
    ]

    for c in checks:
        warn(c, "需要在飞书中手动确认")

    print("\n  提示：在飞书中发送以下消息触发中文显示：")
    print("    1. 发送任意消息 → 检查流式输出和工具进度")
    print("    2. 触发审批 → 检查按钮和标题是否中文")
    print("    3. 触发错误 → 检查错误消息是否中文")

    return True


# ============================================================
# Main
# ============================================================
def main():
    args = sys.argv[1:]

    if not HERMES_HOME:
        print(f"{RED}错误: HERMES_HOME 未设置{RESET}")
        sys.exit(1)

    print(f"{CYAN}hermes-feishu-zh 中文化测试{RESET}")
    print(f"HERMES_HOME: {HERMES_HOME}")

    tests = {
        "--config": test_config,
        "--source": test_source,
        "--audit": test_localization_audit,
        "--plugin": test_plugin,
        "--gateway": test_gateway,
        "--feishu": test_feishu_scenario,
        "--tui": test_tui_scenario,
    }

    if not args:
        # Run all tests
        results = []
        results.append(("Config", test_config()))
        results.append(("Source", test_source()))
        results.append(("Audit", test_localization_audit()))
        results.append(("Plugin", test_plugin()))
        results.append(("Gateway", test_gateway()))
        results.append(("Feishu", test_feishu_scenario()))
        results.append(("TUI", test_tui_scenario()))

        section("SUMMARY")
        total_pass = sum(1 for _, r in results if r)
        total_fail = sum(1 for _, r in results if not r)

        for name, passed in results:
            icon = f"{GREEN}✓{RESET}" if passed else f"{RED}✗{RESET}"
            print(f"  {icon} {name}")

        print(f"\n  总计: {len(results)} 组测试, {total_pass} 通过, {total_fail} 失败")

        if total_fail == 0:
            print(f"\n  {GREEN}🎉 所有中文化检查通过！{RESET}")
        else:
            print(f"\n  {YELLOW}⚠️ 有 {total_fail} 组未通过{RESET}")

        sys.exit(0 if total_fail == 0 else 1)
    else:
        # Run specific tests
        failures = 0
        for arg in args:
            if arg in tests:
                if not tests[arg]():
                    failures += 1
            else:
                print(f"未知参数: {arg}")
                print(f"可用参数: {', '.join(tests.keys())}")
                failures += 1
        sys.exit(0 if failures == 0 else 1)


if __name__ == "__main__":
    main()
