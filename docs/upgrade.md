# Upgrade

The installer is idempotent. Running it again should not duplicate `plugins.enabled`, `platform_toolsets`, or `toolsets` entries.

## Update this extension

If installed from GitHub through a checkout:

```powershell
git pull --ff-only
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

If using the one-line remote command, run the same install command again after the repository is updated.

## After Hermes upgrades

Run verification first:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -VerifyOnly
```

If verification fails because source patch markers moved, reinstall stable mode:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Profile stable
```

Only use enhanced mode after verification supports the new Hermes version.

## Rollback

Restore the newest package backup:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Rollback latest
```

Backups live under:

```text
<HERMES_HOME>\backups\hermes-feishu-zh-<timestamp>
```

Each backup contains a `backup-manifest.json` plus the files that existed before install.

## Compatibility policy

- Stable profile should survive normal Hermes upgrades because it uses config and plugin surfaces.
- Enhanced profile may need patch updates after Hermes changes `gateway/platforms/feishu.py`.
- Secrets are not stored in this repository. Existing `.env` values stay in the user's Hermes home.
