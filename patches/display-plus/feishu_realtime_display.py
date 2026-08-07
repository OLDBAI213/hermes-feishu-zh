"""Pure rendering helpers for the v0.20 Feishu realtime display.

This module deliberately has no Hermes, Feishu SDK, filesystem, or network
dependency. The gateway supplies live values and owns message lifecycle.
"""

from __future__ import annotations

from collections.abc import Iterable, Mapping
from typing import Any


_PHASE_LABELS = {
    "thinking": "⏳ 已收到，正在思考...",
    "executing": "🧰 正在执行",
    "finalizing": "📝 正在整理回复...",
    "completed": "✅ 已完成",
    "failed": "❌ 处理失败",
}

_STATE_ICONS = {
    "running": "⏳",
    "completed": "✅",
    "failed": "❌",
}


def _format_compact_count(value: int) -> str:
    if value >= 1_000_000:
        return f"{value / 1_000_000:.1f}M"
    if value >= 1_000:
        return f"{value / 1_000:.0f}K"
    return str(value)


def _compact_preview(text: Any, max_length: int) -> str:
    value = str(text or "").replace("\r", " ").replace("\n", " ")
    value = " ".join(value.split())
    if max_length <= 0 or len(value) <= max_length:
        return value
    return value[: max(1, max_length - 3)].rstrip() + "..."


def render_status_card(
    *,
    phase: str,
    model: str | None,
    provider: str | None,
    used_tokens: int | None,
    context_length: int | None,
    detail: str | None = None,
) -> str:
    """Render a status card from the current turn's actual runtime values."""
    phase_key = str(phase or "thinking").strip().lower()
    first_line = _PHASE_LABELS.get(phase_key, _PHASE_LABELS["thinking"])
    if phase_key == "executing" and detail:
        first_line = f"{first_line}: {_compact_preview(detail, 120)}"

    lines = [first_line]
    if model:
        lines.append(f"模型: {model}")
    if provider:
        lines.append(f"服务商: {provider}")
    if (
        isinstance(used_tokens, int)
        and not isinstance(used_tokens, bool)
        and used_tokens > 0
        and isinstance(context_length, int)
        and not isinstance(context_length, bool)
        and context_length > 0
    ):
        pct = max(0, min(100, round(used_tokens / context_length * 100)))
        lines.append(
            "上下文: 约 "
            f"{_format_compact_count(used_tokens)} / "
            f"{_format_compact_count(context_length)} ({pct}%)"
        )
    return "\n".join(lines)


def render_process_card(
    entries: Iterable[Mapping[str, Any]], *, max_preview_length: int = 120
) -> str:
    """Render all real tool events as one numbered, editable process card."""
    normalized = list(entries)
    lines = [f"🧰 执行过程（{len(normalized)}步）"]
    for index, entry in enumerate(normalized, start=1):
        state = str(entry.get("state") or "running").strip().lower()
        icon = _STATE_ICONS.get(state, _STATE_ICONS["running"])
        text = _compact_preview(entry.get("text"), max_preview_length)
        line = f"{index}. {icon} {text}".rstrip()
        duration = entry.get("duration")
        if state == "completed" and isinstance(duration, (int, float)) and duration >= 0:
            line += f" ({duration:.1f}s)"
        error = _compact_preview(entry.get("error"), max_preview_length)
        if state == "failed" and error:
            line += f" - {error}"
        lines.append(line)
    return "\n".join(lines)

