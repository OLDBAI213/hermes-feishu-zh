# 更新日志

hermes-feishu-zh 的所有重要变更都会记录在此文件。

## [0.2.4] - 2026-05-24

### 修复
- 修复 `Remove-Installation` 中 `$Python` 变量作用域 bug，卸载功能恢复正常
- 修复 `FALLBACK_EMOJI_TEXT` 替换丢失变量赋值，运行时不再 NameError
- 修复 `_web_response()` 被替换成裸 dict，保持 API 响应结构一致

### 优化
- 完善 README，增加痛点描述和 lark-cli 使用示例
- 添加 GitHub Topics 提高可发现性

## [0.2.3] - 2026-05-23

### 新增
- 源码标记覆盖：飞书工具进度中文标签、浏览器工具标签、进程标题、失败提示、结构化 post 可读性标记
- 发布证据记录：114 条替换规则 + 37 个源码标记，142 个包源码检查通过
- 显示和适配边界文档，后续工作可迁移到 `hermes-feishu-display-plus` 和 `hermes-feishu-adapter-optimization`

### 变更
- 明确项目范围：本包是飞书中文化包，不是显示优化或适配优化包
- 更新 README 和 manifest 措辞，避免混淆中文化、显示美化、浏览器自动化和飞书适配能力
- 加固 `tests/test-zh-display.ps1`，当 `hermes` 是 PowerShell 函数且无 `Source` 路径时回退到 `hermes.exe`

### 验证
- `python tests\test-zh.py --source`：114 条替换规则 + 37 个源码标记，142 通过，0 失败，0 警告
- `powershell.exe -ExecutionPolicy Bypass -File tests\test-zh-display.ps1`：24 通过，0 失败

## [0.2.1] - 2026-05-22

### 新增
- 8 条新中文翻译规则（77→85）
- 错误消息：`未连接`、`发送失败`、`更新消息失败`、`图片文件不存在`、`图片上传失败`、`飞书图片上传缺少 image_key`、`文件不存在`、`文件上传失败`、`飞书文件上传缺少 file_key`、`飞书发送失败`
- 飞书所有用户可见字符串完整覆盖

### 变更
- 版本更新到 0.2.1
- 更新 README 双语支持和更清晰的结构

## [0.2.0] - 2026-05-21

### 新增
- 19 条新规则用于 feishu_comment_rules.py CLI 输出（58→77）
- 规则覆盖：规则文件、配对文件、顶层配置、文档规则
- 添加/删除命令、未知命令提示、检查结果输出

### 变更
- 版本更新到 0.2.0

## [0.1.0] - 2026-05-20

### 新增
- 首次发布
- 58 条中文翻译规则用于 feishu.py 和 run.py
- lark-cli-toolbox 插件（12 个飞书文档/消息/任务工具）
- 中文飞书显示配置合并
- 源码中文标签补丁（增强模式）
- 两种配置：稳定版（仅配置）+ 增强版（源码补丁）
- 备份、回滚和验证支持
- 完整测试套件（test-zh.py）
- GitHub Actions CI
- MIT 许可证
