这是一份以 **Everything Claude Code (ECC) 全面替换现有规范为主框架** 的完整执行方案。

---

# ECC完全体方案：用社区最强配置彻底重构Claude Code开发环境

**设计原则**：承认社区配置优于个人规范。ECC（150K+ Stars）覆盖了你现有14个文档中约80%的内容，剩下的20%通过 CLAUDE.md 覆盖层 + 辅助工具补齐。**你的现有规范中，被ECC覆盖的7个文件直接归档，只保留5个独有的文档。**


## 一、四大组件分工总览

| 组件 | 定位 | 核心能力 | Stars | 在你的体系里负责什么 |
|------|------|----------|:---:|------|
| **ECC** | 🏛️ 主框架（底座） | 38个Agent + 156个Skill + 72个命令 + 12种语言规则 + Memory系统 | 150K+ | 覆盖80%规范，日常编码的全部基础设施 |
| **Superpowers** | 🛡️ 工程纪律 | TDD铁律 + 根因追踪 + 子代理开发 + 上下文保鲜 | 107K+ | 约束编码行为，强制测试先行和系统化调试 |
| **OpenSpec** | 📋 需求纪律 | SDD 5步法：Propose→Spec→Design→Task→Check | 27K+ | 约束需求理解，强制"先定规范再写代码" |
| **cc-discipline** | 🚫 物理防火墙 | 3个Shell Hook：编辑次数阻断 + 调试未完成阻断 + 错误后纪律注入 | — | 把软约束变成硬阻断，物理上不可绕过 |


## 二、为什么以ECC为主框架

### 2.1 ECC的社区权威性

ECC不是"又一个配置库"，而是当前Claude Code生态中**社区验证最充分、覆盖面最广、迭代最活跃**的配置系统：

| 指标 | 数据 |
|------|------|
| GitHub Stars | 150K+（截至2026年4月）|
| Fork | 23K+ |
| 贡献者 | 170+ |
| 核心模块 | 8大模块（需求规划→编码→评审测试→重构→部署对接）|
| 专业Agent | 38+（安全审查、代码审查、测试生成、架构评审等）|
| Skills | 156+（按需加载，不占常驻上下文）|
| 斜杠命令 | 72+（含/plan、/review、/commit等工作流命令）|
| 语言生态 | 12种编程语言专属规则 |
| 迭代时间 | 10个月高频实战打磨 |

**来源认证**：Anthropic官方黑客马拉松冠军项目，作者Affaan Mustafa用这套配置在8小时内完全依靠Claude Code从零构建了zenith.chat实时对话产品，拿下第一名和$15,000 API额度奖励。

### 2.2 ECC解决了你现有的核心痛点

你的14个规范文档写得很好，但存在三个ECC已经完美解决的问题：

| 你的现有痛点 | ECC的解决方案 |
|-------------|--------------|
| 纯软约束，长会话中被忽略 | ECC Hooks系统 + 结构化规则注入 + 上下文持久化 |
| 无记忆持久化，每次会话从零开始 | ECC Memory系统：跨会话保存关键决策、上下文快照 |
| 没有Agent体系，只有一个通用大脑 | 38个专用Agent分工协作（安全审查、测试生成、代码审查等） |

**ECC把你规范里80%的"建议"变成了"内置能力"**——你不需要再靠一个CLAUDE.md去说服Claude遵守规范，ECC直接在系统层面提供了这些能力。


## 三、你的现有规范：哪些被覆盖，哪些保留

### 3.1 被ECC覆盖的文件（直接归档）

| 你的文件 | ECC等价能力 | 覆盖程度 |
|----------|-----------|:---:|
| Agent_Behavior_Rules.md | `bob` Agent + Hooks系统 + 错误熔断机制 | ✅ 完全覆盖 |
| Coding_Convention.md | `rules/common/python/` + 12种语言专属规则 | ✅ 覆盖且更全 |
| Naming_Convention.md | ECC内置命名约定（文件/类/函数/变量） | ✅ 完全覆盖 |
| Commit_Convention.md | `/commit` 命令（Conventional Commits标准） | ✅ 覆盖且自动化 |
| Frontend_Modification_Rules.md | `ui-ux-expert` Agent + 前端专属规则 | ✅ 完全覆盖 |
| Skill_Development_Convention.md | ECC Skill开发模板 + `/new-skill` 脚手架 | ✅ 覆盖且标准化 |
| Secrets_Management.md | `security-reviewer` Agent + `gitguardian` Skill | ✅ 覆盖且更强 |

### 3.2 保留的文件（ECC没有等价物）

| 你的文件 | 保留原因 | 处理方式 |
|----------|----------|----------|
| **SOUL_Template.md** | ECC没有元认知人格定义 | 保留，重命名为 `SOUL.md`，作为最高优先级注入 |
| **PLAN_Template.md** | ECC有/plan命令但没有你的事后追踪结构 | 保留，与ECC的/plan命令互补（事前+事后） |
| **Language_Convention.md** | ECC默认英文，没有中文约定 | **删除原文件**，核心规则写入CLAUDE.md覆盖层 |
| **DOCS_INDEX.md** | 项目文档索引 | 保留，更新引用关系 |
| **CLAUDE_Template.md** | 你的覆盖层模板 | 更新为引用ECC的新版本 |

### 3.3 迁移后的精简目录结构

```
E:/笔记/Claude Code规范/           ← 精简后：7个→5个文件
├── DOCS_INDEX.md                  # 工具规范索引（更新引用）
├── CLAUDE_Template.md             # CLAUDE.md 模板（覆盖层版本）
├── SOUL_Template.md               # 元认知模板（保留不变）
├── PLAN_Template.md               # 任务计划模板（保留不变）
├── INIT_PROJECT.md                # 项目初始化脚本（更新）
└── _archived/                     # ★ 新增归档目录
    ├── Agent_Behavior_Rules.md    # → ECC bob Agent + Hooks
    ├── Coding_Convention.md       # → ECC rules/common/python/
    ├── Naming_Convention.md       # → ECC 内置命名约定
    ├── Commit_Convention.md       # → ECC /commit 命令
    ├── Frontend_Modification_Rules.md  # → ECC ui-ux-expert Agent
    ├── Skill_Development_Convention.md # → ECC Skill 开发模板
    └── Secrets_Management.md      # → ECC security-reviewer Agent
```


## 四、安装前的环境自检

在开始安装之前，确保你的基础环境已就绪。打开终端，依次执行以下命令检查：

```bash
# 1. 检查 Claude Code 版本（需要 2.x 以上）
claude --version
# 预期：2.x.x 的版本号

# 2. 检查 Git 是否安装
git --version
# 预期：git version 2.x.x...

# 3. 检查 Node.js 版本（需要 18.0+）
node -v
# 预期：v18.x.x 或更高

# 4. 确认 Claude Code 已登录
claude status
# 预期：显示已登录状态
```

任何一项不通过，先解决后再继续。


## 五、按正确顺序安装四大组件

### 步骤1：安装 ECC（主框架）— 约2分钟

启动 Claude Code，在会话中依次执行以下两条命令。**User Scope 安装是个人使用的最佳选择**——一次安装，所有项目自动生效，Claude Code 在任何目录下都自带这些能力：

```text
# 1. 添加 ECC 插件市场源
/plugin marketplace add affaan-m/everything-claude-code

# 2. 一键安装 ECC 全家桶
/plugin install everything-claude-code@everything-claude-code
```

交互界面出现三个选项时，选择 **Install for you (user scope)**。

**成功标志**：终端刷屏显示 `Installed agent: xxx`, `Installed command: xxx` 等列表，或提示 `Plugin is already installed`。出现 `(no content)` 也是安装成功。

**安装后你得到的能力**：

| 模块 | 数量 | 典型内容 |
|------|:---:|------|
| Agents（专用子代理） | 38+ | 安全审查员、代码审查员、架构师、测试生成器、UI/UX专家 |
| Skills（可组合技能） | 156+ | TDD、调试、重构、文档生成、API设计 |
| Commands（斜杠命令） | 72+ | /plan、/review、/commit、/architect、/security-audit |
| Rules（语言规范） | 12种 | Python、TS/JS、Go、Rust、Java等专属编码规则 |
| Hooks（自动化钩子） | 多个 | 提交前格式化、测试验证、安全扫描 |
| Memory（跨会话记忆） | 系统级 | 关键决策持久化、上下文快照保存与恢复 |

### 步骤2：安装 Superpowers（工程纪律）— 约1分钟

在 Claude Code 会话中执行：

```text
# 添加 Superpowers 插件市场
/plugin marketplace add obra/superpowers-marketplace

# 安装 Superpowers
/plugin install superpowers@superpowers-marketplace
```

**Superpowers 核心工作流（自动激活）**：包含四个环节——brainstorming 在编码前通过提问细化需求，using-git-worktrees 在隔离分支创建干净工作区，writing-plans 生成清晰的实现计划，subagent-driven-development 逐任务执行并自动检查和审查。

**核心强制规范**：

| 规范 | 说明 |
|------|------|
| TDD 铁律 | 强制红/绿 TDD，写测试→看测试失败→再写实现 |
| 根因追踪 | 系统化追溯 bug 根因而非修补症状 |
| 验证闭环 | 每个任务完成后自动验证；发送PR前自动运行测试 |
| 上下文注入管理 | 自动注入记忆文件、设计文档、编码规范等上下文 |

### 步骤3：安装 OpenSpec（需求纪律）— 约1分钟

```bash
npx kld-sdd
```

初始化完成后，你的 Claude Code 多出 6 个 `/opsx:*` 命令，按顺序使用：**propose（业务意图） → spec（技术契约） → design（实现方案） → task（原子任务拆解） → check（质量门禁）**。

**质量红线（AI 自检，不可绕过）**：
- 所有参数必须有类型、必填标记、范围约束、示例值
- 性能指标必须是具体数字（如 `<100ms P99`），不能是"高性能"
- 边界场景必须覆盖正常流程 + 所有异常流程
- 数据库表结构必须精确到字段级别（类型、长度、索引）
- task.md 必须 100% 覆盖 spec.md 的每个 API 和 design.md 的每个模块

**什么时候用**：开发闭环引擎重构、新技能开发等复杂功能时走完整5步流程。修 typo、改参数名等小改动不需要。

### 步骤4：安装 cc-discipline（物理防火墙）— 约5分钟

```bash
git clone https://github.com/TechHU-GS/cc-discipline.git ~/.cc-discipline
cd /path/to/your-project
bash ~/.cc-discipline/init.sh
```

安装器是**交互式**的——选择你的技术栈、命名项目名称，即可完成。已有 `.claude/` 目录的项目会被自动检测到，以 append 模式运行：**CLAUDE.md 永不覆盖**，Hooks 通过 jq 合并，自定义规则不受影响，安装前自动创建带时间戳的备份。

**核心 Hooks**：

| Hook | 机制 | 解决什么 |
|------|------|----------|
| `streak-breaker.sh` | 单文件编辑3次警告，**5次硬阻断（exit 2）** | 防止反复打补丁而不找根因 |
| `pre-edit-guard.sh` | 调试未完成即改代码时阻断 | 防止"先改了试试"的坏习惯 |
| `post-error-remind.sh` | 检测错误模式后注入调试纪律 | 防止错误后冲动修改 |

**注意**：ECC 也有 Hooks 系统，但 ECC 的 Hooks 做的是**自动化检查**（格式化、测试、安全扫描），cc-discipline 做的是**物理阻断**（5次编辑阻断、调试未完成阻断）。两者不冲突，互补。


## 六、项目级覆盖层配置

### 6.1 新建项目的完整初始化流程

**Step 1：创建项目目录并进入**
```bash
mkdir your-project && cd your-project && git init
```

**Step 2：初始化 OpenSpec SDD 工作流**
```bash
npx kld-sdd
```

**Step 3：注入 cc-discipline 硬约束 Hooks**
```bash
bash ~/.cc-discipline/init.sh
```
安装器将自动检测已有 `.claude/` 目录并以 append 模式合并。

**Step 4：从模板库复制覆盖层文件**
```powershell
Copy-Item "E:\笔记\Claude Code规范\CLAUDE_Template.md" ".\CLAUDE.md"
Copy-Item "E:\笔记\Claude Code规范\SOUL_Template.md" ".\SOUL.md"
Copy-Item "E:\笔记\Claude Code规范\PLAN_Template.md" ".\PLAN_TEMPLATE.md"
```

**Step 5：创建 `.claude/commands/` 自定义命令**
```bash
mkdir -p .claude/commands
# 手动创建 .claude/commands/review.md、commit.md、architect.md
```

### 6.2 CLAUDE.md 覆盖层模板

```markdown
# CLAUDE.md — 项目入口 + 个人覆盖层
# 以 ECC（Everything Claude Code）为主框架

## 一、引用 ECC 主框架（全局生效，无需在此重复）
# ECC 已提供：38个Agent + 156个Skill + 72个命令 + 12种语言规则 + Memory系统
# ECC 的用户级安装使所有项目自动继承全部能力

## 二、个人覆盖层（仅 ECC 未覆盖的部分）

### 语言约定
- 对话使用中文
- 文档使用中文
- 代码注释使用中文
- 代码标识符使用英文
- 调试日志使用英文

### 元认知
- 遵循 SOUL.md 中定义的人格特质和决策树
- 复杂任务必须走 SOUL.md 的6步流程，简单任务直接执行

### 任务追踪
- 执行过程中按 PLAN_Template.md 的结构同步更新 Plan.md
- 复杂功能开发前，先走 OpenSpec 的5步法（Propose→Spec→Design→Task→Check）
- Plan.md 是执行阶段的事后追踪记录，OpenSpec 是规划阶段的事前审核——二者互补

### 知识库引用
- 使用 @notion 或 @docs 引用项目专用文档
- 通用规范通过 DOCS_INDEX.md 查找

### 安全红线（由 cc-discipline Hooks 兜底）
- 任何 rm -rf / DROP TABLE / git push --force → 必须先确认
- 禁止读取或修改 .env 文件内容（只能读变量名，不能读值）
```

**注意**：不要在你的 CLAUDE.md 里重复 ECC 已有的规则。你的 CLAUDE.md 只写 ECC 没有覆盖的20%。


## 七、完整开发工作流

```
你发起一个任务
│
├─ 修 typo / 改参数名
│   ├─ ECC Memory 自动注入上次会话的关键上下文
│   ├─ ECC 的 156+ Skill 和 38+ Agent 可用
│   ├─ Claude 直接执行
│   └─ cc-discipline Hooks 后台监听防打地鼠
│
├─ 写新函数 / 改一个模块
│   ├─ ECC Memory 自动注入上下文
│   ├─ 你说"用 TDD 方式实现" → Superpowers 激活强制 TDD 流程
│   ├─ 你说"/review" → ECC 启动代码审查 Agent
│   ├─ 执行 → 验证
│   └─ cc-discipline 后台监听
│
└─ 开发闭环引擎 / 新技能 / 复杂新功能
    ├─ ECC Memory 自动注入上下文
    ├─ 你说"/opsx:propose 闭环引擎重构"
    ├─ OpenSpec 完整5步流程走完（Propose→Spec→Design→Task→Check）
    ├─ Superpowers 子代理驱动开发自动并行执行原子任务
    ├─ ECC 的 38 个 Agent 各司其职（安全审查、测试生成、代码审查）
    ├─ cc-discipline 后台监听防打地鼠
    └─ 执行 → Plan.md 记录 → ECC Memory 持久化关键决策
```


## 八、初始化命令序列完整复制版

```bash
# === 步骤0：环境自检 ===
claude --version
git --version
node -v

# === 步骤1：启动 Claude Code 并安装 ECC ===
claude
# 在 Claude Code 会话中输入：
# /plugin marketplace add affaan-m/everything-claude-code
# /plugin install everything-claude-code@everything-claude-code
# 选择 Install for you (user scope)，回车

# === 步骤2：在 Claude Code 中安装 Superpowers ===
# /plugin marketplace add obra/superpowers-marketplace
# /plugin install superpowers@superpowers-marketplace
# 退出 Claude Code：/exit

# === 步骤3：进入项目目录，安装 OpenSpec ===
cd /path/to/your-project
npx kld-sdd

# === 步骤4：安装 cc-discipline ===
git clone https://github.com/TechHU-GS/cc-discipline.git ~/.cc-discipline
bash ~/.cc-discipline/init.sh
# 按提示选择技术栈、命名项目名称

# === 步骤5：复制覆盖层模板 ===
# Windows PowerShell:
Copy-Item "E:\笔记\Claude Code规范\CLAUDE_Template.md" ".\CLAUDE.md"
Copy-Item "E:\笔记\Claude Code规范\SOUL_Template.md" ".\SOUL.md"
Copy-Item "E:\笔记\Claude Code规范\PLAN_Template.md" ".\PLAN_TEMPLATE.md"

# === 步骤6：验证安装 ===
ls .claude/hooks/        # 应看到 streak-breaker.sh, pre-edit-guard.sh, post-error-remind.sh
ls .claude/agents/       # 应看到 reviewer.md, investigator.md (cc-discipline) + ECC 全局 Agent
ls .claude/commands/     # 应看到 ECC 72+ 命令（用户级安装）
ls openspec/             # 应看到 config.yaml + changes/
cat CLAUDE.md | head -5  # 确认覆盖层文件存在
```

**验证**：在 Claude Code 中键入 `/plan` 或 `/opsx:propose` 等命令，如果出现自动补全并正常执行，说明所有组件安装成功。


## 九、总结

| 级别 | 组件 | 核心作用 | Stars | 维护成本 |
|:---:|------|------|:---:|:---:|
| 🏛️ 主框架 | **ECC** | 覆盖80%规范，提供全部基础设施（Agent、Skill、命令、规则、记忆） | 150K+ | **零**（官方插件自动更新） |
| 🛡️ 工程纪律 | **Superpowers** | TDD铁律、根因追踪、子代理开发 | 107K+ | **零**（官方插件自动更新） |
| 📋 需求纪律 | **OpenSpec** | SDD 5步法，强制"先定规范再写代码" | 27K+ | **极低**（标准化流程） |
| 🚫 物理防火墙 | **cc-discipline** | 编辑次数阻断、调试未完成阻断、错误后纪律注入 | — | **零**（纯脚本，不改则不动） |
| ✍️ 个人覆盖层 | **CLAUDE.md + SOUL.md + Plan.md** | 仅ECC未覆盖的20%（中文约定、元认知、事后追踪） | — | **一次性** |

**你现在需要做的事**：按上面"八、初始化命令序列"逐行执行，10分钟内所有组件安装完毕。你的现有规范中，被ECC覆盖的7个文件移到 `_archived/` 目录，保留的5个文件继续使用。