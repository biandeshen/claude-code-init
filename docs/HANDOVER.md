# claude-code-init 项目交接文档

> 版本：v1.5.1 | 最后更新：2026-04-30

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
| **配置隐藏、知识可见** | 配置文件进 `.claude/`，知识文档放项目根目录 |
| **Spec 优先** | 5分+ 任务强制走 Spec-Driven Development 流程 |

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
├─────────────────────────────────────┤
│  CI/CD Pipeline (.github/workflows) │ ← 持续集成
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
├── CHANGELOG.md              # 版本变更日志
├── package.json              # npm 分发配置
├── index.js                  # npx 入口
├── init.ps1 / init.sh        # 初始化脚本（16步，两者保持同步）
│
├── templates/                # 覆盖层模板（初始化时复制到项目）
│   ├── CLAUDE_Template.md    # AI 入口配置（含 spec 索引）
│   ├── SOUL_Template.md      # 决策规则 + spec 检查
│   ├── PLAN_Template.md      # 执行日志
│   ├── ROUTINE_Template.md   # 云端定时任务模板
│   └── SPEC_Template.md      # 功能规格模板（7 节结构）
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
│   └── overnight.md          # 无人值守过夜任务
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
│   ├── configure-gitignore.sh / .ps1
│   ├── validate_skills.sh   # Skills 命名校验
│   ├── lib/
│   │   └── common.sh        # 公共函数库
│   └── ...
│
├── .github/workflows/       # CI/CD（Supply Chain 安全）
│   └── ci.yml               # node-check, shellcheck, bash-syntax, markdown-lint, python-syntax
│
├── configs/
│   └── .pre-commit-config.yaml
│
├── .claude-plugin/          # Plugin 市场配置
│   └── plugin.json
│
└── docs/                    # 文档
    ├── HANDOVER.md           # 交接文档（本文件）
    ├── QUICKSTART.md
    ├── AGENT_TEAMS_GUIDE.md
    ├── TROUBLESHOOTING.md
    └── ROADMAP.md
```

### 2.2 关键路径变更（v1.5.1）

| 变更项 | 旧路径 | 新路径 | 原因 |
|--------|--------|--------|------|
| 本地配置 | `/CLAUDE.local.md` | `/.claude/CLAUDE.local.md` | 隐藏目录合规 |
| 周报输出 | `reports/` | `.claude/reports/` | 避免污染项目根目录 |
| tmux PROMPT | `scripts/PROMPT.md` | `.claude/scripts/PROMPT.md` | 与校验脚本同目录 |
| 功能规格模板 | 无 | `templates/SPEC_Template.md` | Spec Generation |
| 定时任务模板 | 无 | `templates/ROUTINE_Template.md` | Routines 集成 |
| CI/CD | 无 | `.github/workflows/ci.yml` | 自动化质量门禁 |
| update.ps1 | /update.ps1 | **已删除** | 空文件（仅 3 字节 BOM） |

---

## 三、易遗漏要点 ⚠️

### 3.1 路径陷阱：`.claude/scripts/` vs `scripts/`

这是本项目**最容易出错的点**，无数次修复都围绕这个双目录设计展开。

| 场景 | 错误写法 | 正确写法 |
|------|----------|----------|
| Skills 中引用校验脚本 | `python scripts/check_secrets.py` | `python .claude/scripts/check_secrets.py` |
| Hooks 命令路径 | `bash scripts/smart-context.sh` | `bash .claude/hooks/smart-context.sh` |
| 命令中引用 tmux | `bash scripts/tmux-session.sh` | `bash .claude/scripts/tmux-session.sh`（在目标项目中） |
| 项目中引用 scripts | `bash .claude/scripts/tmux-session.sh` | `bash scripts/tmux-session.sh`（在本项目中） |

**原理**：
- `.claude/scripts/` 是 **目标项目的 Claude Code 专用目录**，init 时 Python 校验脚本复制到此处
- `scripts/` 是 **脚手架项目自己的独立 Bash 工具**，在项目根目录运行
- init.ps1/init.sh 的 Step 7 把整个 `scripts/` 目录复制到目标项目（保持原目录名）
- **旧 Step 14 曾错误地再创建 `scripts/` 目录**（已于 v1.5.1 删除），因为 Step 7 已完成复制

> **教训**：修改 init 流程时，必须同时检查 init.ps1 和 init.sh，两者步号必须保持一致。

### 3.2 PowerShell Linter 文件干扰

**症状**：`Read` 文件后立刻 `Edit`，PowerShell 编辑器/linter 可能在读取后自动修改文件（格式化、编码转换等），导致 "File has been modified since read" 错误。

**应对策略**：
1. 在 Edit 前立刻重新 Read（不做任何中间操作）
2. 使用更长的 `old_string` 上下文（确保唯一性匹配）
3. 如果仍然失败，用 Write 整文件覆盖

### 3.3 PowerShell UTF-8 BOM 编码要求

**所有 .ps1 文件必须使用 UTF-8 BOM 编码**，否则中文会乱码。

```powershell
# 验证方法：查看文件前3字节
xxd -l 3 update.ps1
# 应该是: EF BB BF
```

PowerShell 5.x 不支持无 BOM 的 UTF-8。PowerShell 7+ 已修复，但为兼容仍需遵守。

### 3.4 PowerShell 路径比较陷阱

```powershell
# 错误：字符串 -eq 无法处理 symlink、junction、不同大小写
if ($SourcePath -eq $TargetPath) { ... }

# 正确：使用 Resolve-Path.ProviderPath 归一化后比较
function Test-SamePath {
    param([string]$PathA, [string]$PathB)
    try {
        $resolvedA = (Resolve-Path $PathA -ErrorAction Stop).ProviderPath
        $resolvedB = (Resolve-Path $PathB -ErrorAction Stop).ProviderPath
        return $resolvedA -eq $resolvedB
    } catch {
        return $false
    }
}
```

init.ps1 中 5 处路径比较（Step 7 源==目标检查、Step 9-10 模板检查等）已全部替换为 `Test-SamePath`。

### 3.5 detectPowerShell() 重复调用

`index.js` 中 `detectPowerShell()` 是一个 `spawnSync` 调用，开销较大。旧代码在 L73 和 L96 各调用了一次。

```javascript
// 正确做法：缓存结果
const psCmd = detectPowerShell();  // 只调用一次
// 后续全部使用 psCmd 变量
```

### 3.6 模板覆盖保护

**init.ps1/init.sh 在复制模板文件前必须先检查文件是否已存在**，否则会覆盖用户的自定义配置。

```bash
# 正确做法
if [ -f "$PROJECT_PATH/CLAUDE.md" ]; then
    echo_warn "CLAUDE.md 已存在，跳过覆盖（如需更新请手动合并）"
else
    cp "$TEMPLATE_DIR/CLAUDE_Template.md" "$PROJECT_PATH/CLAUDE.md"
fi
```

这适用于所有模板：CLAUDE.md, SOUL.md, PLAN.md, SPEC_Template.md, ROUTINE_Template.md。

### 3.7 Gitignore 规则陷阱：`docs/` 误排除

`configure-gitignore.ps1` 和 `configure-gitignore.sh` 的默认选项曾包含 `docs/` 规则，导致所有文档目录被 git 忽略。**文档是知识产物，应当纳入版本控制**。

同时，`CLAUDE.local.md` 移入 `.claude/` 后，gitignore 规则需同步更新：
- 旧规则：`CLAUDE.local.md`（匹配根目录）
- 新规则：`.claude/CLAUDE.local.md` 或保持目录级 `.claude/` 规则

### 3.8 `configure-gitignore` 双脚本维护

`.ps1` 和 `.sh` 版本的 `configure-gitignore` 必须 **同步修改**。两者有相同的选项结构（1/2/3/default），但选项 1 和 default 有**完全相同的 `docs/` 条目**，编辑时需要靠上下文区分。

### 3.9 Pre-commit 路径：设计即正确

`.pre-commit-config.yaml` 中校验脚本的路径如 `\.claude/scripts/check_secrets.py` 是 **正确的**——因为此文件被复制到**目标项目**根目录，而目标项目的 Python 脚本就在 `.claude/scripts/` 下。这是"按设计工作"，不要误判为 bug。

### 3.10 Step 编号一致性

init.ps1 和 init.sh 必须保持步号同步：

| 步号 | 内容 | 备注 |
|------|------|------|
| 1 | 环境检测 | |
| 2 | 读取项目路径 | |
| 3 | 创建项目目录 | |
| 4 | 复制 CLAUDE.md | 含存在检查 |
| 5 | 复制 SOUL.md | 含存在检查 |
| 6 | 复制 PLAN.md | 含存在检查 |
| 7 | 复制 scripts/ 目录 | 含源==目标检查 |
| 8 | 复制 .claude/ 目录 | |
| 9 | 配置 settings.json | |
| 10 | 复制其他模板 | SPEC, ROUTINE, CLAUDE.local.md |
| 11 | 复制 commands/ | |
| 12 | 复制 configs/ | |
| 13 | 配置 .gitignore | |
| 14 | 安装 gstack | （原 Step 15） |
| 15 | 环境检查 | （原 Step 16） |
| 16 | 全局偏好设置 | （原 Step 17） |

> Step 14（创建 scripts/ 目录）已在 v1.5.1 删除，因为 Step 7 已完成此工作。步号 15→14, 16→15, 17→16。

---

## 四、跨平台兼容性陷阱

### 4.1 总览

| 陷阱 | 影响平台 | 症状 | 修复方案 |
|------|----------|------|----------|
| `declare -A` | macOS (Bash 3.2) | `declare: -A: invalid option` | 改用 `mktemp` + 临时文件去重 |
| `find -newermt` | macOS (BSD find) | `find: -newermt: unknown option` | 平台检测，BSD 用 `-newer` + 参考文件 |
| `date -d` | macOS (BSD date) | `date: illegal option -- d` | 平台检测，BSD 用 `-v` 标志 |
| `sort -V` | macOS | 版本排序不可用 | 用 `sort -t. -k1,1n -k2,2n` 替代 |
| `echo -e` | 通用 | 行为不一致 | 使用 `printf` |
| `sed -i` | macOS | 需要提供备份扩展名 | 用 `sed -i ''` 或 Perl 替代 |

### 4.2 validate_skills.sh：`declare -A` → `mktemp`

```bash
# 旧代码（Bash 4+ 专有）
declare -A NAME_COUNT

# 新代码（Bash 3.2+ 兼容）
TMPFILE=$(mktemp) || { echo "  [错误] 无法创建临时文件"; exit 1; }
trap 'rm -f "$TMPFILE"' EXIT INT TERM
# ... 将 name 写入 TMPFILE ...
while read count name; do
    if [ "$count" -gt 1 ]; then
        echo "  [错误] name='$name' 出现 ${count} 次"
    fi
done < <(sort "$TMPFILE" | uniq -c)
```

**关键安全点**：`trap` 必须覆盖 `EXIT INT TERM` 三种信号，确保临时文件在任何退出方式下都被清理。

### 4.3 weekly-report.sh：GNU find → BSD find

```bash
# 平台检测
if [ "$(uname)" = "Darwin" ]; then
    # macOS: 用 touch 创建参考时间文件
    FIND_TIME_FILTER="-newer /tmp/_cci_week_ref_$$"
    touch -t "$(echo "$THIS_WEEK" | tr -d '-')0000" /tmp/_cci_week_ref_$$
else
    # Linux: GNU find 直接支持 -newermt
    FIND_TIME_FILTER="-newermt $THIS_WEEK"
fi

# 使用变量
find "$REPORTS_DIR" -name "*.md" $FIND_TIME_FILTER

# 清理参考文件
rm -f /tmp/_cci_week_ref_$$
```

---

## 五、安全要点

### 5.1 yaml.safe_load() vs yaml.load()

`yaml.load()` 可以执行任意 Python 代码，是严重安全漏洞。**永远使用 `yaml.safe_load()`**。

```python
# check_secrets.py
try:
    import yaml
    HAS_YAML = True
except ImportError:
    HAS_YAML = False

def check_config_file(file_path):
    if HAS_YAML:
        try:
            with open(file_path) as f:
                data = yaml.safe_load(f)  # 安全解析
            return _walk_yaml(data, file_path=file_path)
        except yaml.YAMLError:
            pass  # 回退到逐行解析
    # 逐行正则解析（PyYAML 不可用时的回退方案）
    ...
```

### 5.2 命令注入防护

`index.js` 中所有外部命令调用必须使用 `spawnSync(cmd, args[])` 而非 `execSync(string)`：

```javascript
// 危险：shell 注入
execSync(`git clone ${userInput}`);

// 安全：参数化调用
spawnSync('git', ['clone', userInput]);
```

### 5.3 CI/CD Action SHA 锁定

`.github/workflows/ci.yml` 中所有 action 必须使用 **commit SHA 锁定版本**，不能使用 `@v4` 等浮动标签：

```yaml
# 错误：浮动版本，供应链风险
- uses: actions/checkout@v4

# 正确：锁定 SHA
- uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2
```

同时设置最小权限：
```yaml
permissions:
  contents: read
```

---

## 六、Spec Generation 集成

### 6.1 四层文档架构

```
CLAUDE.md (入口层)
    │  定义："你是谁" + "去哪找"
    │  含 spec 索引表
    ↓
SOUL.md (决策层)
    │  定义：复杂度评估 + 执行决策树
    │  含 spec 检查：5 分+任务必须生成 SPEC
    ↓
SPEC.md (蓝图层)
    │  定义：功能目标 + 约束 + 任务分解 + API 约定
    │  7 节结构
    ↓
PLAN.md (执行层)
    │  定义：当天做了什么 + 下一步计划
    │  执行日志
```

### 6.2 SPEC_Template.md 结构

```markdown
# [功能名称] 功能规格

## 1. 目标与范围
## 2. 约束条件
## 3. 任务分解
## 4. API 契约
## 5. 验收标准
## 6. 边界规则与降级策略
## 7. 相关文档
```

### 6.3 SOUL.md Spec 检查规则

5 分+任务强制执行 Spec-Driven Development：
- AI **必须先生成 SPEC.md** 再写代码
- SPEC.md 必须包含验收标准（可测试）
- 必须有降级/回滚策略（Section 6）

### 6.4 CLAUDE.md Spec 索引

CLAUDE_Template.md 中包含 spec 引用行：
```markdown
功能规格 → docs/specs/
```
AI 在执行任务前会检查该目录是否已有相关规格文档，如有则优先遵循。

---

## 七、使用逻辑

### 7.1 初始化流程

```
用户运行 init.ps1/init.sh
    ↓
复制模板到项目（CLAUDE.md, SOUL.md, PLAN.md）← 含存在检查
    ↓
复制 SPEC_Template.md, ROUTINE_Template.md
    ↓
复制 CLAUDE.local.md → .claude/CLAUDE.local.md ← 隐藏目录
    ↓
复制 Skills 到 .claude/skills/
    ↓
复制 Hooks 到 .claude/hooks/
    ↓
复制 Python 脚本到 .claude/scripts/
    ↓
复制 Bash 脚本到 scripts/
    ↓
安装 Pre-commit hooks（自动 pip install pre-commit）
    ↓
安装 cc-discipline
    ↓
初始化完成
```

### 7.2 任务执行流程

```
用户输入任务
    ↓
Skills Router 自动评估复杂度（0-5分）
    ↓
┌─────────────────────────────────────────┐
│ 0分 → 直接执行                          │
│ 1-2分 → Plan + 执行                    │
│ 3-4分 → Plan + TDD                    │
│ 5分+ → Spec → Plan → TDD → Review     │
└─────────────────────────────────────────┘
    ↓
执行过程中 Hook 场景感知
    ↓
完成后主动推荐下一步
```

### 7.3 Agent Teams 工作流

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

## 八、模块说明

### 8.1 Skills 体系

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

### 8.2 自定义命令

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

### 8.3 模板文件

| 模板 | 目标路径 | 用途 |
|------|----------|------|
| CLAUDE_Template.md | `/CLAUDE.md` | AI 入口配置，含 spec 索引 |
| SOUL_Template.md | `/SOUL.md` | 决策规则，含 spec 检查 |
| PLAN_Template.md | `/PLAN.md` | 执行日志 |
| SPEC_Template.md | `/docs/specs/SPEC_Template.md` | 功能规格模板（7 节结构） |
| ROUTINE_Template.md | `/docs/ROUTINE_Template.md` | 定时任务模板 |

### 8.4 校验脚本

| 脚本 | 功能 |
|------|------|
| check_secrets.py | 检测敏感信息泄露（含 YAML 安全解析） |
| check_function_length.py | 检查函数长度 |
| check_dependencies.py | 检查依赖完整性 |
| check_import_order.py | 检查导入顺序 |
| check_project_structure.py | 检查项目结构（含 gitignore 通配符修复） |
| validate_skills.sh | Skills 命名去重（macOS 兼容） |
| trigger-optimizer.sh | Skills 触发词分析 |

---

## 九、CI/CD 流水线

### 9.1 流水线组成

| Job | 工具 | 覆盖范围 |
|-----|------|----------|
| node-check | Node.js 22 | index.js 语法检查 |
| shellcheck | shellcheck | 所有 .sh 脚本 |
| bash-syntax | bash -n | 所有 .sh 脚本语法 |
| markdown-lint | markdownlint | 所有 .md 文档 |
| python-syntax | python -m py_compile | 所有 .py 脚本 |

### 9.2 Action SHA 锁定清单

| Action | 锁定 SHA | 对应版本 |
|--------|----------|----------|
| actions/checkout | `11bd71901bbe...` | v4.2.2 |
| azure/setup-shellcheck | `e6ba10e6a5...` | v1.2.1 |
| DavidAnson/markdownlint-cli2-action | `1becf028a7...` | v19 |

### 9.3 ShellCheck 排除规则

```yaml
SHELLCHECK_OPTS: "-e SC1091 -e SC2034 -e SC2154"
```
- SC1091：外部 source 文件无法追踪
- SC2034：未使用的变量（工具类脚本常见）
- SC2154：外部引用的变量

---

## 十、常见问题

### Q: 为什么有 scripts/ 和 .claude/scripts/ 两个目录？

- `scripts/`：独立的 Bash 工具，在项目根目录运行（如 tmux-session.sh）
- `.claude/scripts/`：Python 校验脚本，Claude Code 自动识别并运行

**不要在 Skills 中引用 `scripts/` 下的 Python 文件，它们实际在 `.claude/scripts/`。**

### Q: 为什么 .ps1 文件需要 UTF-8 BOM？

PowerShell 5.x 不支持无 BOM 的 UTF-8，会导致中文乱码。PS 7+ 已修复，但为兼容仍需遵守。

### Q: Agent Teams 需要什么条件？

1. Claude Code ≥ 2.0
2. `settings.json` 中设置 `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`
3. tmux 已安装（Unix/macOS）

### Q: 无人值守模式怎么工作？

```bash
bash scripts/tmux-session.sh .claude/scripts/PROMPT.md
```

会在 tmux 会话中循环运行 Claude Code，支持安全限制和 router-unattended 路由。

### Q: init 后在目标项目找不到 Python 校验脚本？

检查目标项目的 `.claude/scripts/` 目录。init 会把校验脚本复制到这里，而不是项目根目录的 `scripts/`。

### Q: 如何确保 init.ps1 和 init.sh 同步？

每次修改 init 流程后，必须在两个文件中做相同变更。步号必须一致。提交前用 `diff` 比较步号编号。

### Q: macOS 上运行脚本报错怎么办？

参考第四章跨平台兼容性陷阱。常见问题：`declare -A` → 用 `mktemp` + `trap` 替代；`find -newermt` → 用 `-newer` + 参考文件。

### Q: CI 流水线报 ShellCheck SC1091 错误？

这是预期行为。`.github/workflows/ci.yml` 中已配置 `SHELLCHECK_OPTS: "-e SC1091"` 排除此规则。如新增 CI 配置需同步此选项。

### Q: SPEC_Template.md 什么时候用？

当 SOUL.md 将任务评估为 5 分+时，AI 会自动生成 SPEC.md。也可以手动用 `/architect` 命令触发。

---

## 十一、版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| v1.5.1 | 2026-04-30 | 隐藏目录合规 + 架构安全 + Spec Generation 集成（26 文件变更） |
| v1.5.0 | 2026-04-30 | Agent Teams 自动建议、Routines 集成、Plugin 市场 |
| v1.4.1 | 2026-04-28 | 智能化提升、无人值守优化 |
| v1.4.0 | 2026-04-28 | SOUL.md 五级复杂度评估 |
| v1.3.0 | 2026-04-28 | 文档清理、安全增强 |

### v1.5.1 详细变更

**隐藏目录合规（6 修复）**：
- 删除 init.ps1/init.sh Step 14（scripts/ 目录污染）
- CLAUDE.local.md 移至 `.claude/CLAUDE.local.md`
- tmux-session.sh reports 移至 `.claude/reports/`
- configure-gitignore 移除 `docs/` 误排除规则
- 模板复制前增加存在检查（防覆盖）

**安全加固（5 修复）**：
- check_secrets.py 使用 `yaml.safe_load()` + ImportError 回退
- validate_skills.sh 用 `mktemp` + `trap` 替代 `declare -A`
- CI/CD 创建 + 所有 action SHA 锁定
- init.ps1 路径比较用 `Resolve-Path.ProviderPath`
- index.js 缓存 `detectPowerShell()` 结果

**跨平台兼容（3 修复）**：
- weekly-report.sh macOS find 兼容（`-newer` + 参考文件）
- validate_skills.sh Bash 3.2 兼容（无关联数组）
- init.sh 源==目标相等检查（与 init.ps1 对齐）

**Spec Generation 集成（5 新增）**：
- SPEC_Template.md（7 节结构模板）
- CLAUDE.md spec 索引行
- SOUL.md spec 检查规则 + 5 分+ 示例
- GUIDE.md 四层文档架构文档
- CHANGELOG.md 创建

---

*本文档为 claude-code-init 项目交接专用，涵盖设计理念、目录结构、易遗漏点和常见问题。如有新增问题，请追加到对应章节。*
