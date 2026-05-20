# hermes-feishu-zh

Hermes Agent community extension for Windows + Feishu Chinese display.

This is not an official Hermes Agent project. It is a community extension that helps Windows Hermes users turn on Chinese Feishu display, stable Feishu `post` output, and the optional `lark-cli` toolbox without replacing their existing Hermes config.

## Install

Replace `OLDBAI213` with the GitHub owner after this project is published:

```powershell
iex (irm https://raw.githubusercontent.com/OLDBAI213/hermes-feishu-zh/main/install.ps1)
```

Local checkout install:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

Default mode is `stable`. It:

- deep-merges Chinese Feishu display settings into `config.yaml`
- preserves existing model, API, Feishu credentials, sessions, and `.env`
- installs and enables `lark-cli-toolbox`
- uses Feishu `post` output for stable Markdown display
- creates a backup before changing files
- runs verification after install

## Enhanced Mode

Enhanced mode also patches Hermes Feishu source code for richer card output.

```powershell
iex (irm https://raw.githubusercontent.com/OLDBAI213/hermes-feishu-zh/main/install.ps1) -Profile enhanced
```

Use enhanced mode only when you accept source patch compatibility checks after Hermes upgrades. The installer backs up changed files and verifies the result.

## Verify

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -VerifyOnly
```

or:

```powershell
powershell -ExecutionPolicy Bypass -File .\verify.ps1
```

Verification checks Hermes, Feishu display config, source Chinese labels, the `lark-cli` plugin, Feishu payload modes, and gateway connection when available.

## Rollback

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Rollback latest
```

Backups are stored under:

```text
<HERMES_HOME>\backups\hermes-feishu-zh-<timestamp>
```

## Requirements

- Windows PowerShell or PowerShell 7
- Hermes Agent installed and working
- `HERMES_HOME` set, or Hermes discoverable through `hermes.exe`
- Feishu gateway already configured in Hermes
- Optional: `lark-cli` installed and bound to Hermes for toolbox features

Bind `lark-cli` to Hermes with bot identity:

```powershell
lark-cli config bind --source hermes --identity bot-only
```

## What This Changes

The installer may change:

- `<HERMES_HOME>\config.yaml`
- `<HERMES_HOME>\plugins\lark-cli-toolbox`
- `<HERMES_HOME>\hermes-agent\gateway\platforms\feishu.py`

It does not contain or ship API keys, Feishu secrets, user IDs, sessions, or tokens.

## Docs

- [Install](docs/install.md)
- [Upgrade](docs/upgrade.md)
- [Troubleshooting](docs/troubleshooting.md)
