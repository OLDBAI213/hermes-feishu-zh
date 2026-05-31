#!/usr/bin/env python3
"""Audit Feishu-facing source strings for Chinese localization coverage.

The point of this script is not to translate text.  It builds a repeatable
ledger of English string literals in Feishu user-visible paths and fails when
English prose is not either translated or explicitly allowed.
"""

from __future__ import annotations

import argparse
import ast
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable

import yaml


DEFAULT_RULES = Path("locales/feishu_zh_audit_allowlist.yaml")

USER_TEXT_NAMES = {
    "body",
    "caption",
    "content",
    "default_message",
    "description",
    "detail",
    "error",
    "fallback",
    "header",
    "hint",
    "label",
    "message",
    "msg",
    "override_error",
    "prompt",
    "reason",
    "summary",
    "text",
    "title",
    "usage",
}

USER_VISIBLE_CALLS = {
    "print",
    "SendResult",
    "RuntimeError",
    "ValueError",
    "KeyError",
    "_error",
    "_web_response",
    "web.Response",
    "web.json_response",
    "json_response",
}

NON_USER_CALL_PREFIXES = {
    "logger.",
    "logging.",
}


@dataclass(frozen=True)
class Finding:
    file: str
    line: int
    text: str
    context: str
    status: str
    reason: str


def _func_name(node: ast.AST) -> str:
    if isinstance(node, ast.Name):
        return node.id
    if isinstance(node, ast.Attribute):
        base = _func_name(node.value)
        return f"{base}.{node.attr}" if base else node.attr
    return ""


def _is_docstring_node(node: ast.AST, parents: dict[ast.AST, ast.AST]) -> bool:
    parent = parents.get(node)
    if not isinstance(parent, ast.Expr):
        return False
    owner = parents.get(parent)
    if not isinstance(owner, (ast.Module, ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
        return False
    return bool(owner.body and owner.body[0] is parent)


def _string_text(node: ast.AST) -> str | None:
    if isinstance(node, ast.Constant) and isinstance(node.value, str):
        return node.value
    if isinstance(node, ast.JoinedStr):
        parts: list[str] = []
        for value in node.values:
            if isinstance(value, ast.Constant) and isinstance(value.value, str):
                parts.append(value.value)
            elif isinstance(value, ast.FormattedValue):
                parts.append("{}")
        return "".join(parts)
    return None


def _iter_string_nodes(tree: ast.AST, parents: dict[ast.AST, ast.AST]) -> Iterable[ast.AST]:
    for node in ast.walk(tree):
        if isinstance(node, ast.Constant) and isinstance(node.value, str):
            if isinstance(parents.get(node), ast.JoinedStr):
                continue
            yield node
        elif isinstance(node, ast.JoinedStr):
            yield node


def _has_english_letters(text: str) -> bool:
    return bool(re.search(r"[A-Za-z]", text))


def _has_cjk(text: str) -> bool:
    return bool(re.search(r"[\u3400-\u9fff]", text))


def _assign_targets(node: ast.AST, parents: dict[ast.AST, ast.AST]) -> list[str]:
    current: ast.AST | None = node
    while current is not None:
        parent = parents.get(current)
        if isinstance(parent, ast.Assign):
            names: list[str] = []
            for target in parent.targets:
                names.extend(_target_names(target))
            return names
        if isinstance(parent, ast.AnnAssign):
            return _target_names(parent.target)
        current = parent
    return []


def _target_names(target: ast.AST) -> list[str]:
    if isinstance(target, ast.Name):
        return [target.id]
    if isinstance(target, ast.Attribute):
        return [target.attr]
    if isinstance(target, (ast.Tuple, ast.List)):
        names: list[str] = []
        for item in target.elts:
            names.extend(_target_names(item))
        return names
    return []


def _inside_call(node: ast.AST, parents: dict[ast.AST, ast.AST]) -> ast.Call | None:
    current: ast.AST | None = node
    while current is not None:
        parent = parents.get(current)
        if isinstance(parent, ast.Call):
            return parent
        current = parent
    return None


def _inside_return(node: ast.AST, parents: dict[ast.AST, ast.AST]) -> bool:
    current: ast.AST | None = node
    while current is not None:
        if isinstance(parents.get(current), ast.Return):
            return True
        current = parents.get(current)
    return False


def _keyword_name(node: ast.AST, parents: dict[ast.AST, ast.AST]) -> str | None:
    parent = parents.get(node)
    while parent is not None:
        maybe_call = parents.get(parent)
        if isinstance(maybe_call, ast.Call):
            for keyword in maybe_call.keywords:
                if keyword.value is parent or keyword.value is node:
                    return keyword.arg
            return None
        node = parent
        parent = parents.get(parent)
    return None


def _is_logger_context(node: ast.AST, parents: dict[ast.AST, ast.AST]) -> bool:
    call = _inside_call(node, parents)
    if call is None:
        return False
    name = _func_name(call.func)
    return any(name.startswith(prefix) for prefix in NON_USER_CALL_PREFIXES)


def _looks_machine_only(text: str) -> bool:
    stripped = text.strip()
    if not stripped:
        return True
    if "\n" in stripped and len(stripped) > 160:
        return True
    if stripped.startswith(("http://", "https://", "/", ".")):
        return True
    if re.fullmatch(r"[A-Za-z0-9_./:;{}()<>\[\]@|?*=+,%#$\\ -]+", stripped):
        if " " not in stripped or re.fullmatch(r"[A-Z0-9_ -]+", stripped):
            return True
    return False


def _candidate_context(node: ast.AST, parents: dict[ast.AST, ast.AST]) -> str | None:
    if _is_logger_context(node, parents):
        return None

    call = _inside_call(node, parents)
    call_name = _func_name(call.func) if call is not None else ""
    keyword = _keyword_name(node, parents)
    targets = _assign_targets(node, parents)

    if call_name == "t":
        return None
    if call_name in USER_VISIBLE_CALLS:
        return f"call:{call_name}"
    if keyword and keyword in USER_TEXT_NAMES:
        return f"keyword:{keyword}"
    if any(any(part in target.lower() for part in USER_TEXT_NAMES) for target in targets):
        return f"assign:{','.join(targets)}"
    if _inside_return(node, parents):
        return "return"
    return None


def _load_rules(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as f:
        raw = yaml.safe_load(f) or {}
    return raw


def _compile_patterns(items: Iterable[dict[str, str]]) -> list[tuple[re.Pattern[str], str]]:
    compiled: list[tuple[re.Pattern[str], str]] = []
    for item in items:
        pattern = item.get("pattern")
        if not pattern:
            continue
        compiled.append((re.compile(pattern), item.get("reason", "")))
    return compiled


def _allowed_reason(text: str, exact: dict[str, str], patterns: list[tuple[re.Pattern[str], str]]) -> str | None:
    stripped = text.strip()
    if stripped in exact:
        return exact[stripped]
    for pattern, reason in patterns:
        if pattern.search(stripped):
            return reason
    return None


def _forbidden_reason(text: str, patterns: list[tuple[re.Pattern[str], str]]) -> str | None:
    for pattern, reason in patterns:
        if pattern.search(text):
            return reason
    return None


def audit(root: Path, rules_path: Path) -> list[Finding]:
    rules = _load_rules(rules_path)
    exact = {item["text"]: item.get("reason", "") for item in rules.get("allowed_exact", []) if "text" in item}
    allowed_patterns = _compile_patterns(rules.get("allowed_patterns", []))
    forbidden_patterns = _compile_patterns(rules.get("forbidden_patterns", []))

    findings: list[Finding] = []
    for rel in rules.get("scope", {}).get("files", []):
        path = root / rel
        source = path.read_text(encoding="utf-8")
        tree = ast.parse(source, filename=str(path))
        parents = {child: parent for parent in ast.walk(tree) for child in ast.iter_child_nodes(parent)}

        for node in _iter_string_nodes(tree, parents):
            text = (_string_text(node) or "").strip()
            if not text or not _has_english_letters(text):
                continue

            line = getattr(node, "lineno", 0)
            forbidden = _forbidden_reason(text, forbidden_patterns)
            if forbidden:
                findings.append(Finding(rel, line, text, "forbidden", "forbidden", forbidden))
                continue

            if _is_docstring_node(node, parents):
                findings.append(Finding(rel, line, text, "docstring", "ignored", "docstring"))
                continue

            context = _candidate_context(node, parents)
            if context is None:
                reason = _allowed_reason(text, exact, allowed_patterns)
                status = "allowed" if reason else "ignored"
                findings.append(Finding(rel, line, text, "non_user_visible", status, reason or "not in user-visible context"))
                continue

            if _has_cjk(text):
                findings.append(Finding(rel, line, text, context, "translated", "contains Chinese"))
                continue

            reason = _allowed_reason(text, exact, allowed_patterns)
            if reason:
                findings.append(Finding(rel, line, text, context, "allowed", reason))
            elif _looks_machine_only(text):
                findings.append(Finding(rel, line, text, context, "allowed", "machine/protocol-looking literal"))
            else:
                findings.append(Finding(rel, line, text, context, "unapproved", "English prose in user-visible context"))

    return findings


def _summarize(findings: list[Finding]) -> dict[str, Any]:
    counts: dict[str, int] = {}
    for finding in findings:
        counts[finding.status] = counts.get(finding.status, 0) + 1
    unapproved = [finding for finding in findings if finding.status in {"unapproved", "forbidden"}]
    user_visible = [
        finding
        for finding in findings
        if finding.context not in {"docstring", "non_user_visible"}
    ]
    return {
        "total_english_literals": len(findings),
        "user_visible_english_literals": len(user_visible),
        "counts": dict(sorted(counts.items())),
        "unapproved_count": len(unapproved),
        "unapproved": [finding.__dict__ for finding in unapproved],
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default=".", help="Hermes agent repository root")
    parser.add_argument("--rules", default=str(DEFAULT_RULES), help="Audit allowlist YAML")
    parser.add_argument("--json", action="store_true", help="Emit machine-readable JSON")
    parser.add_argument("--max-items", type=int, default=50, help="Max unapproved items to print")
    args = parser.parse_args(argv)

    root = Path(args.root).resolve()
    rules_path = (root / args.rules).resolve() if not Path(args.rules).is_absolute() else Path(args.rules)
    findings = audit(root, rules_path)
    summary = _summarize(findings)

    if args.json:
        print(json.dumps(summary, ensure_ascii=False, indent=2))
    else:
        print("Feishu localization audit")
        print(f"root: {root}")
        print(f"rules: {rules_path}")
        print(f"total English literals: {summary['total_english_literals']}")
        print(f"user-visible English literals: {summary['user_visible_english_literals']}")
        print(f"unapproved: {summary['unapproved_count']}")
        for key, value in summary["counts"].items():
            print(f"  {key}: {value}")
        if summary["unapproved"]:
            print()
            print("Unapproved user-visible English:")
            for item in summary["unapproved"][: args.max_items]:
                print(f"- {item['file']}:{item['line']} [{item['context']}] {item['text']!r}")
                print(f"  reason: {item['reason']}")

    return 1 if summary["unapproved_count"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
