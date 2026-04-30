# Claude Code 通用开发环境

[![Version](https://img.shields.io/github/package-json/v/biandeshen/claude-code-init)](https://github.com/biandeshen/claude-code-init)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

## 前置条件

- **Claude Code ≥ 2.0**（确认方法：在终端输入 `claude --version`，版本号应 ≥ 2.0。如低于此版本，请先升级 Claude Code）
- Git
- Python 3.8+
- Node.js 18+
- Windows PowerShell 7+（推荐）或 Git Bash

## 它能帮你做什么？

| 场景 | 效果 |
|------|------|
| 代码写完了 | 自动审查安全问题、性能问题、测试覆盖 |
| Bug 修完了 | 自动提交 + 规范检查 |
| 遇到复杂需求 | AI 自动拆分任务，复杂项目走 TDD |
| 想重构但怕改坏 | 安全重构模式，只改味道不改变逻辑 |
| 提交前不确定 | 一键检查敏感信息泄露 |
| 夜间让它跑任务 | 无人值守模式，自动循环执行 |
| 多角度并行审查 | 启动 Agent Teams，3-5 个专家同时工作 |
| 需要质量保证 | `/qa` 全面的浏览器自动化测试 |

## 快速开始

### 方式一：npx 一键初始化（推荐）

```bash
# 初始化项目
npx @biandeshen/claude-code-init --project-path ./my-project

# 安装核心插件（在 Claude Code 中执行）
/plugin marketplace add affaan-m/everything-claude-code
/plugin install everything-claude-code@everything-claude-code
/plugin marketplace add obra/superpowers-marketplace
/plugin install superpowers@superpowers-marketplace

# 开始开发
cd my-project
claude
```

### 方式二：手动克隆

```bash
# 克隆脚手架
git clone https://github.com/biandeshen/claude-code-init.git ~/tools/claude-code-init

# 初始化项目（Windows）
.\init.ps1 -ProjectPath "你的项目路径"

# 初始化项目（macOS/Linux）
./init.sh ./your-project
```

## 常用命令

| 命令 | 作用 |
|------|------|
| `/review` | 代码审查（安全 + 性能 + 测试） |
| `/fix` | 自动修复 Bug |
| `/commit` | 规范提交 |
| `/refactor` | 安全重构 |
| `/explain <目标>` | 代码解释 |
| `/validate` | 运行校验脚本 |
| `/team <数量> <任务>` | 启动 Agent 团队并行工作 |
| `/qa <目标>` | 质量保证测试 |
| `/plan-ceo-review <需求>` | 产品需求审查 |
| `/help` | 查看所有命令 |

> 输入 `/help <命令>` 查看详情，`/<命令>` 直接执行。例如：`/review` 直接开始审查。

## 进阶功能

### 无人值守长任务
让 AI 在你离开后继续工作：
```bash
# macOS/Linux
bash scripts/tmux-session.sh .claude/scripts/PROMPT.md

# Windows
tmux new-session -d -s claude-overnight
tmux send-keys -t claude-overnight "claude -p \$(cat .claude/scripts/PROMPT.md) --max-turns 50 --max-budget-usd 10.00" Enter
tmux attach -t claude-overnight
```

### Agent Teams
并行启动多个 AI 专家同时工作：
```bash
/team 3 审查 PR #142        # 3 个审查专家并行
/team 5 排查登录失败问题    # 5 个调查者验证假设
```

> 更多进阶功能见 [完整使用指南](GUIDE.md)

## 工作原理

1. **复杂度评估**：AI 自动评估任务复杂度（0-5分）
2. **自动分流**：
   - 简单任务 → 直接执行
   - 中等任务 → Plan + 执行
   - 复杂任务 → TDD 或完整流程
3. **安全保障**：Pre-commit Hooks 拦截敏感信息泄露

> 详细规则见 [SOUL.md](templates/SOUL_Template.md)

## 版本兼容性

| 组件 | 最低版本 | 推荐版本 |
|------|----------|----------|
| Claude Code | 2.0 | 最新稳定版 |
| Node.js | 16 | 18+ |
| Python | 3.8 | 3.10+ |
| Git | 2.30 | 最新稳定版 |
| PowerShell (Windows) | 5.1 | 7+ |
| tmux (Unix/macOS) | 3.0 | 最新稳定版 |

## 遇到问题？

👉 [常见问题排查指南](docs/TROUBLESHOOTING.md)

## 完整文档

👉 [查看完整使用指南](GUIDE.md)

## License

MIT
