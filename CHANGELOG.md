# Changelog

All notable changes to the claude-code-init project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.5.7] - 2026-05-01

### Fixed
- **Memory access_count 递增机制 (P0)**: `/remember` 命令新增 access_count 递增规则，每次 search/show 检索到记忆时自动递增计数，为 GC 提供准确数据基础。
- **Memory GC `/gc` 命令缺失 (P0)**: 新增 `commands/gc.md`，定义完整的 GC 流程（扫描 → 预览 → 执行），支持 `--dry-run` 和 `--auto` 无人值守模式。
- **10 个 SKILL.md 缺少回滚规范 (P0)**: 全部 Skill 新增"失败处理"章节——高风险（code-review/safe-refactoring/git-commit）包含 git stash 完整回滚；中风险（tdd-workflow/error-fix/project-init）包含步骤级回滚；低风险标注只读无需回滚。
- **smart-context.sh stdin 无超时保护 (P1)**: `cat` 读取 stdin 改为跨平台超时方案（优先 `timeout`，回退 `perl`，最后 `cat`），防止 hook 挂起。
- **smart-context.sh JSON 转义不完整 (P1)**: `json_escape` 函数增强——优先使用 `jq -Rs`，回退补充换行符和控制字符转义。
- **init.sh/init.ps1 全量复制 scripts/ 引发过度部署 (P1)**: `cp -r scripts/*` 改为白名单选择性复制，排除 `__pycache__/`、`check-env.sh`、`configure-gitignore.*`、`lib/common.sh` 等仅 init 使用的文件。

### Changed
- `package.json` 移除 `.claude/scripts/` 条目（已清空，所有脚本由 `scripts/` 部署）。
- 版本号同步：package.json、init.sh、init.ps1、CLAUDE.md → v1.5.7。

## [1.5.6] - 2026-05-01

### Fixed
- **Router ↔ Brainstorming 触发词冲突 (P0)**: 路由 `架构、方案、设计` 改为跳转「需求头脑风暴」技能而非 `/architect` 命令，消除与需求分析触发词的分派歧义。
- **code-review SKILL.md OWASP Top 10 缺失项 (P1)**: 安全清单补全 A04 不安全设计、A06 脆弱组件、A08 软件完整性、A09 日志监控、A10 SSRF。
- **Router 决策表触发词扩展 (P1)**: 每个路由条目新增关键字同义词（代码审计、error、fix、refactor、security、validate 等），提升触发匹配率。
- **Router 否定语义检测 (P1)**: 决策表前新增否定过滤规则（"不用/不要/跳过/取消/不需要"），防止否定式用户输入误触发技能路由。
- **smart-context.sh rm -rf 正则增强 (P1)**: 危险命令检测覆盖 `rm -rf` 标志任意顺序（`rm -r -f`）及长选项形式（`rm --recursive --force`），并检测命令链前缀。

### Changed
- 版本号同步：package.json、init.sh、init.ps1、CLAUDE.md → v1.5.6。

## [1.5.5] - 2026-05-01

### Fixed
- **smart-context.sh `exit 0` 阻断后续场景 (P0)**: 场景 2（安全文件）不再提前退出，场景 3~10 可达。`skillToActivate` 标志移入末尾统一 JSON 输出。
- **PROMPT.md 部署链断裂 (P0)**: PROMPT.md 从 `.claude/scripts/` 移动到 `scripts/`，确保被 init.sh 部署到目标项目。tmux-session.sh 的默认任务文件不再断链。
- **`.claude/scripts/` 过时 Python 副本 (P1)**: 删除 5 个版本不一致的 check_*.py 死代码文件及 `__pycache__/`。`scripts/` 成为唯一部署源。
- **`index.js` 无 `--version` 标志 (P2)**: 新增 `--version` / `-v` 参数。
- **`index.js` 无 `--project-path` 验证 (P2)**: 新增驱动器根目录、shell 元字符检测。
- **命令数量不一致 (P2)**: CLAUDE.md（17→20）、init.sh（18→20）统一为实际值。
- **`init.sh` 步骤命名误导 (P3)**: "复制 Python 校验脚本" → "复制校验脚本和 Shell 工具"。
- **`init.sh` 运行时 banner 版本号 v1.5.3→v1.5.5**: 之前遗漏的版本同步。
- **`init.sh` 命令列表补全**: 缺失 plan-eng-review、tdd 已补齐。

### Changed
- 版本号同步：package.json、init.sh、init.ps1、CLAUDE.md → v1.5.5。

## [1.5.4] - 2026-05-01

### Fixed
- **`.gitignore` 缺 `.env` 保护 (P0)**: 新增 `.env`、`.env.*`、`*.pem`、`*.key` 规则。
- **`check_secrets.py` 秘钥检测增强 (P1)**: 新增 Slack/Google OAuth/Stripe live key 检测模式。
- **`init.sh` 版本显示不一致 (P1)**: 运行时 banner 修正为 v1.5.4。
- **废弃 `plugin.json` 删除 (P1)**: 文件已废弃且版本停滞，已删除。
- **GUIDE.md 虚假声明修正 (P1)**: 插件安装说明从"自动具备"改为"手动安装"。
- **`sed '$a\'` macOS 兼容性 (P1)**: `configure-gitignore.sh` 改用便携式换行追加。
- **`CLAUDE_Template.md` 双版本行统一 (P1)**: 两条不同日期的版本声明合并为一条。
- **`init.sh` 步骤编号断裂 (P2)**: 修正为连续编号 1-14。
- **版本一致性 (P2)**: HANDOVER.md、MAINTENANCE-NOTES.md、GUIDE.md、CLAUDE.md 版本历史同步至 v1.5.4。
- **SOUL.md 更新至 v1.2.0 (P2)**: 项目自身 dogfood 最新模板，添加记忆规则/动态阈值引用。

### Added
- **`.gitattributes` 文件 (P1)**: 强制 LF（.sh/.py/.md）和 CRLF（.ps1）行尾，防止 Windows 克隆破坏 shebang。
- **测试覆盖扩展 (P1)**: 新增 11 个测试（init.sh/init.ps1 功能检查、Skills 存在性、Router 路由、安全性、跨平台），从 12 增至 23 个。

### Changed
- **`init.sh` 颜色定义统一 (P2)**: 内联颜色定义替换为 `source scripts/lib/common.sh`。
- **README.md 死链接修正**: SOUL_Template.md 路径修正为 SOUL.md。
- **`help.md` 命令表补充**: 新增 `/plan-eng-review` 和 `/tdd` 条目。

## [1.5.3] - 2026-05-01

### Fixed
- **Memory 系统路径骨折 (P0)**: 模板和文档统一描述单文件 MEMORY.md 记忆结构，替换废弃的多文件引用 (INDEX.md/decisions.md/bugs.md/patterns.md/context.md)。
- **静默覆盖用户数据 (P0)**: `init.sh` 和 `init.ps1` 中 CLAUDE.local.md 和 MEMORY.local.md 写入前添加存在性检查，`--force`/`-Force` 可跳过保护。
- **project-validate 幽灵脚本 (P0)**: 5 个缺失的 Python 校验脚本从 `scripts/` 复制到 `.claude/scripts/`。
- **Router 缺失条目 (P0)**: 决策表新增 code-explain 和 project-init 两个 Skills 的触发规则。
- **幽灵命令引用 (P1)**: 删除 `/ship`、`/clean`、`/canary`、`/benchmark`、`/cso`、`/office-hours` 6 个不存在命令的残留引用。
- **路径错误 (P1)**: `help.md` 修正 SOUL_Template.md 路径；`status.md` 修正 reports/ 路径为 `.claude/reports/`。
- **版本号升级**: package.json、CLAUDE.md、init.sh、init.ps1 统一升至 v1.5.3。

### Added
- 新增 `commands/plan-eng-review.md`：技术架构评审命令，支持可扩展性/安全性/可维护性/成本四维度评审。
- 新增 `commands/tdd.md`：TDD 工作流快捷命令（Red→Green→Refactor 循环）。

### Changed
- 6 个骨架命令 (commit/explain/fix/refactor/review/validate) 添加「快速参考」节，提供功能摘要和适用场景。

### Known Limitations
- **ROUTINE_Template.md** 定义了 YAML 例行任务结构但尚无执行引擎实现，规划于 v1.6.0。
- **complexity-rules.yaml** 与 **SOUL.md** 存在重叠的复杂度评分规则，规划于 v1.6.0 统一。

## [1.5.2] - 2026-04-30

### Fixed
- `template_version()` grep non-zero exit code crashing `init.sh` at step 10 when target CLAUDE.md lacks version marker.
- `--force` mode now skips plugin installation confirmation prompt for non-interactive execution.
- `--force` mode passes `--auto` to cc-discipline to prevent interaction in pipelines.
- OpenSpec install locked to `@1.3.1` and uses `--tools claude` flag.

### Changed
- 6 overlapping Commands (commit/fix/review/refactor/explain/validate) reduced to Skill reference entries.
- `scripts/check_secrets.py` synced with full version from `.claude/scripts/` (GitHub/AWS/JWT patterns + Markdown scanning).
- Version bumped to v1.5.2 across `init.sh` and `init.ps1`.
- `engines.node` raised to `>=18.0.0` (Node 16 EOL, `node --test` requires Node 18+).
- CI matrix drops Node 16; added `version-check` job for cross-file version consistency.
- Eliminated duplicate color/output-function definitions in 5 scripts; centralized via `scripts/lib/common.sh`.
- Cleaned up 3 dead-code blocks in `scripts/tmux-session.sh` (ROUTER_SKILL, CLAUDE_CMD, notify_completion).
- Fixed 3 incorrect step-number comments in `init.sh` (#7→#8, #13→#14, #16→#15).

## [1.5.1] - 2026-04-30

### Added
- SPEC_Template.md for feature-level spec generation.
- CI/CD pipeline (`.github/workflows/ci.yml`) for automated validation.
- Source==target equality check in `init.sh` Step 7, aligned with `init.ps1`.
- Automatic pre-commit installation in `init.sh`, unified with `init.ps1`.
- `Resolve-Path`-based `Test-SamePath` function in `init.ps1` for robust path comparison.
- Cached `detectPowerShell()` result in `index.js` to avoid redundant forks.

### Changed
- `check_secrets.py` now uses `yaml.safe_load()` for YAML config parsing with line-by-line fallback.
- `check_project_structure.py` fixed wildcard pattern handling in gitignore check.
- `validate_skills.sh` replaced `declare -A` (Bash 4+) with temp-file dedup for Bash 3.2+/macOS compatibility.
- `weekly-report.sh` added macOS `find` compatibility via platform detection.
- `tmux-session.sh` reports directory moved from `reports/` to `.claude/reports/`.
- `init.sh` pre-commit step now auto-installs via pip when missing.
- `CLAUDE.local.md` moved to `.claude/CLAUDE.local.md` for hidden directory compliance.

### Removed
- `docs/` rule removed from `configure-gitignore.ps1` and `.sh` to avoid accidental document exclusion.
- `update.ps1` (empty file) deleted.

### Fixed
- `init.ps1` path comparisons now use `Resolve-Path` instead of string `-eq`.
- `index.js` no longer calls `detectPowerShell()` twice.

## [1.5.0] - 2026-04-30

### Added
- Agent Teams parallel development (`/team`).
- gstack role system: CEO review, architect review, QA testing, overnight.
- Unattended long-running tasks (tmux + Ralph Wiggum plugin).
- Skills trigger optimizer (`trigger-optimizer.sh`).
- Weekly report generator (`weekly-report.sh`).
- Environment check script (`check-env.sh`).
- Project handover documentation (`docs/HANDOVER.md`).
- `.claude/scripts/` directory restructure.

### Changed
- `kld-sdd` replaced with `@fission-ai/openspec` (due to npm unpublishing).
- Renumbered init steps 1-17 in both `init.ps1` and `init.sh`.

### Fixed
- Command injection in `index.js`: `execSync(string)` replaced with `spawnSync(cmd, args[])`.
- Smart context hook regex fixes: `(rRf)` → `[rRf]`, `git push` → `git\s+push`.
- Pre-commit config paths restored to `.claude/scripts/` (correct by design for target projects).
- Hermedoc quoting in `init.sh`: `'EOF'` → `EOF` for date expansion.
- `package.json` orphan reference to non-existent `.claude/agents/` removed.

## [1.4.1] - 2026-04-28

### Fixed
- Removed misleading Skip parameter documentation.
- Added system dependency checks.
- Fixed silent failures in init scripts.

## [1.4.0] - 2026-04-28

### Changed
- Removed `_archived/` directory.
- Rewrote `SECURITY.md`.
- Added SOUL.md five-tier complexity assessment.

## [1.3.0] - 2026-04-28

### Changed
- Deleted `_archived/`.
- Enhanced README warnings.
- Hardened file paths.

## [1.2.0] - 2026-04-28

### Added
- Initial release with basic scaffolding functionality.

[Unreleased]: https://github.com/biandeshen/claude-code-init/compare/v1.5.4...HEAD
[1.5.4]: https://github.com/biandeshen/claude-code-init/compare/v1.5.3...v1.5.4
[1.5.3]: https://github.com/biandeshen/claude-code-init/compare/v1.5.2...v1.5.3
[1.5.2]: https://github.com/biandeshen/claude-code-init/compare/v1.5.1...v1.5.2
[1.5.1]: https://github.com/biandeshen/claude-code-init/compare/v1.5.0...v1.5.1
[1.5.0]: https://github.com/biandeshen/claude-code-init/compare/v1.4.1...v1.5.0
[1.4.1]: https://github.com/biandeshen/claude-code-init/compare/v1.4.0...v1.4.1
[1.4.0]: https://github.com/biandeshen/claude-code-init/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/biandeshen/claude-code-init/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/biandeshen/claude-code-init/releases/tag/v1.2.0
