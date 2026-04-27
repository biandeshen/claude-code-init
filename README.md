# Claude Code 通用开发环境

一键初始化 Claude Code 开发环境，AI 自动评估任务复杂度并选择执行模式。

## 功能

- 一键初始化 Claude Code 开发环境
- 自动安装 ECC、Superpowers、OpenSpec、cc-discipline
- 复制覆盖层模板 (CLAUDE.md、SOUL.md、PLAN_TEMPLATE.md)
- 复制 Python 校验脚本 (密钥检查、函数长度、依赖方向等)
- 自动配置 Pre-commit Hooks
- 自动配置 .gitignore
- **AI 自动评估任务复杂度，选择执行模式**

## 前置条件（一辈子一次）

### 检查 Claude Code 版本

确保 Claude Code 版本 >= 2.0（`/plugin` 命令需要）：
```bash
claude --version
```

在 Claude Code 会话中完成插件安装：

```
/plugin marketplace add affaan-m/everything-claude-code
/plugin install everything-claude-code@everything-claude-code

/plugin marketplace add obra/superpowers-marketplace
/plugin install superpowers@superpowers-marketplace
```

克隆项目脚手架到本地（位置任意）：

```bash
git clone https://github.com/biandeshen/claude-code-init.git ~/tools/claude-code-init
```

可选：添加到 PATH 方便调用：

```powershell
# PowerShell Profile 中添加
$env:Path += ";~/tools/claude-code-init"
```

---

## 新项目初始化（每个项目一次）

```powershell
# 方式一：添加 PATH 后直接用
init-project -ProjectPath "新项目路径"

# 方式二：直接运行脚本
~/tools/claude-code-init/init.ps1 -ProjectPath "新项目路径"
```

Unix/macOS：

```bash
./init.sh /path/to/your-project
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

| 条件 | 风险分 |
|------|:------:|
| 影响模块超过 1 个 | +1 |
| 涉及 API、数据库 schema 或数据结构变更 | +1 |
| 涉及加密、鉴权、支付、文件删除等敏感操作 | +1 |

**自动模式切换**：

- **0 分**：直接执行，事后记录
- **1 分**：先写 Plan，然后 TDD
- **2-3 分**：自动启动 `/opsx:propose`

无法判断时默认走完整流程。单文件编辑超过 5 次，强制停止并输出根因分析。

---

## 常用命令

| 命令 | 作用 |
|------|------|
| `/commit` | 规范提交（自动分析 + Conventional Commits + Pre-commit） |
| `/review` | 代码审查（安全性/正确性/性能/可维护性/测试覆盖） |
| `/architect 方案` | 架构评审 |
| `/validate` | 运行项目 scripts/ 下的自定义校验脚本 |
| `/opsx:propose 名称` | 复杂功能 SDD 流程（AI 可能自动触发） |

---

## 覆盖层模板

初始化后会复制以下模板到项目目录：

| 文件 | 说明 |
|------|------|
| `CLAUDE.md` | 项目入口，引用双索引 |
| `SOUL.md` | 元认知规则，决策树和复杂度评估 |
| `PLAN_TEMPLATE.md` | 任务执行计划模板 |

---

## 校验脚本

初始化后会复制 `scripts/` 目录到项目：

| 脚本 | 说明 | Pre-commit |
|------|------|:----------:|
| `check_secrets.py` | 密钥安全检查 | ✅ |
| `check_function_length.py` | 函数长度 ≤50 行 | ✅ |
| `check_dependencies.py` | 模块依赖方向 | ✅ |
| `check_import_order.py` | import 顺序 | ✅ |
| `check_project_structure.py` | 项目结构完整性 | ✅ |

手动运行：

```bash
python scripts/check_secrets.py
pre-commit run --all-files
```

自定义依赖规则：创建 `.dependency-rules.json`

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
| **OpenSpec** | SDD 5步法工作流 | npx kld-sdd |
| **cc-discipline** | 物理防火墙 Hooks | git clone |

---

## 维护

- **ECC / Superpowers**：收到更新提示后 `/plugin update`
- **脚手架**：`git -C ~/tools/claude-code-init pull`
- 已有项目重新应用：重新运行 `init.ps1`/`init.sh`

---

## 跳过某些工具

```powershell
.\init.ps1 -ProjectPath "你的项目路径" -SkipECC -SkipSuperpowers
```

| 选项 | 说明 |
|------|------|
| `-SkipECC` | 跳过 ECC 安装 |
| `-SkipSuperpowers` | 跳过 Superpowers 安装 |
| `-SkipOpenSpec` | 跳过 OpenSpec 安装 |
| `-SkipCcDiscipline` | 跳过 cc-discipline 安装 |

---

## 仓库结构

```
claude-code-init/
├── README.md              # 本文件
├── init.ps1 / init.sh      # 初始化脚本
├── templates/              # 覆盖层模板
│   ├── CLAUDE_Template.md
│   ├── SOUL_Template.md
│   └── PLAN_Template.md
├── commands/              # 自定义斜杠命令
├── scripts/                # Python 校验脚本
├── configs/                # 配置文件
│   └── .pre-commit-config.yaml
└── _archived/              # 归档的规范文档
```

---

## 版本

v1.1.0 | 2026-04-28

## License

MIT
