from __future__ import annotations

import importlib.util
from pathlib import Path
import json


MODULE_PATH = (
    Path(__file__).resolve().parents[1]
    / "patches"
    / "display-plus"
    / "feishu_realtime_display.py"
)
PATCH_PATH = MODULE_PATH.parents[1] / "display-plus-v20.replacements.json"


def load_module():
    spec = importlib.util.spec_from_file_location("feishu_realtime_display", MODULE_PATH)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_status_card_uses_live_runtime_values() -> None:
    display = load_module()

    rendered = display.render_status_card(
        phase="thinking",
        model="mimo-v2.5",
        provider="xiaomi",
        used_tokens=46_000,
        context_length=1_000_000,
    )

    assert rendered == (
        "⏳ 已收到，正在思考...\n"
        "模型: mimo-v2.5\n"
        "服务商: xiaomi\n"
        "上下文: 约 46K / 1.0M (5%)"
    )


def test_status_card_hides_context_when_runtime_has_no_real_usage() -> None:
    display = load_module()

    rendered = display.render_status_card(
        phase="thinking",
        model="deepseek-v4-flash",
        provider="deepseek",
        used_tokens=0,
        context_length=1_000_000,
    )

    assert "模型: deepseek-v4-flash" in rendered
    assert "服务商: deepseek" in rendered
    assert "上下文:" not in rendered


def test_status_card_changes_with_real_execution_phase() -> None:
    display = load_module()

    executing = display.render_status_card(
        phase="executing",
        model="deepseek-v4-flash",
        provider="deepseek",
        used_tokens=51_000,
        context_length=1_000_000,
        detail="terminal",
    )
    finalizing = display.render_status_card(
        phase="finalizing",
        model="deepseek-v4-flash",
        provider="deepseek",
        used_tokens=58_000,
        context_length=1_000_000,
    )

    assert executing.splitlines()[0] == "🧰 正在执行: terminal"
    assert finalizing.splitlines()[0] == "📝 正在整理回复..."
    assert "约 58K / 1.0M (6%)" in finalizing


def test_process_card_numbers_real_steps_and_marks_results() -> None:
    display = load_module()

    rendered = display.render_process_card(
        [
            {"text": "终端: ls -la", "state": "completed", "duration": 0.4},
            {"text": "搜索: Hermes Feishu", "state": "running"},
            {"text": "读取文件: config.yaml", "state": "failed", "error": "权限不足"},
        ]
    )

    assert rendered.splitlines() == [
        "🧰 执行过程（3步）",
        "1. ✅ 终端: ls -la (0.4s)",
        "2. ⏳ 搜索: Hermes Feishu",
        "3. ❌ 读取文件: config.yaml - 权限不足",
    ]


def test_process_card_compacts_multiline_and_long_previews() -> None:
    display = load_module()
    command = "第一行\n" + "x" * 200

    rendered = display.render_process_card(
        [{"text": command, "state": "running"}],
        max_preview_length=40,
    )

    assert rendered.startswith("🧰 执行过程（1步）\n1. ⏳ 第一行 x")
    assert len(rendered.splitlines()[1]) <= 50


def test_v20_patch_contains_gateway_status_and_progress_integration() -> None:
    replacements = json.loads(PATCH_PATH.read_text(encoding="utf-8"))
    run_rules = [item for item in replacements if item["file"].endswith("gateway/run.py")]

    combined = "\n".join(item["replace"] for item in run_rules)
    assert "render_status_card" in combined
    assert "__feishu_tool_completed__" in combined
    assert "🧰 执行过程" in combined


def test_stable_display_config_uses_v20_fields_and_quiet_heartbeat() -> None:
    config = (MODULE_PATH.parents[1] / "stable.config.yaml").read_text(encoding="utf-8")

    assert "delivery:" not in config
    assert "style:" not in config
    assert "fields:" in config
    assert "- model" in config
    assert "- context_pct" in config
    assert "runtime_footer:" in config
    assert "enabled: false" in config
    assert "long_running_notifications: false" in config


def test_installer_copies_renderer_and_applies_only_v20_display_patch() -> None:
    installer = (MODULE_PATH.parents[2] / "install.ps1").read_text(encoding="utf-8")

    assert "Install-DisplayAssets" in installer
    assert "feishu_realtime_display.py" in installer
    assert "display-plus-v20.replacements.json" in installer
    assert "Apply-Replacements -JsonPath (Join-Path $PackRoot \"patches\\feishu-display-upgrade.replacements.json\")" not in installer


def test_verify_script_checks_realtime_assets_and_quiet_feishu_runtime() -> None:
    verify = (MODULE_PATH.parents[2] / "verify.ps1").read_text(encoding="utf-8")

    assert "feishu_realtime_display.py" in verify
    assert "display-plus-v20.replacements.json" in verify
    assert "realtime_cards" in verify
    assert "long_running_notifications" in verify
    assert "runtime_footer" in verify


def test_legacy_display_checks_do_not_require_removed_v015_fields() -> None:
    stale_files = [
        MODULE_PATH.parents[2] / "tests" / "test-zh-display.ps1",
        MODULE_PATH.parents[2] / "tests" / "test-zh.py",
    ]
    for path in stale_files:
        text = path.read_text(encoding="utf-8")
        assert "gateway_locale" not in text
        assert "outbound_format" not in text
        assert "card_mode" not in text
        assert "runtime_footer.style" not in text


def test_installer_normalizes_line_endings_before_replacement_matching() -> None:
    installer = (MODULE_PATH.parents[2] / "install.ps1").read_text(encoding="utf-8")

    assert "normalizedText" in installer
    assert "`r`n" in installer


def test_package_check_requires_v20_realtime_display_assets() -> None:
    package_check = (MODULE_PATH.parents[2] / "tests" / "check-package.ps1").read_text(
        encoding="utf-8"
    )

    assert "feishu-zh-v20.replacements.json" in package_check
    assert "display-plus-v20.replacements.json" in package_check
    assert "feishu_realtime_display.py" in package_check
    assert "feishu-display-upgrade.replacements.json" not in package_check


def test_bootstrap_runs_installer_with_powershell_7() -> None:
    bootstrap = (MODULE_PATH.parents[2] / "bootstrap.ps1").read_text(encoding="utf-8")

    assert "Get-Command pwsh" in bootstrap
    assert "& $pwsh.Source" in bootstrap


def test_installer_preflights_all_display_rules_before_creating_backup() -> None:
    installer = (MODULE_PATH.parents[2] / "install.ps1").read_text(encoding="utf-8")

    assert "Assert-ReplacementsApplicable" in installer
    assert installer.index("Assert-ReplacementsApplicable -JsonPath") < installer.index(
        "$backupDir = New-Backup"
    )


def test_installer_backup_names_include_milliseconds() -> None:
    installer = (MODULE_PATH.parents[2] / "install.ps1").read_text(encoding="utf-8")

    assert 'Get-Date -Format "yyyyMMdd-HHmmssfff"' in installer
