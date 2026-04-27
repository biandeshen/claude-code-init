# Claude Code 通用开发环境

一键初始化 Claude Code 开发环境，AI 自动评估任务复杂度并选择执行模式。

## 快速开始

```bash
# 1. 克隆脚手架
git clone https://github.com/biandeshen/claude-code-init.git ~/tools/claude-code-init

# 2. 安装插件（在 Claude Code 中）
/plugin marketplace add affaan-m/everything-claude-code
/plugin install everything-claude-code@everything-claude-code
/plugin marketplace add obra/superpowers-marketplace
/plugin install superpowers@superpowers-marketplace

# 3. 初始化新项目
~/tools/claude-code-init/init.ps1 -ProjectPath "你的项目路径"

# 4. 开始开发
cd your-project
claude
```

## 功能

- **一键初始化**：ECC + Superpowers + OpenSpec + cc-discipline
- **覆盖层模板**：CLAUDE.md + SOUL.md + PLAN_TEMPLATE.md
- **校验脚本**：密钥检查、函数长度、依赖方向、import 顺序
- **AI 复杂度评估**：自动判断任务类型并选择执行模式

## AI 复杂度评估

| 分值 | 模式 |
|:----:|------|
| 0分 | 直接执行（只读操作） |
| 1-2分 | Plan + 执行 |
| 3-4分 | Plan + TDD |
| 5分+ | 完整 SDD 流程 |

单文件编辑超过5次强制中断。

## 常用命令

| 命令 | 作用 |
|------|------|
| `/commit` | 规范提交 |
| `/review` | 代码审查 |
| `/architect` | 架构评审 |
| `/validate` | 运行校验脚本 |

## 完整文档

👉 [查看完整使用指南](GUIDE.md)

## License

MIT
