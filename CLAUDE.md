# claude-code-init 开发规范

> Claude Code 会话启动时自动读取。本项目自身用自己产出的工具开发（dogfooding）。
> 版本：v1.5.7 | 最后更新：2026-05-01

---

## 项目定位

claude-code-init 是一个**元工具** — 它的所有功能（Skills、Hooks、模板、脚本、命令）的最终目的，都是服务于**目标开发项目**，让 Claude Code 在目标项目上工作得更好。

> 每次改动前问自己：这个改动最终能让目标项目的开发体验好在哪里？

---

## 索引架构

| 规范类型 | 来源 | 说明 |
|----------|------|------|
| **工具规范** | ECC 内置 | 156+ Skills / 38 Agents |
| **元认知规则** | [SOUL.md](SOUL.md) | 复杂度评估、决策树、文档生命周期 |
| **项目规范** | `.claude/skills/` | 本项目自定义 Skill |
| **命令定义** | `commands/` | 20 个斜杠命令，部署到 `.claude/commands/` |
| **模板定义** | `templates/` | 5 个模板，部署到目标项目根目录 |
| **项目文档** | 根目录 `*.md` + `docs/` | 本工具自身的使用和开发文档 |

---

## 项目结构

```
claude-code-init/
├── CLAUDE.md              # 本文件 — 项目入口规范
├── SOUL.md                # 元认知规则 — 控制 AI 行为
├── README.md              # 快速开始入口
├── GUIDE.md               # 完整使用指南
├── CHANGELOG.md           # 版本变更记录
├── SECURITY.md            # 安全策略
├── LICENSE                # MIT 许可证
├── package.json           # npm 包配置
├── index.js               # npx 入口脚本
├── init.sh / init.ps1      # 初始化脚本
├── templates/              # 5 个覆盖层模板 (→ 目标项目)
│   ├── CLAUDE_Template.md
│   ├── SOUL_Template.md
│   ├── SPEC_Template.md
│   ├── PLAN_Template.md
│   └── ROUTINE_Template.md
├── commands/              # 20 个斜杠命令 (→ .claude/commands/)
├── .claude/               # Claude Code 配置
│   ├── skills/            # 10 个自定义 Skill (→ .claude/skills/)
│   ├── scripts/           # Python 校验 + PROMPT.md (→ .claude/scripts/)
│   ├── hooks/             # Pre-commit hooks
│   └── settings.json      # Claude Code 设置
├── scripts/               # Shell 工具脚本
│   ├── tmux-session.sh    # 无人值守会话管理
│   ├── ralph-setup.sh     # Ralph 插件安装
│   ├── weekly-report.sh   # 周报生成
│   ├── validate_skills.sh # Skills 健康检查
│   ├── check-env.sh       # 环境检查
│   └── configure-gitignore.*
├── configs/               # 配置文件
│   └── .pre-commit-config.yaml
├── docs/                  # 深度文档
│   ├── HANDOVER.md        # 项目交接文档
│   ├── QUICKSTART.md      # 快速上手
│   ├── TROUBLESHOOTING.md # 故障排查
│   ├── ROADMAP.md         # 路线图
│   ├── AGENT_TEAMS_GUIDE.md
│   └── PHASE2_PLAN.md     # Phase2 计划
└── .github/workflows/     # CI/CD
    └── ci.yml
```

---

## 文档同步规则

> 本项目自身也必须遵守文档生命周期规范（见 [SOUL.md](SOUL.md) 文档生命周期规范）。

1. **代码修改后**：检查 `README.md`、`GUIDE.md`、`docs/` 中的引用是否过时
2. **命令增减后**：同步更新 `commands/help.md` 和 `GUIDE.md` 的命令表
3. **目录结构变化后**：更新本文件（CLAUDE.md）的项目结构图
4. **版本发布后**：同步更新 `CHANGELOG.md`、`GUIDE.md` 版本历史

---

## 版本历史

- `v1.5.7` (2026-05-01)：第四轮审查修复 Batch 3 — Memory GC + access_count + Skill 回滚规范 + timeout + JSON 转义 + 选择性部署
- `v1.5.6` (2026-05-01)：第四轮审查修复 Batch 2 — Router/Brainstorming 路由冲突 + OWASP 补全 + 否定语义 + rm -rf 正则增强 + 触发词扩展
- `v1.5.5` (2026-05-01)：第四轮审查修复 Batch 1 — hook exit 0 致命修复 + PROMPT.md 部署链 + 过时代码清理 + 版本标志
- `v1.5.4` (2026-05-01)：第三轮多角色审查修复 — 安全加固 P0/P1 密钥检测增强 + 版本一致性修复
- `v1.5.3` (2026-05-01)：安全加固 P0/P1 密钥检测增强 + 版本一致性修复
- `v1.5.2` (2026-05-01)：安全修复 .env 保护 + 信任边界加固
- `v1.5.1` (2026-04-30)：全线 Bug 修复 + 跨平台兼容 + 安全加固 + 文档同步机制
- `v1.5.0` (2026-04-30)：Agent Teams + 无人值守 + Skills 优化 + 文档交接

---

*核心原则：工具服务目标项目，模板服务目标项目，规则服务目标项目。*
