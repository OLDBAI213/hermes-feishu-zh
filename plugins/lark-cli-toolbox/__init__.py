"""Hermes tools backed by the local lark-cli executable."""

from __future__ import annotations

import json
import os
import shutil
import subprocess
from pathlib import Path
from typing import Any, Iterable


TOOLSET = "lark_cli"
TIMEOUT_SECONDS = 90
MAX_OUTPUT_CHARS = 12000


def _find_lark_cli() -> str | None:
    configured = os.getenv("LARK_CLI_BIN")
    candidates = [
        configured,
        shutil.which("lark-cli.cmd"),
        shutil.which("lark-cli.exe"),
        shutil.which("lark-cli"),
        shutil.which("lark-cli.ps1"),
    ]
    for candidate in candidates:
        if candidate and Path(candidate).exists():
            return str(candidate)
    return None


def _check_lark_cli() -> bool:
    return _find_lark_cli() is not None


def _command(args: list[str]) -> list[str]:
    exe = _find_lark_cli()
    if not exe:
        raise RuntimeError("lark-cli not found. Install @larksuite/cli or set LARK_CLI_BIN.")
    if exe.lower().endswith(".ps1"):
        return [
            "powershell",
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            exe,
            *args,
        ]
    return [exe, *args]


def _clip(text: str) -> str:
    if len(text) <= MAX_OUTPUT_CHARS:
        return text
    return text[:MAX_OUTPUT_CHARS] + "\n...[truncated]"


def _run(args: list[str], *, timeout: int = TIMEOUT_SECONDS) -> dict[str, Any]:
    try:
        proc = subprocess.run(
            _command(args),
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=timeout,
            shell=False,
        )
    except Exception as exc:
        return {"ok": False, "error": str(exc), "args": args}

    stdout = _clip((proc.stdout or "").strip())
    stderr = _clip((proc.stderr or "").strip())
    payload: dict[str, Any] = {
        "ok": proc.returncode == 0,
        "returncode": proc.returncode,
        "args": args,
    }
    if stdout:
        try:
            payload["data"] = json.loads(stdout)
        except json.JSONDecodeError:
            payload["stdout"] = stdout
    if stderr:
        payload["stderr"] = stderr
    return payload


def _json(payload: Any) -> str:
    return json.dumps(payload, ensure_ascii=False, indent=2)


def _value(args: dict[str, Any], key: str, default: Any = None) -> Any:
    value = args.get(key, default)
    if value is None or value == "":
        return default
    return value


def _identity(args: dict[str, Any], default: str = "user") -> str:
    value = str(_value(args, "identity", default)).strip()
    return value if value in {"user", "bot"} else default


def _add(options: list[str], flag: str, value: Any) -> None:
    if value is None or value == "":
        return
    if isinstance(value, (dict, list)):
        value = json.dumps(value, ensure_ascii=False)
    options.extend([flag, str(value)])


def _add_bool(options: list[str], flag: str, enabled: Any) -> None:
    if bool(enabled):
        options.append(flag)


def _add_format(options: list[str]) -> None:
    options.extend(["--format", "json"])


def _comma(values: Any) -> str:
    if isinstance(values, str):
        return values
    if isinstance(values, Iterable):
        return ",".join(str(v) for v in values if v)
    return str(values)


def _doctor(args: dict[str, Any] | None = None, **_: Any) -> str:
    doctor = _run(["doctor"])
    auth = _run(["auth", "status"])
    return _json({"lark_cli": _find_lark_cli(), "doctor": doctor, "auth_status": auth})


def _docs_search(args: dict[str, Any], **_: Any) -> str:
    query = _value(args, "query", "")
    options = ["docs", "+search", "--as", _identity(args), "--query", query]
    _add(options, "--page-size", _value(args, "page_size", 10))
    _add(options, "--page-token", _value(args, "page_token"))
    _add(options, "--filter", _value(args, "filter"))
    _add_format(options)
    return _json(_run(options))


def _docs_fetch(args: dict[str, Any], **_: Any) -> str:
    options = [
        "docs",
        "+fetch",
        "--as",
        _identity(args, "user"),
        "--api-version",
        str(_value(args, "api_version", "v2")),
    ]
    _add(options, "--doc", _value(args, "doc"))
    _add(options, "--limit", _value(args, "limit"))
    _add(options, "--offset", _value(args, "offset"))
    _add_format(options)
    return _json(_run(options))


def _markdown_fetch(args: dict[str, Any], **_: Any) -> str:
    options = ["markdown", "+fetch", "--as", _identity(args)]
    _add(options, "--file-token", _value(args, "file_token"))
    _add(options, "--output", _value(args, "output"))
    _add_bool(options, "--overwrite", _value(args, "overwrite", False))
    _add_format(options)
    return _json(_run(options))


def _markdown_create(args: dict[str, Any], **_: Any) -> str:
    options = ["markdown", "+create", "--as", _identity(args)]
    _add(options, "--name", _value(args, "name"))
    _add(options, "--content", _value(args, "content"))
    _add(options, "--file", _value(args, "file"))
    _add(options, "--folder-token", _value(args, "folder_token"))
    _add_bool(options, "--dry-run", _value(args, "dry_run", False))
    _add_format(options)
    return _json(_run(options))


def _messages_search(args: dict[str, Any], **_: Any) -> str:
    options = ["im", "+messages-search", "--as", "user"]
    _add(options, "--query", _value(args, "query"))
    _add(options, "--chat-id", _value(args, "chat_id"))
    _add(options, "--chat-type", _value(args, "chat_type"))
    _add(options, "--sender", _value(args, "sender"))
    _add(options, "--sender-type", _value(args, "sender_type"))
    _add(options, "--start", _value(args, "start"))
    _add(options, "--end", _value(args, "end"))
    _add(options, "--page-size", _value(args, "page_size", 20))
    _add_bool(options, "--page-all", _value(args, "page_all", False))
    _add_bool(options, "--is-at-me", _value(args, "is_at_me", False))
    _add_format(options)
    return _json(_run(options))


def _messages_get(args: dict[str, Any], **_: Any) -> str:
    options = ["im", "+messages-mget", "--as", _identity(args)]
    _add(options, "--message-ids", _comma(_value(args, "message_ids", "")))
    _add_format(options)
    return _json(_run(options))


def _chat_messages_list(args: dict[str, Any], **_: Any) -> str:
    options = ["im", "+chat-messages-list", "--as", _identity(args)]
    _add(options, "--chat-id", _value(args, "chat_id"))
    _add(options, "--user-id", _value(args, "user_id"))
    _add(options, "--start", _value(args, "start"))
    _add(options, "--end", _value(args, "end"))
    _add(options, "--sort", _value(args, "sort", "desc"))
    _add(options, "--page-size", _value(args, "page_size", 50))
    _add(options, "--page-token", _value(args, "page_token"))
    _add_format(options)
    return _json(_run(options))


def _tasks_list(args: dict[str, Any], **_: Any) -> str:
    options = ["task", "+get-my-tasks", "--as", "user"]
    _add(options, "--query", _value(args, "query"))
    _add(options, "--created_at", _value(args, "created_at"))
    _add(options, "--due-start", _value(args, "due_start"))
    _add(options, "--due-end", _value(args, "due_end"))
    if "complete" in args:
        _add_bool(options, "--complete", args.get("complete"))
    _add_bool(options, "--page-all", _value(args, "page_all", True))
    _add_format(options)
    return _json(_run(options))


def _task_create(args: dict[str, Any], **_: Any) -> str:
    options = ["task", "+create", "--as", _identity(args)]
    _add(options, "--summary", _value(args, "summary"))
    _add(options, "--description", _value(args, "description"))
    _add(options, "--due", _value(args, "due"))
    _add(options, "--assignee", _value(args, "assignee"))
    _add(options, "--follower", _value(args, "follower"))
    _add(options, "--tasklist-id", _value(args, "tasklist_id"))
    _add(options, "--idempotency-key", _value(args, "idempotency_key"))
    _add_bool(options, "--dry-run", _value(args, "dry_run", False))
    _add_format(options)
    return _json(_run(options))


def _calendar_agenda(args: dict[str, Any], **_: Any) -> str:
    options = ["calendar", "+agenda", "--as", _identity(args)]
    _add(options, "--calendar-id", _value(args, "calendar_id"))
    _add(options, "--start", _value(args, "start"))
    _add(options, "--end", _value(args, "end"))
    _add_format(options)
    return _json(_run(options))


def _base_query(args: dict[str, Any], **_: Any) -> str:
    options = ["base", "+data-query", "--as", _identity(args)]
    _add(options, "--base-token", _value(args, "base_token"))
    _add(options, "--dsl", _value(args, "dsl"))
    _add_format(options)
    return _json(_run(options))


def _schema(name: str, description: str, properties: dict[str, Any], required: list[str] | None = None) -> dict[str, Any]:
    return {
        "name": name,
        "description": description,
        "parameters": {
            "type": "object",
            "properties": properties,
            "required": required or [],
        },
    }


TEXT = {"type": "string"}
IDENTITY = {"type": "string", "enum": ["user", "bot"], "description": "Feishu identity to use."}
BOOL = {"type": "boolean"}
INT = {"type": "integer"}


TOOLS = [
    (
        "lark_cli_doctor",
        "Check lark-cli installation, binding, and auth status.",
        {},
        [],
        _doctor,
    ),
    (
        "lark_docs_search",
        "Search personal-visible Feishu docs, wiki, and spreadsheets.",
        {"query": TEXT, "page_size": INT, "page_token": TEXT, "filter": {"type": "object"}, "identity": IDENTITY},
        ["query"],
        _docs_search,
    ),
    (
        "lark_docs_fetch",
        "Fetch Feishu document content by URL or token.",
        {"doc": TEXT, "api_version": {"type": "string", "enum": ["v1", "v2"]}, "limit": INT, "offset": INT, "identity": IDENTITY},
        ["doc"],
        _docs_fetch,
    ),
    (
        "lark_markdown_fetch",
        "Fetch a Feishu Drive Markdown file by token.",
        {"file_token": TEXT, "output": TEXT, "overwrite": BOOL, "identity": IDENTITY},
        ["file_token"],
        _markdown_fetch,
    ),
    (
        "lark_markdown_create",
        "Create a Markdown file in Feishu Drive.",
        {"name": TEXT, "content": TEXT, "file": TEXT, "folder_token": TEXT, "dry_run": BOOL, "identity": IDENTITY},
        [],
        _markdown_create,
    ),
    (
        "lark_messages_search",
        "Search Feishu messages visible to the user.",
        {"query": TEXT, "chat_id": TEXT, "chat_type": TEXT, "sender": TEXT, "sender_type": TEXT, "start": TEXT, "end": TEXT, "page_size": INT, "page_all": BOOL, "is_at_me": BOOL},
        [],
        _messages_search,
    ),
    (
        "lark_messages_get",
        "Batch fetch Feishu messages by message IDs.",
        {"message_ids": TEXT, "identity": IDENTITY},
        ["message_ids"],
        _messages_get,
    ),
    (
        "lark_chat_messages_list",
        "List messages in a Feishu chat or P2P conversation.",
        {"chat_id": TEXT, "user_id": TEXT, "start": TEXT, "end": TEXT, "sort": {"type": "string", "enum": ["asc", "desc"]}, "page_size": INT, "page_token": TEXT, "identity": IDENTITY},
        [],
        _chat_messages_list,
    ),
    (
        "lark_tasks_list",
        "List Feishu tasks assigned to the user.",
        {"query": TEXT, "created_at": TEXT, "due_start": TEXT, "due_end": TEXT, "complete": BOOL, "page_all": BOOL},
        [],
        _tasks_list,
    ),
    (
        "lark_task_create",
        "Create a Feishu task.",
        {"summary": TEXT, "description": TEXT, "due": TEXT, "assignee": TEXT, "follower": TEXT, "tasklist_id": TEXT, "idempotency_key": TEXT, "dry_run": BOOL, "identity": IDENTITY},
        ["summary"],
        _task_create,
    ),
    (
        "lark_calendar_agenda",
        "Read Feishu calendar agenda.",
        {"calendar_id": TEXT, "start": TEXT, "end": TEXT, "identity": IDENTITY},
        [],
        _calendar_agenda,
    ),
    (
        "lark_base_query",
        "Query Feishu Base data with lark-cli LiteQuery DSL.",
        {"base_token": TEXT, "dsl": TEXT, "identity": IDENTITY},
        ["base_token", "dsl"],
        _base_query,
    ),
]


def register(ctx) -> None:
    for name, description, properties, required, handler in TOOLS:
        ctx.register_tool(
            name=name,
            toolset=TOOLSET,
            schema=_schema(name, description, properties, required),
            handler=handler,
            check_fn=_check_lark_cli,
            emoji="",
        )
