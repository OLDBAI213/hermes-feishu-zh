#!/usr/bin/env python3
"""Apply display-plus-v20.replacements.json to live Hermes source (dry-run / apply).

Usage:
  python apply_display_plus.py --dry-run
  python apply_display_plus.py --apply
"""
import json
import shutil
import sys
import os
from pathlib import Path

HERMES_ROOT = Path(r"C:\Users\Administrator\AppData\Local\hermes\hermes-agent")
PATCH_FILE = Path(r"C:\Users\Administrator\Desktop\AI\feishu-zh-v20\patches\display-plus-v20.replacements.json")
BACKUP_DIR = Path(r"C:\Users\Administrator\Desktop\AI\feishu-zh-v20\验证\备份_显示优化")

def main():
    dry = "--dry-run" in sys.argv
    apply = "--apply" in sys.argv
    if not dry and not apply:
        print("need --dry-run or --apply")
        return 1

    with open(PATCH_FILE, encoding="utf-8") as f:
        rules = json.load(f)

    BACKUP_DIR.mkdir(parents=True, exist_ok=True)

    total = len(rules)
    hit = 0
    already = 0
    miss = []

    for item in rules:
        rel = item["file"]
        # strip hermes-agent/ prefix
        rel_clean = rel.removeprefix("hermes-agent/")
        target = HERMES_ROOT / rel_clean
        if not target.exists():
            miss.append(f"{rel}: FILE MISSING")
            continue
        text = target.read_text(encoding="utf-8")
        normalized = text.replace("\r\n", "\n")
        if item["replace"] in normalized:
            already += 1
            continue
        if item["find"] in normalized:
            hit += 1
            if apply:
                # backup once
                backup = BACKUP_DIR / (rel_clean.replace("/", "__") + ".bak")
                if not backup.exists():
                    shutil.copy2(target, backup)
                new_text = normalized.replace(item["find"], item["replace"])
                # preserve original line endings
                if "\r\n" in text:
                    new_text = new_text.replace("\n", "\r\n")
                target.write_text(new_text, encoding="utf-8")
            continue
        miss.append(f"{rel}: FIND NOT FOUND")

    print(f"total={total} hit={hit} already={already} miss={len(miss)}")
    for m in miss:
        print("  MISS:", m)
    return 0 if len(miss) == 0 else 2

if __name__ == "__main__":
    sys.exit(main())
