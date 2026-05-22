# Changelog

All notable changes to hermes-feishu-zh will be documented in this file.

## [0.2.1] - 2026-05-22

### Added
- 8 new Chinese translation rules (77→85)
- Error messages: `未连接`, `发送失败`, `更新消息失败`, `图片文件不存在`, `图片上传失败`, `飞书图片上传缺少 image_key`, `文件不存在`, `文件上传失败`, `飞书文件上传缺少 file_key`, `飞书发送失败`
- Complete coverage of all user-visible Feishu strings

### Changed
- Updated version to 0.2.1
- Updated README with bilingual support and clearer structure

## [0.2.0] - 2026-05-21

### Added
- 19 new rules for feishu_comment_rules.py CLI output (58→77)
- Rules covering: rule files, pairing files, top-level config, document rules
- Add/remove commands, unknown command prompts, check result output

### Changed
- Version bumped to 0.2.0

## [0.1.0] - 2026-05-20

### Added
- Initial release
- 58 Chinese translation rules for feishu.py and run.py
- lark-cli-toolbox plugin (12 tools for Feishu docs/messages/tasks)
- Config merge for Chinese Feishu display settings
- Source code Chinese labels patch (enhanced mode)
- Two profiles: stable (config only) + enhanced (source patch)
- Backup, rollback, and verification support
- Comprehensive test suite (test-zh.py)
- GitHub Actions CI
- MIT License
