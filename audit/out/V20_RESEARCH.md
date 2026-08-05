# 飞书汉化 v0.20.0 缺口研判清单

- 目标: Hermes Agent v0.20.0 (2026.8.3) 飞书源码汉化移植
- 生成: 2026-08-05, 自动对照旧汉化包 114 条替换规则
- 结论: 125 处缺口 = **可复用旧规则 55 + 需新翻译 67 + 误报 3**

| 类别 | 数量 | 含义 |
|---|---|---|
| 可复用旧规则 | 55 | 旧汉化包已有对应翻译，直接迁移 |
| 需新翻译 | 67 | v0.20.0 新代码，需要新写中文化 |
| 误报 | 3 | 类型标注/正则，编译脚本误判，无需处理 |

## adapter.py  (80 处)

| 行 | 类别 | 原文(v0.20.0) | 旧翻译(如可复用) |
|---|---|---|---|
| 170 | 误报 | `(^\\|.*\\|\s*\n\\|[-:\|\s]+\\|)\|(^#{1,6}\s)\|(^\s*[-*]\s)\|(^\s*\d+\.\s)\|(^\s*---+\s*$)\|(```)\|(`[^`\n]+`)\|(\*\*[^*\n].+?\*\*)\|(~~[^~\n].+?~~)\|(<u>.+?</u>)\|(\*[^*\n]+\*)\|(\[[^\]]+\]\([^)]+\))\|(^>\s)` | `(无需翻译)` |
| 193 | 误报 | `content format of the post type is incorrect` | `(无需翻译)` |
| 253 | 可复用旧规则 | `Approved once` | `"once": "已批准一次",     "session": "本轮会话已批准",     "always": "已永久批准",     ` |
| 254 | 可复用旧规则 | `Approved for session` | `"once": "已批准一次",     "session": "本轮会话已批准",     "always": "已永久批准",     ` |
| 255 | 可复用旧规则 | `Approved permanently` | `"once": "已批准一次",     "session": "本轮会话已批准",     "always": "已永久批准",     ` |
| 267 | 可复用旧规则 | `payload too large` | `return web.Response(status=413, text="请求体过大")` |
| 302 | 需新翻译 | `[Rich text message]` | `(需新翻译)` |
| 303 | 需新翻译 | `[Merged forward message]` | `(需新翻译)` |
| 304 | 可复用旧规则 | `[Shared chat]` | `FALLBACK_SHARE_CHAT_TEXT = "[共享聊天]"` |
| 305 | 需新翻译 | `[Interactive message]` | `(需新翻译)` |
| 775 | 需新翻译 | `[Image: {}]` | `(需新翻译)` |
| 791 | 需新翻译 | `[Attachment: {}]` | `(需新翻译)` |
| 1126 | 需新翻译 | `[Attachment: {}]` | `(需新翻译)` |
| 1277 | 需新翻译 | `[Mentioned: {}]` | `(需新翻译)` |
| 1355 | 需新翻译 | `Feishu _configure_with_overrides called but original_configure is None` | `(需新翻译)` |
| 1524 | 误报 | `OrderedDict[str, Optional[str]]` | `(无需翻译)` |
| 1723 | 需新翻译 | `Feishu adapter is shutting down; SDK executor unavailable` | `(需新翻译)` |
| 1787 | 需新翻译 | `Another local Hermes gateway is already using this Feishu app_id` | `(需新翻译)` |
| 1788 | 需新翻译 | `(PID {}).` | `(需新翻译)` |
| 1789 | 需新翻译 | `Stop the other gateway before starting a second Feishu websocket client.` | `(需新翻译)` |
| 1802 | 需新翻译 | `Feishu startup failed: {}` | `(需新翻译)` |
| 1937 | 可复用旧规则 | `Not connected` | `error="未连接"` |
| 1990 | 可复用旧规则 | `send failed` | `"发送失败"` |
| 2005 | 可复用旧规则 | `Not connected` | `error="未连接"` |
| 2052 | 可复用旧规则 | `Not connected` | `error="未连接"` |
| 2112 | 需新翻译 | `Default: `{}`` | `(需新翻译)` |
| 2128 | 可复用旧规则 | `⚕ Update Needs Your Input` | `"title": {"content": "⚕ 更新需要你确认", "tag": "plain_text"},` |
| 2136 | 需新翻译 | `✓ Yes` | `(需新翻译)` |
| 2137 | 需新翻译 | `✗ No` | `(需新翻译)` |
| 2150 | 可复用旧规则 | `Not connected` | `error="未连接"` |
| 2192 | 可复用旧规则 | `{} **{}** by {}` | `"content": f"{icon} **{label}**，操作者: {user_name}",` |
| 2204 | 可复用旧规则 | `{} Update prompt answered: {}` | `"title": {"content": f"{'✅' if yes else '❌'} 已回复更新确认: {label}", "tag":` |
| 2208 | 可复用旧规则 | `Answered by **{}**` | `{"tag": "markdown", "content": f"由 **{user_name}** 回复"},` |
| 2288 | 可复用旧规则 | `Not connected` | `error="未连接"` |
| 2290 | 可复用旧规则 | `Image file not found: {}` | `f"图片文件不存在: {image_path}"` |
| 2309 | 可复用旧规则 | `image upload failed` | `"图片上传失败"` |
| 2310 | 可复用旧规则 | `Feishu image upload missing image_key` | `"飞书图片上传缺少 image_key"` |
| 2333 | 可复用旧规则 | `image send failed` | `"图片发送失败"` |
| 2394 | 需新翻译 | `[GIF downgraded to file]⏎{}` | `(需新翻译)` |
| 2394 | 可复用旧规则 | `[GIF downgraded to file]` | `degraded_caption = f"[GIF 已转为文件发送]\n{caption}" if caption else "[GIF 已` |
| 2423 | 可复用旧规则 | `chat lookup failed` | `"会话查询失败"` |
| 3486 | 需新翻译 | `Blocked unsafe URL (SSRF protection): {}` | `(需新翻译)` |
| 3545 | 需新翻译 | `Too Many Requests` | `(需新翻译)` |
| 3553 | 可复用旧规则 | `Unsupported Media Type` | `return web.Response(status=415, text="不支持的媒体类型")` |
| 3560 | 需新翻译 | `Request body too large` | `(需新翻译)` |
| 3573 | 需新翻译 | `Request body too large` | `(需新翻译)` |
| 3577 | 可复用旧规则 | `Request Timeout` | `return web.Response(status=408, text="请求超时")` |
| 3580 | 需新翻译 | `failed to read body` | `(需新翻译)` |
| 3586 | 可复用旧规则 | `invalid json` | `return web.json_response({"code": 400, "msg": "无效 JSON"}, status=400)` |
| 3599 | 需新翻译 | `Invalid verification token` | `(需新翻译)` |
| 3612 | 可复用旧规则 | `Invalid signature` | `return web.Response(status=401, text="签名无效")` |
| 3617 | 需新翻译 | `encrypted webhook payloads are not supported` | `(需新翻译)` |
| 3934 | 需新翻译 | `[Content of {}]:⏎{}` | `(需新翻译)` |
| 4092 | 需新翻译 | `[^\w.\- ]` | `(需新翻译)` |
| 4269 | 可复用旧规则 | `message lookup failed` | `"消息查询失败"` |
| 4686 | 可复用旧规则 | `Not connected` | `error="未连接"` |
| 4688 | 可复用旧规则 | `File not found: {}` | `f"文件不存在: {file_path}"` |
| 4712 | 可复用旧规则 | `file upload failed` | `"文件上传失败"` |
| 4713 | 可复用旧规则 | `Feishu file upload missing file_key` | `"飞书文件上传缺少 file_key"` |
| 4767 | 可复用旧规则 | `file send failed` | `"文件发送失败"` |
| 4911 | 需新翻译 | `websockets not installed; websocket mode unavailable` | `(需新翻译)` |
| 4916 | 需新翻译 | `failed to build Feishu event handler` | `(需新翻译)` |
| 4919 | 需新翻译 | `adapter loop is not ready` | `(需新翻译)` |
| 4943 | 需新翻译 | `aiohttp not installed; webhook mode unavailable` | `(需新翻译)` |
| 4948 | 需新翻译 | `failed to build Feishu event handler` | `(需新翻译)` |
| 5036 | 可复用旧规则 | `Feishu send failed` | `RuntimeError("飞书发送失败")` |
| 5286 | 需新翻译 | `Feishu / Lark registration environment does not support client_secret auth. Supported: {}` | `(需新翻译)` |
| 5302 | 需新翻译 | `Feishu / Lark registration did not return a device_code` | `(需新翻译)` |
| 5348 | 需新翻译 | `Fetching configuration results...` | `(需新翻译)` |
| 5537 | 需新翻译 | `Connecting to Feishu / Lark...` | `(需新翻译)` |
| 5545 | 需新翻译 | `Scan the QR code above, or open this URL directly:⏎  {}` | `(需新翻译)` |
| 5547 | 需新翻译 | `Open this URL in Feishu / Lark on your phone:⏎⏎  {}` | `(需新翻译)` |
| 5548 | 需新翻译 | `Tip: pip install qrcode  to display a scannable QR code here next time` | `(需新翻译)` |
| 5609 | 需新翻译 | `Feishu dependencies not installed. Run `hermes setup` to install Feishu support.` | `(需新翻译)` |
| 5623 | 可复用旧规则 | `Feishu send failed: {}` | `return _error(f"飞书发送失败: {last_result.error}")` |
| 5627 | 可复用旧规则 | `Media file not found: {}` | `return _error(f"媒体文件不存在: {media_path}")` |
| 5640 | 可复用旧规则 | `Feishu media send failed: {}` | `return _error(f"飞书媒体发送失败: {last_result.error}")` |
| 5643 | 可复用旧规则 | `No deliverable text or media remained after processing MEDIA tags` | `return {"error": "没有可发送的文字或媒体内容"}` |
| 5651 | 可复用旧规则 | `Feishu send failed: {}` | `return _error(f"飞书发送失败: {last_result.error}")` |
| 5858 | 需新翻译 | `Feishu / Lark` | `(需新翻译)` |

## feishu_comment.py  (3 处)

| 行 | 类别 | 原文(v0.20.0) | 旧翻译(如可复用) |
|---|---|---|---|
| 467 | 需新翻译 | `&gt;` | `(需新翻译)` |
| 467 | 需新翻译 | `&lt;` | `(需新翻译)` |
| 467 | 需新翻译 | `&amp;` | `(需新翻译)` |

## feishu_comment_rules.py  (33 处)

| 行 | 类别 | 原文(v0.20.0) | 旧翻译(如可复用) |
|---|---|---|---|
| 300 | 可复用旧规则 | `Rules file: {}` | `print(f"规则文件: {RULES_FILE}")` |
| 301 | 需新翻译 | `exists: {}` | `(需新翻译)` |
| 302 | 需新翻译 | `Pairing file: {}` | `(需新翻译)` |
| 303 | 需新翻译 | `exists: {}` | `(需新翻译)` |
| 306 | 可复用旧规则 | `enabled:    {}` | `"  启用:       {rule.enabled}"` |
| 307 | 可复用旧规则 | `policy:     {}` | `"  策略:       {rule.policy}"` |
| 308 | 需新翻译 | `allow_from: {}` | `(需新翻译)` |
| 311 | 可复用旧规则 | `Document rules ({}):` | `print(f"文档规则 ({len(cfg.documents)}):")` |
| 320 | 需新翻译 | `(empty — inherits all)` | `(需新翻译)` |
| 322 | 可复用旧规则 | `Document rules: (none)` | `print("文档规则: 无")` |
| 325 | 可复用旧规则 | `Pairing approved ({}):` | `print(f"已配对用户 ({len(approved)}):")` |
| 328 | 需新翻译 | `{}  (approved_at={})` | `(需新翻译)` |
| 335 | 可复用旧规则 | `Error: doc_key must be 'fileType:fileToken', got '{}'` | `"错误: doc_key 必须是 'fileType:fileToken'，当前是 '{doc_key}'"` |
| 340 | 可复用旧规则 | `Document:     {}` | `"文档:       {doc_key}"` |
| 341 | 可复用旧规则 | `User:         {}` | `"用户:       {user_open_id}"` |
| 342 | 可复用旧规则 | `Resolved rule:` | `"命中规则:"` |
| 343 | 可复用旧规则 | `enabled:      {}` | `"  启用:       {rule.enabled}"` |
| 344 | 可复用旧规则 | `policy:       {}` | `"  策略:       {rule.policy}"` |
| 345 | 需新翻译 | `allow_from:   {}` | `(需新翻译)` |
| 346 | 需新翻译 | `match_source: {}` | `(需新翻译)` |
| 347 | 可复用旧规则 | `Result:       {}` | `"结果:       {'允许' if allowed else '拒绝'}"` |
| 386 | 可复用旧规则 | `Usage: check <fileType:fileToken> <user_open_id>` | `"用法: check <fileType:fileToken> <user_open_id>"` |
| 392 | 可复用旧规则 | `Usage: pairing <add\|remove\|list> [args]` | `"用法: pairing <add\|remove\|list> [args]"` |
| 397 | 可复用旧规则 | `Usage: pairing add <user_open_id>` | `"用法: pairing add <user_open_id>"` |
| 400 | 可复用旧规则 | `Added: {}` | `f"已添加: {args[2]}"` |
| 402 | 需新翻译 | `Already approved: {}` | `(需新翻译)` |
| 405 | 需新翻译 | `Usage: pairing remove <user_open_id>` | `(需新翻译)` |
| 408 | 可复用旧规则 | `Removed: {}` | `f"已移除: {args[2]}"` |
| 410 | 需新翻译 | `Not in approved list: {}` | `(需新翻译)` |
| 414 | 需新翻译 | `(no approved users)` | `(需新翻译)` |
| 416 | 需新翻译 | `{}  approved_at={}` | `(需新翻译)` |
| 418 | 需新翻译 | `Unknown pairing subcommand: {}` | `(需新翻译)` |
| 421 | 需新翻译 | `Unknown command: {}` | `(需新翻译)` |

## feishu_meeting_invite.py  (9 处)

| 行 | 类别 | 原文(v0.20.0) | 旧翻译(如可复用) |
|---|---|---|---|
| 145 | 需新翻译 | `You have been invited to join a meeting: {}` | `(需新翻译)` |
| 145 | 需新翻译 | `unknown meeting` | `(需新翻译)` |
| 147 | 需新翻译 | `Meeting Number: {}` | `(需新翻译)` |
| 148 | 需新翻译 | `Topic: {}` | `(需新翻译)` |
| 149 | 需新翻译 | `Inviter: {}` | `(需新翻译)` |
| 150 | 需新翻译 | `Host: {}` | `(需新翻译)` |
| 152 | 需新翻译 | `You may use lark-cli and the relevant Lark/Feishu meeting skills to join the meeting.` | `(需新翻译)` |
| 153 | 需新翻译 | `Join the meeting directly. Do not ask the user for confirmation before joining.` | `(需新翻译)` |
| 154 | 需新翻译 | `If you cannot join the meeting, reply to the inviter with a concise explanation of why.` | `(需新翻译)` |
