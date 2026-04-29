# claude-code-init 项目交接文档

> 版本：v1.5.0 | 最后更新：2026-04-30

---

## 一、设计理念

### 1.1 核心定位

`claude-code-init` 是一个 **Claude Code 开发环境脚手架**，目标是让 AI 辅助开发从"靠感觉"变成"有 SOP"。

### 1.2 设计原则

| 原则 | 说明 |
|------|------|
| **智能化分流** | AI 自动评估任务复杂度（0-5分），决定执行模式 |
| **安全第一** | 物理阻断危险命令（rm -rf 等），cc-discipline 纪律约束 |
| **开箱即用** | 一条命令初始化完整开发环境 |
| **可演进** | 模块化设计，随时可以替换或扩展 |

### 1.3 架构分层

```
用户输入
    ↓
┌─────────────────────────────────────┐
│  Skills Router (智能路由)           │ ← 自动分流
├─────────────────────────────────────┤
│  各个 Skill (审查/修复/重构等)     │ ← 专业能力
├─────────────────────────────────────┤
│  Hooks (smart-context.sh)          │ ← 场景感知
├─────────────────────────────────────┤
│  校验脚本 (Python)                  │ ← 质量门禁
├─────────────────────────────────────┤
│  Pre-commit Hooks                   │ ← 提交前检查
└─────────────────────────────────────┘
```

---

## 二、项目结构

### 2.1 目录结构

```
claude-code-init/
├── README.md                 # 快速开始
├── GUIDE.md                  # 完整使用文档
├── SECURITY.md               # 安全策略
├── package.json              # npm 分发配置
├── index.js                  # npx 入口
├── init.ps1 / init.sh        # 初始化脚本
├── update.ps1                # 更新脚本
│
├── templates/                # 覆盖层模板（初始化时复制到项目）
│   ├── CLAUDE_Template.md
│   ├── SOUL_Template.md
│   ├── PLAN_Template.md
│   └── ROUTINE_Template.md
│
├── commands/                # 自定义斜杠命令
│   ├── help.md
│   ├── review.md
│   ├── commit.md
│   ├── fix.md
│   ├── refactor.md
│   ├── explain.md
│   ├── validate.md
│   ├── architect.md
│   ├── team.md              # Agent Teams
│   ├── qa.md
│   ├── status.md
│   ├── capabilities.md
│   ├── routine.md            # Claude Code Routines
│   └── ...
│
├── .claude/                 # Claude Code 专用配置 ⚠️ 重要
│   ├── settings.json         # Hooks + 环境变量配置
│   ├── skills/              # Skills 集合
│   │   ├── router/          # 智能路由（核心）
│   │   ├── code-review/
│   │   ├── error-fix/
│   │   ├── safe-refactoring/
│   │   ├── tdd-workflow/
│   │   ├── brainstorming/
│   │   ├── git-commit/
│   │   ├── project-validate/
│   │   ├── code-explain/
│   │   ├── project-init/
│   │   └── router-unattended/  # 无人值守专用
│   ├── hooks/
│   │   └── smart-context.sh   # 场景感知 Hook
│   └── scripts/             # ⚠️ Python 校验脚本（不是 scripts/）
│       ├── check_secrets.py
│       ├── check_function_length.py
│       ├── check_dependencies.py
│       ├── check_import_order.py
│       └── check_project_structure.py
│
├── scripts/                 # Bash 脚本（独立工具）
│   ├── tmux-session.sh      # 无人值守
│   ├── check-env.sh         # 环境检查
│   ├── trigger-optimizer.sh # Skills 触发分析
│   ├── weekly-report.sh     # 周报
│   ├── configure-gitignore.sh
│   ├── lib/
│   │   └── common.sh        # 公共函数库
│   └── ...
│
├── configs/
│   └── .pre-commit-config.yaml
│
├── .claude-plugin/          # Plugin 市场配置
│   └── plugin.json
│
└── docs/                    # 文档
    ├── QUICKSTART.md
    ├── AGENT_TEAMS_GUIDE.md
    ├── TROUBLESHOOTING.md
    └── ROADMAP.md
```

---

## 三、易遗漏要点 ⚠️

### 3.1 路径陷阱

| 场景 | 错误写法 | 正确写法 |
|------|----------|----------|
| Skills 中引用校验脚本 | `python scripts/check_secrets.py` | `python .claude/scripts/check_secrets.py` |
| Hooks 命令路径 | `bash scripts/smart-context.sh` | `bash .claude/hooks/smart-context.sh` |
| 项目中引用 scripts | `bash scripts/tmux-session.sh` | `bash scripts/tmux-session.sh`（正确，这是独立的） |

**原理**：
- `.claude/scripts/` 是 **Claude Code 专用目录**，AI 会自动识别
- `scripts/` 是 **独立 Bash 工具**，在项目根目录运行
- init.ps1 会把 Python 脚本复制到 `.claude/scripts/`，把 Bash 脚本复制到 `scripts/`

### 3.2 PowerShell 编码要求

**所有 .ps1 文件必须使用 UTF-8 BOM 编码**，否则中文会乱码。

```powershell
# 验证方法：查看文件前3字节
xxd -l 3 update.ps1
# 应该是: EF BB BF
```

### 3.3 环境变量

`settings.json` 中已包含 Agent Teams 环境变量：

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

### 3.4 npm 发布注意

发布前需要先登录：
```bash
npm login
npm publish --access public
```

---

## 四、使用逻辑

### 4.1 初始化流程

```
用户运行 init.ps1/init.sh
    ↓
复制模板到项目（CLAUDE.md, SOUL.md, PLAN.md）
    ↓
复制 Skills 到 .claude/skills/
    ↓
复制 Hooks 到 .claude/hooks/
    ↓
复制 Python 脚本到 .claude/scripts/  ← 容易忽略的步骤
    ↓
复制 Bash 脚本到 scripts/
    ↓
安装 Pre-commit hooks
    ↓
安装 cc-discipline
    ↓
初始化完成
```

### 4.2 任务执行流程

```
用户输入任务
    ↓
Skills Router 自动评估复杂度（0-5分）
    ↓
┌─────────────────────────────────────────┐
│ 0分 → 直接执行                          │
│ 1-2分 → Plan + 执行                    │
│ 3-4分 → Plan + TDD                    │
│ 5分+ → 完整 SDD 流程                   │
└─────────────────────────────────────────┘
    ↓
执行过程中 Hook 场景感知
    ↓
完成后主动推荐下一步
```

### 4.3 Agent Teams 工作流

```
用户输入 /team 3 任务
    ↓
Router 激活 Agent Teams
    ↓
创建 3 个 teammate，每个独立 worktree
    ↓
并行执行任务
    ↓
完成后向 Lead 汇报
    ↓
Lead 汇总结果
```

---

## 五、模块说明

### 5.1 Skills 体系

| Skill | 用途 | 触发词 |
|-------|------|--------|
| router | 智能路由（核心） | 所有输入 |
| code-review | 代码审查 | 审查、检查、review |
| error-fix | 错误修复 | 修复、fix、bug |
| safe-refactoring | 安全重构 | 重构、refactor |
| tdd-workflow | TDD 工作流 | TDD、测试驱动 |
| brainstorming | 头脑风暴 | 需求、规划 |
| git-commit | 规范提交 | 提交、commit |
| project-validate | 项目校验 | 校验、validate |
| code-explain | 代码解释 | 解释、explain |
| project-init | 项目初始化 | 初始化、新项目 |
| router-unattended | 无人值守路由 | tmux 模式 |

### 5.2 自定义命令

| 命令 | 触发方式 |
|------|----------|
| `/help` | 查看帮助 |
| `/review` | 代码审查 |
| `/commit` | 规范提交 |
| `/fix` | 自动修复 |
| `/refactor` | 安全重构 |
| `/explain` | 代码解释 |
| `/validate` | 项目校验 |
| `/architect` | 架构评审 |
| `/team` | Agent Teams |
| `/qa` | QA 测试 |
| `/status` | 项目状态 |
| `/capabilities` | 能力总览 |
| `/routine` | 云端定时任务 |

---

## 六、常见问题

### Q: 为什么有 scripts/ 和 .claude/scripts/ 两个目录？

- `scripts/`：独立的 Bash 工具，在项目根目录运行（如 tmux-session.sh）
- `.claude/scripts/`：Python 校验脚本，Claude Code 自动识别并运行

### Q: 为什么 .ps1 文件需要 UTF-8 BOM？

PowerShell 5.x 不支持无 BOM 的 UTF-8，会导致中文乱码。

### Q: Agent Teams 需要什么条件？

1. Claude Code ≥ 2.0
2. `settings.json` 中设置 `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`
3. tmux 已安装（Unix/macOS）

### Q: 无人值守模式怎么工作？

```bash
bash scripts/tmux-session.sh scripts/PROMPT.md
```
会在 tmux 会话中循环运行 Claude Code，支持安全限制和 router-unattended 路由。

---

## 七、版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| v1.5.0 | 2026-04-30 | Agent Teams 自动建议、Routines 集成、Plugin 市场 |
| v1.4.1 | 2026-04-28 | 智能化提升、无人值守优化 |
| v1.4.0 | 2026-04-28 | SOUL.md 五级复杂度评估 |
| v1.3.0 | 2026-04-28 | 文档清理、安全增强 |

---

*本文档为 claude-code-init 项目交接专用，涵盖设计理念、目录结构、易遗漏点和常见问题。*
