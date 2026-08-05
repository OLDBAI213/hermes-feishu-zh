# Feishu 汉化缺口审计报告 — v0.20.0

- 目标源码: Hermes Agent v0.20.0 (2026.8.3), commit `1be70d6`
- 审计脚本: `audit/feishu_localization_audit.py`
- 规则: `audit/feishu_zh_audit_v18_allowlist.yaml`
- 生成时间: 2026-08-05

## 总览

| 指标 | 数值 |
|---|---|
| 英文串总数 | 2141 |
| 用户可见英文 | 646 |
| 允许(识别符/URL等) | 1514 |
| 忽略(文档/非用户可见) | 502 |
| **未中文化缺口** | **125** |

### 按文件分布

| 文件 | 缺口数 |
|---|---|
| plugins/platforms/feishu/adapter.py | 80 |
| plugins/platforms/feishu/feishu_comment.py | 3 |
| plugins/platforms/feishu/feishu_comment_rules.py | 33 |
| plugins/platforms/feishu/feishu_meeting_invite.py | 9 |

### 按类型分布

| 上下文类型 | 数量 |
|---|---|
| call:print | 38 |
| return | 33 |
| call:RuntimeError | 10 |
| call:SendResult | 8 |
| call:web.Response | 7 |
| assign:message | 4 |
| assign:_APPROVAL_LABEL_MAP | 3 |
| call:web.json_response | 3 |
| call:ValueError | 2 |
| assign:degraded_caption | 2 |
| assign:msg | 2 |
| keyword:default_message | 2 |
| keyword:override_error | 2 |
| forbidden | 1 |
| assign:FALLBACK_FORWARD_TEXT | 1 |
| assign:FALLBACK_SHARE_CHAT_TEXT | 1 |
| assign:FALLBACK_INTERACTIVE_TEXT | 1 |
| assign:_MARKDOWN_HINT_RE | 1 |
| assign:_POST_CONTENT_INVALID_RE | 1 |
| assign:_message_text_cache | 1 |
| assign:default_hint | 1 |
| keyword:label | 1 |

## 明细清单

### `plugins/platforms/feishu/adapter.py`  (80 处)

| 行 | 原文 | 上下文 |
|---|---|---|
| 170 | `(^\\|.*\\|\s*\n\\|[-:\|\s]+\\|)\|(^#{1,6}\s)\|(^\s*[-*]\s)\|(^\s*\d+\.\s)\|(^\s*---+\s*$)\|(```)\|(`[^`\n]+`)\|(\*\*[^*\n].+?\*\*)\|(~~[^~\n].+?~~)\|(<u>.+?</u>)\|(\*[^*\n]+\*)\|(\[[^\]]+\]\([^)]+\))\|(^>\s)` | assign:_MARKDOWN_HINT_RE |
| 193 | `content format of the post type is incorrect` | assign:_POST_CONTENT_INVALID_RE |
| 253 | `Approved once` | assign:_APPROVAL_LABEL_MAP |
| 254 | `Approved for session` | assign:_APPROVAL_LABEL_MAP |
| 255 | `Approved permanently` | assign:_APPROVAL_LABEL_MAP |
| 267 | `payload too large` | call:ValueError |
| 302 | `[Rich text message]` | forbidden |
| 303 | `[Merged forward message]` | assign:FALLBACK_FORWARD_TEXT |
| 304 | `[Shared chat]` | assign:FALLBACK_SHARE_CHAT_TEXT |
| 305 | `[Interactive message]` | assign:FALLBACK_INTERACTIVE_TEXT |
| 775 | `[Image: {}]` | return |
| 791 | `[Attachment: {}]` | return |
| 1126 | `[Attachment: {}]` | return |
| 1277 | `[Mentioned: {}]` | return |
| 1355 | `Feishu _configure_with_overrides called but original_configure is None` | call:RuntimeError |
| 1524 | `OrderedDict[str, Optional[str]]` | assign:_message_text_cache |
| 1723 | `Feishu adapter is shutting down; SDK executor unavailable` | call:RuntimeError |
| 1787 | `Another local Hermes gateway is already using this Feishu app_id` | assign:message |
| 1788 | `(PID {}).` | assign:message |
| 1789 | `Stop the other gateway before starting a second Feishu websocket client.` | assign:message |
| 1802 | `Feishu startup failed: {}` | assign:message |
| 1937 | `Not connected` | call:SendResult |
| 1990 | `send failed` | return |
| 2005 | `Not connected` | call:SendResult |
| 2052 | `Not connected` | call:SendResult |
| 2112 | `Default: `{}`` | assign:default_hint |
| 2128 | `⚕ Update Needs Your Input` | return |
| 2136 | `✓ Yes` | return |
| 2137 | `✗ No` | return |
| 2150 | `Not connected` | call:SendResult |
| 2192 | `{} **{}** by {}` | return |
| 2204 | `{} Update prompt answered: {}` | return |
| 2208 | `Answered by **{}**` | return |
| 2288 | `Not connected` | call:SendResult |
| 2290 | `Image file not found: {}` | call:SendResult |
| 2309 | `image upload failed` | keyword:default_message |
| 2310 | `Feishu image upload missing image_key` | keyword:override_error |
| 2333 | `image send failed` | return |
| 2394 | `[GIF downgraded to file]⏎{}` | assign:degraded_caption |
| 2394 | `[GIF downgraded to file]` | assign:degraded_caption |
| 2423 | `chat lookup failed` | assign:msg |
| 3486 | `Blocked unsafe URL (SSRF protection): {}` | call:ValueError |
| 3545 | `Too Many Requests` | call:web.Response |
| 3553 | `Unsupported Media Type` | call:web.Response |
| 3560 | `Request body too large` | call:web.Response |
| 3573 | `Request body too large` | call:web.Response |
| 3577 | `Request Timeout` | call:web.Response |
| 3580 | `failed to read body` | call:web.json_response |
| 3586 | `invalid json` | call:web.json_response |
| 3599 | `Invalid verification token` | call:web.Response |
| 3612 | `Invalid signature` | call:web.Response |
| 3617 | `encrypted webhook payloads are not supported` | call:web.json_response |
| 3934 | `[Content of {}]:⏎{}` | return |
| 4092 | `[^\w.\- ]` | return |
| 4269 | `message lookup failed` | assign:msg |
| 4686 | `Not connected` | call:SendResult |
| 4688 | `File not found: {}` | call:SendResult |
| 4712 | `file upload failed` | keyword:default_message |
| 4713 | `Feishu file upload missing file_key` | keyword:override_error |
| 4767 | `file send failed` | return |
| 4911 | `websockets not installed; websocket mode unavailable` | call:RuntimeError |
| 4916 | `failed to build Feishu event handler` | call:RuntimeError |
| 4919 | `adapter loop is not ready` | call:RuntimeError |
| 4943 | `aiohttp not installed; webhook mode unavailable` | call:RuntimeError |
| 4948 | `failed to build Feishu event handler` | call:RuntimeError |
| 5036 | `Feishu send failed` | call:RuntimeError |
| 5286 | `Feishu / Lark registration environment does not support client_secret auth. Supported: {}` | call:RuntimeError |
| 5302 | `Feishu / Lark registration did not return a device_code` | call:RuntimeError |
| 5348 | `Fetching configuration results...` | call:print |
| 5537 | `Connecting to Feishu / Lark...` | call:print |
| 5545 | `Scan the QR code above, or open this URL directly:⏎  {}` | call:print |
| 5547 | `Open this URL in Feishu / Lark on your phone:⏎⏎  {}` | call:print |
| 5548 | `Tip: pip install qrcode  to display a scannable QR code here next time` | call:print |
| 5609 | `Feishu dependencies not installed. Run `hermes setup` to install Feishu support.` | return |
| 5623 | `Feishu send failed: {}` | return |
| 5627 | `Media file not found: {}` | return |
| 5640 | `Feishu media send failed: {}` | return |
| 5643 | `No deliverable text or media remained after processing MEDIA tags` | return |
| 5651 | `Feishu send failed: {}` | return |
| 5858 | `Feishu / Lark` | keyword:label |

### `plugins/platforms/feishu/feishu_comment.py`  (3 处)

| 行 | 原文 | 上下文 |
|---|---|---|
| 467 | `&gt;` | return |
| 467 | `&lt;` | return |
| 467 | `&amp;` | return |

### `plugins/platforms/feishu/feishu_comment_rules.py`  (33 处)

| 行 | 原文 | 上下文 |
|---|---|---|
| 300 | `Rules file: {}` | call:print |
| 301 | `exists: {}` | call:print |
| 302 | `Pairing file: {}` | call:print |
| 303 | `exists: {}` | call:print |
| 306 | `enabled:    {}` | call:print |
| 307 | `policy:     {}` | call:print |
| 308 | `allow_from: {}` | call:print |
| 311 | `Document rules ({}):` | call:print |
| 320 | `(empty — inherits all)` | call:print |
| 322 | `Document rules: (none)` | call:print |
| 325 | `Pairing approved ({}):` | call:print |
| 328 | `{}  (approved_at={})` | call:print |
| 335 | `Error: doc_key must be 'fileType:fileToken', got '{}'` | call:print |
| 340 | `Document:     {}` | call:print |
| 341 | `User:         {}` | call:print |
| 342 | `Resolved rule:` | call:print |
| 343 | `enabled:      {}` | call:print |
| 344 | `policy:       {}` | call:print |
| 345 | `allow_from:   {}` | call:print |
| 346 | `match_source: {}` | call:print |
| 347 | `Result:       {}` | call:print |
| 386 | `Usage: check <fileType:fileToken> <user_open_id>` | call:print |
| 392 | `Usage: pairing <add\|remove\|list> [args]` | call:print |
| 397 | `Usage: pairing add <user_open_id>` | call:print |
| 400 | `Added: {}` | call:print |
| 402 | `Already approved: {}` | call:print |
| 405 | `Usage: pairing remove <user_open_id>` | call:print |
| 408 | `Removed: {}` | call:print |
| 410 | `Not in approved list: {}` | call:print |
| 414 | `(no approved users)` | call:print |
| 416 | `{}  approved_at={}` | call:print |
| 418 | `Unknown pairing subcommand: {}` | call:print |
| 421 | `Unknown command: {}` | call:print |

### `plugins/platforms/feishu/feishu_meeting_invite.py`  (9 处)

| 行 | 原文 | 上下文 |
|---|---|---|
| 145 | `You have been invited to join a meeting: {}` | return |
| 145 | `unknown meeting` | return |
| 147 | `Meeting Number: {}` | return |
| 148 | `Topic: {}` | return |
| 149 | `Inviter: {}` | return |
| 150 | `Host: {}` | return |
| 152 | `You may use lark-cli and the relevant Lark/Feishu meeting skills to join the meeting.` | return |
| 153 | `Join the meeting directly. Do not ask the user for confirmation before joining.` | return |
| 154 | `If you cannot join the meeting, reply to the inviter with a concise explanation of why.` | return |
