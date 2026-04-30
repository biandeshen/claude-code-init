# Changelog

All notable changes to the claude-code-init project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

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

[Unreleased]: https://github.com/biandeshen/claude-code-init/compare/v1.5.0...HEAD
[1.5.2]: https://github.com/biandeshen/claude-code-init/compare/v1.5.1...v1.5.2
[1.5.1]: https://github.com/biandeshen/claude-code-init/compare/v1.5.0...v1.5.1
[1.5.0]: https://github.com/biandeshen/claude-code-init/compare/v1.4.1...v1.5.0
[1.4.1]: https://github.com/biandeshen/claude-code-init/compare/v1.4.0...v1.4.1
[1.4.0]: https://github.com/biandeshen/claude-code-init/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/biandeshen/claude-code-init/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/biandeshen/claude-code-init/releases/tag/v1.2.0
