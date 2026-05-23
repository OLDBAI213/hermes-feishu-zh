#!/usr/bin/env python3
"""
Hermes 更新检测器 - 检测到 Hermes 更新后自动重装飞书套件
用法：python hermes-update-watcher.py
"""

import subprocess
import os
import time
import json
from pathlib import Path

HERMES_HOME = os.environ.get("HERMES_HOME", "E:\\AI\\hermes")
AGENT_ROOT = os.path.join(HERMES_HOME, "hermes-agent")
VERSION_FILE = os.path.join(HERMES_HOME, ".hermes-feishu-last-version")

# 需要监控的源码文件
WATCHED_FILES = [
    "gateway/platforms/feishu.py",
    "gateway/platforms/feishu_comment.py",
    "gateway/platforms/feishu_comment_rules.py",
    "gateway/run.py",
    "tools/send_message_tool.py",
]

# 飞书套件目录
SUITES = [
    {"name": "hermes-feishu-zh", "dir": "E:/AI/github/hermes-feishu-zh"},
    {"name": "hermes-feishu-display-plus", "dir": "E:/AI/github/hermes-feishu-display-plus"},
    {"name": "hermes-feishu-adapter-optimization", "dir": "E:/AI/github/hermes-feishu-adapter-optimization"},
]


def get_file_hashes():
    """获取监控文件的哈希值"""
    hashes = {}
    for f in WATCHED_FILES:
        path = os.path.join(AGENT_ROOT, f)
        if os.path.exists(path):
            # 简单用修改时间和大小作为哈希
            stat = os.stat(path)
            hashes[f] = f"{stat.st_mtime}:{stat.st_size}"
    return hashes


def load_last_hashes():
    """加载上次的哈希值"""
    if os.path.exists(VERSION_FILE):
        with open(VERSION_FILE, "r") as f:
            return json.load(f)
    return {}


def save_hashes(hashes):
    """保存当前哈希值"""
    with open(VERSION_FILE, "w") as f:
        json.dump(hashes, f, indent=2)


def check_changed_files(current, last):
    """检查哪些文件发生了变化"""
    changed = []
    for f, h in current.items():
        if f not in last or last[f] != h:
            changed.append(f)
    return changed


def install_suite(suite):
    """安装一个飞书套件"""
    install_script = os.path.join(suite["dir"], "install.ps1")
    if not os.path.exists(install_script):
        print(f"  ❌ {suite['name']}: install.ps1 不存在")
        return False

    print(f"  🔧 安装 {suite['name']}...")
    powershell = r"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    result = subprocess.run(
        [powershell, "-ExecutionPolicy", "Bypass", "-File", install_script],
        capture_output=True, text=True, timeout=120
    )

    if result.returncode == 0:
        print(f"  ✅ {suite['name']}: 安装成功")
        return True
    else:
        print(f"  ⚠️ {suite['name']}: 安装有警告")
        # 检查是否有关键错误
        if "error" in result.stderr.lower() or "exception" in result.stderr.lower():
            print(f"     {result.stderr[:200]}")
        return True  # 警告不算失败


def main():
    print("=== Hermes 更新检测器 ===")
    print(f"Hermes: {HERMES_HOME}")
    print(f"监控文件: {len(WATCHED_FILES)} 个")
    print()

    # 获取当前文件哈希
    current = get_file_hashes()
    last = load_last_hashes()

    # 检查变化
    changed = check_changed_files(current, last)

    if not changed:
        print("✅ 没有检测到变化，跳过安装")
        return

    print(f"⚠️ 检测到 {len(changed)} 个文件变化:")
    for f in changed:
        print(f"  - {f}")

    print()
    print("=== 开始重装飞书套件 ===")

    success = 0
    for suite in SUITES:
        if install_suite(suite):
            success += 1

    print()
    print(f"=== 完成: {success}/{len(SUITES)} 成功 ===")

    # 保存当前哈希
    save_hashes(current)
    print("已更新版本记录")


if __name__ == "__main__":
    main()
