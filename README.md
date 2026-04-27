# claude-code-init

Claude Code 开发环境一键初始化工具箱。

## 功能

- 一键初始化 Claude Code 开发环境
- 自动安装 ECC (Everything Claude Code)、Superpowers、OpenSpec、cc-discipline
- 复制覆盖层模板 (CLAUDE.md、SOUL.md、PLAN_TEMPLATE.md)
- 自动配置 .gitignore

## 仓库结构

```
claude-code-init/
├── README.md              # 本文件
├── init.ps1               # Windows PowerShell 一键初始化
├── init.sh                # Unix/macOS 一键初始化
├── templates/             # 覆盖层模板
│   ├── CLAUDE_Template.md
│   ├── SOUL_Template.md
│   └── PLAN_Template.md
└── commands/              # 自定义斜杠命令
    ├── review.md          # /review - 代码审查
    ├── commit.md          # /commit - 规范提交
    └── architect.md       # /architect - 架构分析
```

## 快速开始

### 首次使用

```bash
# 克隆仓库到本地（克隆到任意位置）
git clone https://github.com/你的账号/claude-code-init.git
cd claude-code-init
```

### 新建项目

```powershell
# Windows PowerShell（在 claude-code-init 目录下执行）
.\init.ps1 -ProjectPath "C:\path\to\your-project"
```

```bash
# Unix/macOS
./init.sh /path/to/your-project
```

## 包含的工具

| 工具 | 说明 | 安装方式 |
|------|------|----------|
| **ECC** | Everything Claude Code - 38个Agent + 183个Skills | Claude Code 插件 |
| **Superpowers** | TDD铁律 + 根因追踪 | Claude Code 插件 |
| **OpenSpec** | SDD 5步法工作流 | npx kld-sdd |
| **cc-discipline** | 物理防火墙 Hooks | git clone |

## 覆盖层模板

初始化后会复制以下模板到项目目录：

| 文件 | 说明 |
|------|------|
| `CLAUDE.md` | 项目入口，引用双索引 |
| `SOUL.md` | 元认知规则，决策树和技能联动 |
| `PLAN_TEMPLATE.md` | 任务执行计划模板 |

## 自定义命令

初始化后会创建 `.claude/commands/` 目录，包含：

| 命令 | 用途 |
|------|------|
| `/review` | 代码审查 |
| `/commit` | 规范提交 |
| `/architect` | 架构分析 |

## 更新规范

```bash
# 进入仓库目录
cd claude-code-init

# 拉取最新规范
git pull
```

> 已有项目重新应用：重新运行 init.ps1/init.sh 即可

## 选项

```powershell
# 跳过某些工具的安装提示
.\init.ps1 -ProjectPath "C:\path\to\your-project" -SkipECC -SkipSuperpowers
```

| 选项 | 说明 |
|------|------|
| `-SkipECC` | 跳过 ECC 安装提示 |
| `-SkipSuperpowers` | 跳过 Superpowers 安装提示 |
| `-SkipOpenSpec` | 跳过 OpenSpec 安装提示 |
| `-SkipCcDiscipline` | 跳过 cc-discipline 安装提示 |

## 版本

v1.0.0 | 2026-04-28

## License

MIT
