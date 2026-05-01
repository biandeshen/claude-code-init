---
name: project-init
version: 1.0.0
lastUpdated: 2026-05-01
description: >
  新项目初始化时自动加载。中文触发词：初始化项目、初始化环境、设置项目、
  帮我设置开发环境、首次启动、project init、setup、initialize。
  检查项目结构完整性、导航 CLAUDE.md/SOUL.md、
  确认 SPEC 模板和校验脚本就位。由 Router 在用户说"初始化项目"或
  "帮我设置项目"时触发。
---

# 项目初始化技能

你负责在新项目或首次进入项目时确保整个开发环境就绪。

## 执行流程

### 1. 结构完整性检查

检查以下文件是否存在：

| 文件 | 用途 | 缺失时的操作 |
|------|------|-------------|
| `CLAUDE.md` | 项目规范入口 | 从 `.claude/templates/CLAUDE_Template.md` 复制 |
| `SOUL.md` | 元认知规则 | 从 `.claude/templates/SOUL_Template.md` 复制 |
| `.claude/PLAN_Template.md` | 执行计划模板 | 从 templates 复制 |
| `.claude/SPEC_Template.md` | 功能规格模板 | 从 templates 复制 |
| `.claude/skills/` | Skills 目录 | 从脚手架模板复制 |
| `.claude/scripts/` | 校验脚本 | 从脚手架模板复制 |
| `.claude/hooks/smart-context.sh` | 场景感知 Hook | 从脚手架模板复制 |
| `.claude/settings.json` | Claude Code 配置 | 从脚手架模板复制 |
| `.pre-commit-config.yaml` | Pre-commit 配置 | 从 configs 复制 |
| `.claude/commands/` | 自定义命令 | 从脚手架模板复制 |

### 2. 导航引导

结构检查通过后，输出简短导航：

```
✅ 项目环境已就绪

快速开始：
- /help — 查看所有可用命令和场景导航
- /capabilities — 按场景索引系统能力
- /status — 项目状态仪表盘

核心文档：
- CLAUDE.md — 项目规范入口（建议先阅读）
- SOUL.md — AI 元认知规则（决策树 + 复杂度评估）
```

### 3. 环境检查（可选）

如用户明确要求或为新项目，执行 `scripts/check-env.sh` 确认：
- Git 可用
- Python/Node.js 版本
- Pre-commit 已安装

## 失败处理（回滚机制）

- **文件复制失败**：检查源路径是否存在，确认后重试
- **步骤级回滚**：每个文件的复制为独立操作，单文件失败不影响其他文件
- **部分失败**：汇总失败文件列表，提示用户手动处理
- 本技能为设置类操作，无需 git stash 回滚
