# Release Check

Last local validation: 2026-05-20

Validated on Windows with Hermes Agent v0.14.0.

Checks passed:

- package structure check
- PowerShell parser check for `install.ps1`, `verify.ps1`, and `tests/check-package.ps1`
- no local machine path or secret-like value found in release files
- `install.ps1 -VerifyOnly` against an existing Hermes home
- `install.ps1 -Profile stable` install
- repeated stable install without duplicate config list entries
- `install.ps1 -Rollback latest`
- post-rollback verification

Known notes:

- Remote install commands still use `<owner>` until the GitHub repository owner is chosen.
- `user_identity` warning from `lark-cli doctor` is expected for `bot-only` binding.
- Enhanced mode patches Hermes source and must be revalidated after Hermes Feishu adapter changes.
