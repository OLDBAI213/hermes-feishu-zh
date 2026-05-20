# Install

`hermes-feishu-zh` is Windows-first and expects an existing Hermes Agent install.

## Remote install

After publishing, replace `OLDBAI213` with the GitHub owner:

```powershell
iex (irm https://raw.githubusercontent.com/OLDBAI213/hermes-feishu-zh/main/install.ps1)
```

## Local install

From this repository:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

## Options

Stable profile:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Profile stable
```

Enhanced profile:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Profile enhanced
```

Verify only:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -VerifyOnly
```

Rollback latest backup:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Rollback latest
```

Restart Hermes gateway after install:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -RestartGateway
```

## Uninstall

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Uninstall
```

This removes the plugin, cleans config, and restores source files from backup.

## Profiles

`stable` is the default. It merges config, installs the `lark-cli-toolbox` plugin, and uses Feishu `post` output.

`enhanced` additionally patches Hermes Feishu source code so normal replies can use interactive card output. Use it only when you accept source patch compatibility checks after Hermes upgrades.

## lark-cli binding

The plugin can load without `lark-cli`, but tools need the CLI to be installed and bound:

```powershell
lark-cli config bind --source hermes --identity bot-only
```

`bot-only` is enough for bot/app API access. User-only resources such as personal calendar or private docs may require a user login later.
