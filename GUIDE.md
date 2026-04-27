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
npx claude-code-init --project-path ./my-project
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
| **5分+** | 完整流程 | 启动 `/opsx:propose` |

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

## 校验脚本

初始化后会复制 `scripts/` 目录到项目：

| 脚本 | 说明 | Pre-commit |
|------|------|:----------:|
| `check_secrets.py` | 密钥安全检查 | ✅ |
| `check_function_length.py` | 函数长度 ≤50 行 | ✅ |
| `check_dependencies.py` | 模块依赖方向 | ✅ |
| `check_import_order.py` | import 顺序 | ✅ |
| `check_project_structure.py` | 项目结构完整性 | ✅ |

### 手动运行

```bash
python scripts/check_secrets.py
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
| **OpenSpec** | SDD 5步法工作流 | npx kld-sdd |
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
├── package.json           # npm 包配置（支持 npx）
├── index.js               # npx 入口脚本
├── init.ps1 / init.sh      # 初始化脚本
├── templates/              # 覆盖层模板
│   ├── CLAUDE_Template.md
│   ├── SOUL_Template.md
│   └── PLAN_Template.md
├── commands/              # 自定义斜杠命令
│   ├── review.md
│   ├── commit.md
│   └── architect.md
├── scripts/               # Python 校验脚本
│   ├── check_secrets.py
│   ├── check_function_length.py
│   ├── check_dependencies.py
│   ├── check_import_order.py
│   └── check_project_structure.py
└── configs/               # 配置文件
    └── .pre-commit-config.yaml
```

---

## 版本

v1.2.0 | 2026-04-28

## License

MIT
