# Claude Code 通用开发环境 - 完整使用指南

> 完整使用文档。关于快速开始，请参考 [README.md](README.md)。

---

## 前置条件（一辈子一次）

### 检查 Claude Code 版本

确保 Claude Code 版本 >= 2.0（`/plugin` 命令需要）：
```bash
claude --version
```

### 安装插件

在 Claude Code 会话中完成插件安装：

```
/plugin marketplace add affaan-m/everything-claude-code
/plugin install everything-claude-code@everything-claude-code

/plugin marketplace add obra/superpowers-marketplace
/plugin install superpowers@superpowers-marketplace
```

### 克隆脚手架

```bash
git clone https://github.com/biandeshen/claude-code-init.git ~/tools/claude-code-init
```

可选：添加到 PATH：

```powershell
# PowerShell Profile 中添加
$env:Path += ";~/tools/claude-code-init"
```

---

## 新项目初始化（每个项目一次）

### 方式一：npx 一键初始化（推荐）

```bash
npx @biandeshen/claude-code-init --project-path ./my-project
```

### 方式二：手动克隆后运行

```bash
# 克隆脚手架
git clone https://github.com/biandeshen/claude-code-init.git ~/tools/claude-code-init

# Windows PowerShell
~/tools/claude-code-init/init.ps1 -ProjectPath "你的项目路径"

# Unix/macOS
~/tools/claude-code-init/init.sh /path/to/your-project
```

初始化后自动具备：ECC 全家桶、Superpowers、OpenSpec、cc-discipline、校验脚本和 Pre-commit 配置。

---

## 开始开发

```bash
cd your-project
claude
```

AI 自动加载全部配置，**任务类型由 AI 自动评估**。

---

## AI 自动复杂度评估

### 只读操作（0分，直接执行）

以下操作自动判定为简单任务，事后记录即可：

| 操作类型 | 示例命令 |
|----------|----------|
| Git 查看类 | `git status`, `git log`, `git diff` |
| 文件浏览类 | `ls`, `dir`, `cat`, `head`, `tail` |
| 配置读取类 | 读取配置文件但不修改 |
| 信息获取类 | 搜索代码但不修改 |

> ⚠️ **例外触发**：只读操作若涉及搜索敏感字段（password、secret、token、key、credential）、
> 扫描 `.env` 文件、或以 `-S`/`-G` 搜索二进制模式，**立即升级为 3 分**（走 TDD 流程），并输出安全审计报告。
>
> **升级后的执行流程**：检测到敏感搜索 → 立即停止 → 输出安全审计报告（含敏感字段清单、文件路径、风险等级、修复建议）→ 等待用户确认 → 才可继续。

### 风险因子评分

| 风险条件 | 风险分 |
|----------|:------:|
| 影响模块超过 1 个 | +1 |
| 涉及 API、数据库 schema 或数据结构变更 | +1 |
| 涉及加密、鉴权、支付、文件删除等敏感操作 | +1 |
| 修改核心业务逻辑（计算规则、业务流程） | +2 |
| 修改安全相关代码（认证、授权、加密） | +2 |
| 修改数据库查询或 schema | +2 |
| 修改 API 接口契约 | +2 |

### 分值 → 执行模式

| 分值 | 执行模式 | 说明 |
|:----:|----------|------|
| **0分** | 直接执行 | 只读任务或纯信息操作 |
| **1-2分** | Plan → 执行 | 中等复杂度，先计划后实施 |
| **3-4分** | Plan → TDD | 高复杂度，测试驱动 |
| **5分+** | 完整流程 | 启动 `/opsx:propose`，走完整 SDD 5 步法 |

### 不确定性处理

如果对任何条件无法判断，**默认按"最高分"处理**，强制走完整流程。

### 强制中断规则

**单文件编辑超过5次，必须停下来：**
1. 重新评估复杂度
2. 输出根因分析
3. 向用户汇报当前状态

### 评估示例

| 任务 | 只读 | 影响模块 | API/DB | 敏感操作 | 逻辑变更 | 总分 | 模式 |
|------|:----:|:--------:|:------:|:--------:|:--------:|:----:|:----:|
| 查看 git status | ✅ | - | - | - | - | 0 | 直接执行 |
| 修改 README | ❌ | 0 | ❌ | ❌ | ❌ | 0 | 直接执行 |
| 添加新 API | ❌ | 1 | +1 | ❌ | +2 | 4 | TDD |
| 修改认证逻辑 | ❌ | 1 | ❌ | +1 | +2 | 4 | TDD |
| 重构核心业务 | ❌ | 2+ | ❌ | ❌ | +2 | 4+ | 完整流程 |

---

## 常用命令

| 命令 | 作用 |
|------|------|
| `/help` | 显示所有可用命令和工作流速查 |
| `/commit` | 规范提交（自动分析 + Conventional Commits + Pre-commit） |
| `/review` | 代码审查（安全性/正确性/性能/可维护性/测试覆盖） |
| `/architect <方案>` | 架构评审 |
| `/validate` | 运行项目 `.claude/scripts/` 下的自定义校验脚本 |
| `/fix` | 自动错误修复（分析 → 根因 → 方案 → 执行 → 验证） |
| `/refactor` | 安全重构（先测试保护，逐步重构，保持测试绿灯） |
| `/explain <目标>` | 代码深度解释（架构/数据流/决策/风险） |
| `/team <数量> <任务>` | 启动 Agent 团队并行工作 |
| `/qa <目标>` | 质量保证测试 |
| `/plan-ceo-review <需求>` | 产品需求审查 |
| `/routine <描述>` | 云端定时任务管理 |
| `/overnight` | 启动无人值守长任务 |
| `/overnight-report` | 查看过夜任务汇总 |
| `/status` | 项目状态仪表盘 |
| `/capabilities` | 按场景索引系统能力 |
| `/messages` | 查看 Agent 团队消息 |
| `/opsx:propose <名称>` | 复杂功能 SDD 流程（AI 可能自动触发） |

---

## 覆盖层模板

初始化后会复制以下模板到项目目录：

| 文件 | 说明 |
|------|------|
| `CLAUDE.md` | 项目入口，引用双索引 |
| `SOUL.md` | 元认知规则，决策树和复杂度评估 |
| `PLAN_TEMPLATE.md` | 任务执行计划模板 |
| `SPEC_Template.md` | 功能级设计规格模板 |
| `ROUTINE_Template.md` | 日常开发规范模板 |

### 模板生命周期

```
claude-code-init/templates/
        ↓  init.ps1/init.sh 复制
项目根目录/
    ├── CLAUDE.md      # 复制后重命名
    ├── SOUL.md        # 复制后重命名
    └── PLAN_TEMPLATE.md
```

---

## 四层文档架构

初始化后，项目具备四层递进的 AI 开发文档体系：

```
CLAUDE.md  ← 入口层：项目规范 + 文档索引
    ↓
SOUL.md    ← 决策层：复杂度评估 + 执行模式自动切换
    ↓
SPEC.md    ← 规格层：单一功能的目标/约束/契约/验收标准
    ↓
PLAN.md    ← 执行层：任务执行的实时日志
```

| 文档 | 定位 | 时机 | 示例 |
|------|------|------|------|
| **CLAUDE.md** | AI 启动时自动读取的入口规范 | 项目初始化时创建 | "本项目的代码风格是..." |
| **SOUL.md** | 元认知规则，AI 自动评估任务复杂度 | 每次任务开始时评估 | "修改认证模块 → 4分 → Plan+TDD" |
| **docs/specs/*.md** | 功能级设计蓝图，定义 API 契约和验收标准 | 复杂功能(≥5分)开发**前** | "用户认证系统 v1 — 支持 OAuth2 + JWT" |
| **Plan.md** | 任务执行日志，记录每一步的实际操作 | 复杂功能开发**中** | "14:32 修改 auth.py → ✅ → 下一步..." |

> **核心原则**：Spec 管"做什么"（事前设计），Plan 管"做了什么"（事后记录）。
> 参考模板：[SPEC_Template.md](templates/SPEC_Template.md) | [PLAN_Template.md](templates/PLAN_Template.md)

### Spec 与 OpenSpec 的关系

- **Spec** (docs/specs/)：轻量级、项目内嵌的功能规格。适合单个功能的手写设计。
- **OpenSpec** (openspec/changes/)：重量级 SDD 5步法工作流。适合大型变更的标准化管理。
- **关系**：OpenSpec 的 "Spec" 步骤可产出 `docs/specs/` 中的 Spec 文件；手动创建的 Spec 也可作为 OpenSpec "Propose" 步骤的输入。

---

## 校验脚本

初始化后会复制 `.claude/scripts/` 目录到项目：

| 脚本 | 说明 | Pre-commit |
|------|------|:----------:|
| `check_secrets.py` | 密钥安全检查 | ✅ |
| `check_function_length.py` | 函数长度 ≤50 行 | ✅ |
| `check_dependencies.py` | 模块依赖方向 | ✅ |
| `check_import_order.py` | import 顺序 | ✅ |
| `check_project_structure.py` | 项目结构完整性 | ✅ |

### 手动运行

```bash
python .claude/scripts/check_secrets.py
pre-commit run --all-files
```

### 自定义依赖规则

创建 `.dependency-rules.json`：

```json
{
    "src": {"forbidden": ["lib"]},
    "lib": {"forbidden": ["lib"]},
    "tests": {"forbidden": []}
}
```

---

## 错误自动处理

| 情况 | 系统反应 |
|------|----------|
| 单文件编辑 ≥5 次 | 强制阻断，要求根因分析 |
| 测试连续失败 2 次 | 自动停止，请求介入 |
| 调试未完成即改代码 | 阻断，要求先完成调试 |

---

## 包含的工具

| 工具 | 说明 | 安装方式 |
|------|------|----------|
| **ECC** | Everything Claude Code - 38个Agent + 183个Skills | Claude Code 插件 |
| **Superpowers** | TDD铁律 + 根因追踪 | Claude Code 插件 |
| **OpenSpec** | SDD 5步法工作流 | npm: @fission-ai/openspec |
| **cc-discipline** | 物理防火墙 Hooks | git clone |

---

## 维护

> ⚠️ **重要**：重新运行 `init.ps1`/`init.sh` 会覆盖项目中已修改的模板文件（CLAUDE.md、SOUL.md 等）。如需更新规范到最新版本，推荐只拉取脚手架本身：
> ```bash
> git -C ~/tools/claude-code-init pull
> ```

- **ECC / Superpowers**：收到更新提示后 `/plugin update`
- **脚手架更新**：`git -C ~/tools/claude-code-init pull`
- **覆盖模板**：`init.ps1 -ProjectPath "你的项目"`（会覆盖现有模板）

---

## 仓库结构

```
claude-code-init/
├── README.md              # 快速开始入口
├── GUIDE.md               # 完整使用文档
├── SECURITY.md            # 安全策略
├── LICENSE                # MIT 许可证
├── CHANGELOG.md           # 版本变更记录
├── package.json           # npm 包配置（支持 npx）
├── index.js               # npx 入口脚本
├── init.ps1 / init.sh      # 初始化脚本
├── docs/                  # 文档
│   ├── QUICKSTART.md      # 快速上手
│   ├── TROUBLESHOOTING.md # 故障排查
│   └── HANDOVER.md        # 项目交接文档
├── templates/              # 覆盖层模板
│   ├── CLAUDE_Template.md
│   ├── SOUL_Template.md
│   ├── SPEC_Template.md
│   ├── PLAN_Template.md
│   └── ROUTINE_Template.md
├── commands/              # 自定义斜杠命令 (17个)
│   ├── review.md, commit.md, fix.md
│   ├── refactor.md, explain.md, validate.md
│   ├── team.md, qa.md, routine.md
│   └── help.md, status.md, capabilities.md...
├── scripts/               # Shell 脚本工具
│   ├── tmux-session.sh    # 无人值守会话管理
│   ├── ralph-setup.sh     # Ralph 插件安装
│   ├── weekly-report.sh   # 周报生成
│   ├── validate_skills.sh # Skills 健康检查
│   ├── check-env.sh       # 环境检查
│   └── configure-gitignore.* # .gitignore 配置
├── .claude/scripts/         # Claude Code 专用脚本
│   ├── check_secrets.py     # 密钥安全检查
│   ├── check_function_length.py
│   ├── check_dependencies.py
│   ├── check_import_order.py
│   ├── check_project_structure.py
│   └── PROMPT.md            # 过夜任务清单
└── configs/               # 配置文件
    └── .pre-commit-config.yaml
```

---

## 常见问题

### Q: 初始化后 `claude` 启动报错 "plugin not found"
A: ECC 和 Superpowers 需要手动在 Claude Code 中安装，`init.ps1` 仅打印安装命令。详见 README 步骤 3。

### Q: `pre-commit install` 失败
A: 确认 Python 版本 >= 3.8，执行 `pip install pre-commit` 后重试。

### Q: 如何更新已有项目的规范？
A: `git -C ~/tools/claude-code-init pull` 仅更新脚手架。如需覆盖模板，重新运行 `init.ps1`（会覆盖 CLAUDE.md 等文件，建议先备份）。

### Q: npx 运行报 "command not found"
A: 确保 Node.js >= 18 已安装。也可以使用手动方式：
```bash
git clone https://github.com/biandeshen/claude-code-init.git ~/tools/claude-code-init
~/tools/claude-code-init/init.ps1 -ProjectPath "你的项目"
```

---

## 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| v1.5.1 | 2026-04-30 | 全线跨平台兼容修复(38项)、安全加固、CI门禁强化、MIT License |
| v1.5.0 | 2026-04-30 | Agent Teams 并行开发、无人值守长任务、Skills 触发词优化、文档交接 |
| v1.4.1 | 2026-04-28 | 移除误导性 Skip 参数文档、添加系统依赖检查、修复静默失败 |
| v1.4.0 | 2026-04-28 | 移除 _archived/、SECURITY.md 重写、SOUL.md 五级制复杂度评估 |
| v1.3.0 | 2026-04-28 | 删除 _archived/、增强 README 警告、修复硬化路径 |
| v1.2.0 | 2026-04-28 | 初始版本基础功能 |

---

## License

MIT
