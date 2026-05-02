# 两阶段初始化架构设计

> 状态: 草案 | 最后更新: 2026-05-02
> 替代: 当前 init.sh/init.ps1 全栈一体化方案

---

## 1. 问题陈述

### 1.1 当前架构的痛点

```
init.sh / init.ps1 ← 一个脚本做所有事
├── 文件部署 (cp -r skills / hooks / commands / scripts)
├── 系统依赖安装 (git / pre-commit / Python)
├── JSON 合并 (内联 Python 在 bash 中)
├── 交互式配置 (read -p / Read-Host — /dev/tty 问题)
├── 模板版本比较 (grep 版本号 + 人工比对)
├── 环境检查 (check-env.sh → source lib/common.sh)
└── .gitignore 配置 (sed 块替换 + awk 去重)
```

具体问题:

| # | 问题 | 影响 |
|---|------|------|
| 1 | **双脚本维护** — bash + PowerShell 两套实现 | 5 轮修复已经暴露 27 个 bug，其中 1/3 是跨平台差异 |
| 2 | **Shell 内 JSON 合并** — Python inline 在 bash heredoc 中 | 引号逃逸噩梦，调试困难 |
| 3 | **交互式提示** — `read -p` 无 `/dev/tty` 会从 stdin 读取 | 非交互环境直接挂起 |
| 4 | **跨平台 edge case** — `$HOME` 不可写、mktemp 差异、路径空格 | 每次新平台暴露新 bug |
| 5 | **用户无参与感** — 脚本静默覆盖，用户事后才发现 | CLAUDE.md 被覆盖后才看到 .bak |
| 6 | **单次运行即失效** — 配置完成后无法检测模板漂移 | 项目模板永远停留在 init 时刻 |

### 1.2 根因

**Shell 脚本不适合做需要"理解上下文 + 交互决策"的事情。** 当前架构让 init.sh 承担了两种截然不同的工作:

- **部署工作** (Shell 擅长): 复制文件、安装依赖、设置 git hooks
- **配置工作** (Shell 不擅长): JSON 合并、交互式问答、版本对比、环境诊断

### 1.3 核心洞察

> Claude Code 启动后可以做 Shell 做不到的事:
> - 用自然语言问用户问题
> - 理解 JSON/YAML/Markdown 结构
> - 跨平台路径处理 (Claude Code 自身已经处理了)
> - 逐项确认再执行 (用户参与决策)

---

## 2. 方案评估

### 2.1 候选方案

通过联网搜索和 3 路 agent 并行分析，评估了三种方案:

| 方案 | 原理 | 复杂度 | 交互性 | 推荐度 |
|------|------|--------|--------|--------|
| **A: MCP Server** (如 CCL) | 独立服务暴露工具给 Claude Code | 🔴 高 | ⭐⭐⭐ | ❌ |
| **B: Setup Hook** (`claude --init`) | Claude Code 内置的初始化钩子 | 🟡 中 | ⭐⭐ | ⚠️ |
| **C: Skill** (`/init-config`) | 自定义 Skill 引导 Claude 执行配置 | 🟢 低 | ⭐⭐⭐⭐⭐ | ✅ |

### 2.2 MCP Server — 不推荐

**CCL (Claude Context Loader)** 是 MCP 方案的典型代表，但分析显示:

- **鸡和蛋问题**: MCP Server 需要配置 `.mcp.json` 才能用，但配置本身是 init 要生成的内容
- **生命周期不匹配**: MCP 适合"持续运行的服务"，而脚手架是"一次性操作"
- **部署成本**: 需要安装 MCP SDK + 配置 + 进程管理，远重于 `git clone + 运行脚本`
- **社区验证**: cc-discipline、ECC、Superpowers、OpenSpec 均未采用 MCP 做脚手架，这不是偶然

**结论**: CCL 选择 MCP 是合理的 (它是运行时服务)，但 claude-code-init 选用 MCP 是错误的 (它是脚手架生成器)。

### 2.3 Setup Hook — 有局限

`Setup` hook (Claude Code v2.1.10+) 适合**静默环境准备**:

```json
{
  "hooks": {
    "Setup": [{
      "matcher": "init",
      "hooks": [{
        "type": "command",
        "command": "bash .claude/hooks/init-check.sh"
      }]
    }]
  }
}
```

优势:
- `claude --init` 是自然的 CLI UX
- 脚本 stdout 成为 Claude 的 additionalContext

局限:
- **无法交互**: Hook 是 shell 脚本，不能用自然语言问用户问题
- **版本依赖**: 需要 Claude Code v2.1.10+
- **作用有限**: 只能做"检查 + 报告"，实际修改仍需 Claude 在对话中完成

**结论**: 适合作为辅助提醒机制 (让 Claude 在启动时提示 `/init-config`)，不适合作为配置阶段的主体。

### 2.4 Skill — 推荐方案

**Skill 方案的核心优势**:

| 维度 | Skill `/init-config` | 当前 init.sh |
|------|---------------------|-------------|
| 交互方式 | 自然语言对话 | `read -p` shell 提示 |
| 跨平台 | Claude Code 自动处理 | 双脚本 + 27 个已修 bug |
| 模板合并 | Claude 理解两侧语义，智能合并 | Python inline 在 bash 中 |
| 用户可见性 | "我要做以下 3 件事，同意吗？" | 静默覆盖 |
| 持续可用 | 每次会话都可调用 | 只在 init 时运行一次 |
| 维护成本 | 纯 Markdown + shell 辅助脚本 | bash + PS + inline Python |

SKILL.md 的编排模式 (来自 Plector 的已验证实践):

```
Skill (SKILL.md)         ← 决策 + 交互层 (Claude 驱动)
    │
    ├── 步骤 1: 运行 shell 脚本做检查  ← 机械层 (确定性的)
    ├── 步骤 2: 读文件、分析差异       ← 理解层 (Claude 擅长)
    ├── 步骤 3: 问用户、确认           ← 交互层 (自然语言)
    └── 步骤 4: 写文件、应用配置       ← 执行层 (通过工具)
```

---

## 3. 目标架构

### 3.1 两阶段总览

```
┌─────────────────────────────────────────────────────────┐
│                   两阶段初始化流程                        │
├──────────────────────┬──────────────────────────────────┤
│  阶段 1: 引导部署     │  阶段 2: 交互配置                 │
│  init.sh / init.ps1  │  Skill `/init-config`            │
│                      │                                  │
│  [终端中运行]          │  [Claude Code 会话中运行]         │
│                      │                                  │
│  • 创建 .claude/ 结构 │  • settings.json 合并            │
│  • 复制 hooks/skills  │  • .gitignore 策略               │
│  • 复制 commands      │  • 模板版本比较 + 覆盖           │
│  • 复制 scripts       │  • 环境完整性检查                 │
│  • 安装 pre-commit    │  • CLAUDE.md 定制化              │
│  • 安装 cc-discipline │  • 交互式确认 (自然语言)          │
│                      │                                  │
│  输出: 文件就绪        │  输出: 配置完成报告               │
│  提示: claude --init  │                                  │
└──────────────────────┴──────────────────────────────────┘
```

### 3.2 阶段 1: init.sh 精简 (引导部署)

init.sh 只保留 **Shell 能做且 Claude Code 不能做的事**:

```bash
# init.sh — 精简后的职责

# 1. 文件部署 (cp -r, 无需 AI 判断)
cp -r "$SKILLS_DIR"   "$TARGET/.claude/skills/"
cp -r "$HOOKS_DIR"    "$TARGET/.claude/hooks/"
cp -r "$COMMANDS_DIR" "$TARGET/.claude/commands/"
cp -r "$SCRIPTS_DIR"  "$TARGET/.claude/scripts/"

# 2. 系统依赖安装 (需要 root/shell 权限)
pre-commit install
git clone cc-discipline

# 3. 初始化 settings.json (仅基础结构, 不含合并)
cat > "$TARGET/.claude/settings.json" <<JSON
{
  "hooks": { "PreToolUse": [...] }
}
JSON
```

**移除的内容** (移到阶段 2):

| 当前职责 | 移入阶段 2 的原因 |
|----------|-----------------|
| JSON 合并 | Claude 读两侧 JSON，智能合并，保留用户覆盖 |
| .gitignore 交互选择 | Claude 自然语言问用户 (全部忽略/部分提交/全部提交) |
| 模板版本比较 | Claude diff 对比，用户决策是否覆盖 |
| 环境检查 | Claude 逐个 `command -v` 检查，输出友好报告 |
| 备份/覆盖确认 | `--force` 模式外，Claude 逐个确认 |

### 3.3 阶段 2: Skill /init-config (交互配置)

SKILL.md 的核心指令:

```markdown
---
name: init-config
description: 完成项目初始化配置 — settings.json 合并、.gitignore 策略、模板覆盖、环境检查
---

# Init Config

## 执行步骤

### 步骤 1: 配置 settings.json
- 读取 `.claude/settings.json` (当前) 和源模板
- 合并 hooks 配置，保留用户已有覆盖
- 用 `python3 -c "import json; ..."` 做 JSON 合并
- 写回 `.claude/settings.json`

### 步骤 2: 配置 .gitignore
- 检查 `.gitignore` 是否已有 AI 配置条目
- 问用户: "你想如何管理 AI 配置文件？"
  - 全部忽略 (推荐) / 部分提交 / 全部提交
- 根据用户选择写入

### 步骤 3: 检查模板版本
- 读取 CLAUDE.md / SOUL.md 版本号
- 与模板版本对比
- 如有差异: 显示 diff，问用户是否更新

### 步骤 4: 检查环境完整性
- 逐个检查: claude --version, python --version, node --version
- 报告缺失或版本不满足的组件
```

### 3.4 辅助脚本

Skill 可以调用 shell 脚本做确定性的机械操作:

```
.claude/
├── skills/
│   └── init-config/
│       ├── SKILL.md              # Skill 指令
│       └── scripts/
│           ├── check-prereqs.sh  # 环境预检 (被 Skill 步骤 4 调用)
│           └── apply-templates.sh # 模板应用 (被 Skill 步骤 3 调用)
```

这些脚本是**可选的** — Claude 也可以用 Bash 工具直接执行命令。"Skill 编排 + shell 执行"模式将决策层和执行层分离。

---

## 4. 用户流程对比

### 4.1 当前流程

```bash
./init.sh . --force --skip-ecc --skip-superpowers --skip-openspec
# → 脚本静默执行 5-10 秒
# → 输出 "初始化完成！"
# → 用户不知道具体发生了什么
# → 事后发现 CLAUDE.md 被覆盖了才看到 .bak
# → 发现 .gitignore 重复条目
```

### 4.2 新流程

```bash
# 阶段 1: 终端中运行 (5 秒)
./bootstrap.sh ./my-project
# → 仅复制文件 + 安装依赖
# → 输出 "运行 claude 进入项目完成配置"

# 阶段 2: Claude Code 会话中
cd my-project
claude
# → 输入 /init-config
# → Claude: "我将帮你完成项目配置。需要做 3 件事:
#    1. 合并 settings.json (发现 cc-discipline hooks 已存在，将追加 smart-context hook)
#    2. 配置 .gitignore (当前未包含 AI 文件)
#    3. 检查环境完整性
#    是否开始？"
# → 用户: "好的，开始吧"
# → Claude 逐项执行，每步确认
# → Claude: "配置完成！变更摘要: ..."
```

---

## 5. 迁移路径

### 5.1 向后兼容

- **现有 init.sh/init.ps1 保留** — 添加 `--legacy` 标志运行当前全栈模式
- **新 `bootstrap.sh`** — 精简版，仅部署 + 提示运行 `/init-config`
- **Skill 独立于 init 流程** — 即使用户手动部署文件，也能直接 `/init-config`

### 5.2 引入步骤

```
第 1 步: 编写 Skill `/init-config` (SKILL.md + 辅助脚本)
第 2 步: 创建 bootstrap.sh (从 init.sh 剥离配置逻辑)
第 3 步: 添加 Setup Hook (可选提醒)
第 4 步: init.sh 添加 --legacy 模式
第 5 步: 文档更新 + 默认流程切换
```

### 5.3 版本要求

| 组件 | 最低版本 | 备注 |
|------|----------|------|
| Claude Code | ≥ 2.0 | Skill 机制的基础要求 |
| Setup Hook (可选) | ≥ 2.1.10 | 仅用于自动提醒 |
| Skill `/init-config` | ≥ 2.0 | 所有版本可用 |

---

## 6. 风险与缓解

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| Claude 执行 SKILL.md 时推理偏差 | 配置结果不符合预期 | 辅助脚本做确定性操作 (JSON 合并、文件写入) |
| 用户不习惯 `/init-config` | 阶段 2 被跳过 | Setup Hook 在启动时提示 "运行 /init-config 完成配置" |
| Claude Code 版本低于 2.0 | Skill 不可用 | bootstrap.sh 检测版本并警告 |
| 网络不稳定时无法下载模板 | 配置中断 | 辅助脚本支持重试，Skill 描述幂等行为 |
| SKILL.md 指令过于复杂 | Claude 执行遗漏步骤 | 拆分为多个步骤，每步有明确的成功标准 |

---

## 7. 设计原则

1. **Shell 做部署，Claude 做配置** — 各司其职，不越界
2. **确定性操作进脚本，决策性操作进 Skill** — 脚本保证正确性，Skill 保证灵活性
3. **用户始终在 loop 中** — Claude 每步之前先问，用户确认后再执行
4. **幂等设计** — 重复运行 `/init-config` 不产生副作用
5. **渐进披露** — 先做最常见的配置，高级选项折叠在 "需要更多？" 后面
