# Troubleshooting

## Hermes home not found

Set `HERMES_HOME` or pass `-HermesHome`:

```powershell
$env:HERMES_HOME = "C:\Users\<you>\.hermes"
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

## lark-cli doctor fails

Bind `lark-cli` to the Hermes Feishu app:

```powershell
lark-cli config bind --source hermes --identity bot-only
```

If `user_identity` is only a warning, bot identity is still usable. Personal docs, calendar, and user-only resources can require a user login.

## Gateway result looks failed

On Windows, the Scheduled Task result can show a non-zero value after a detached or stopped long-running process. Prefer these checks:

```powershell
hermes gateway status
Get-Content "$env:HERMES_HOME\gateway_state.json"
```

The useful state is `gateway_state = running` and `platforms.feishu.state = connected`.

## Enhanced patch fails

Use stable mode:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Profile stable
```

Enhanced mode patches Hermes source. If Hermes changed the Feishu adapter, the replacement markers may no longer match.

## Chinese display not visible

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\verify.ps1
```

Expected config:

```text
display.language = zh
display.gateway_locale = zh
platforms.feishu.extra.outbound_format = post
```

## Restore previous state

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Rollback latest
```
