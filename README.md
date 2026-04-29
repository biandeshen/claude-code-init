# Claude Code 通用开发环境

[![Version](https://img.shields.io/badge/version-1.4.1-blue)](https://github.com/biandeshen/claude-code-init)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

一键搭建「AI辅助开发」工作环境。Claude Code 接入后，AI 会自动评估任务复杂度并选择最佳执行模式。

## 它能帮你做什么？

| 场景 | 效果 |
|------|------|
| 代码写完了 | 自动审查安全问题、性能问题、测试覆盖 |
| Bug 修完了 | 自动提交 + 规范检查 |
| 遇到复杂需求 | AI 自动拆分任务，复杂项目走 TDD |
| 想重构但怕改坏 | 安全重构模式，只改味道不改变逻辑 |
| 提交前不确定 | 一键检查敏感信息泄露 |
| 夜间让它跑任务 | 无人值守模式，自动循环执行 |

## 快速开始

### 方式一：npx 一键初始化（推荐）

```bash
# 初始化项目
npx claude-code-init --project-path ./my-project

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
| `/tdd` | 测试驱动开发 |
| `/explain <目标>` | 代码解释 |
| `/validate` | 运行校验脚本 |
| `/help` | 查看所有命令 |

> 输入 `/help <命令>` 查看详情，`/<命令>` 直接执行。例如：`/review` 直接开始审查。

## 工作原理

1. **复杂度评估**：AI 自动评估任务复杂度（0-5分）
2. **自动分流**：
   - 简单任务 → 直接执行
   - 中等任务 → Plan + 执行
   - 复杂任务 → TDD 或完整流程
3. **安全保障**：Pre-commit Hooks 拦截敏感信息泄露

> 详细规则见 [SOUL.md](templates/SOUL_Template.md)

## 完整文档

👉 [查看完整使用指南](GUIDE.md)

## License

MIT
