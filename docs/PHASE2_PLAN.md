# 阶段二落地计划：从小队流程化到自治开发者

> **状态：已完成** (v1.5.0 已交付全部 4 个步骤：tmux-session.sh、Router 升级、docs 更新。注：post-commit-review 通过 git-commit Skill 实现，非独立脚本)
> **归档日期：2026-04-30**

让 AI 从"人在环内"的被动助手，升级为"人在环上"的自治开发者。

---

## 目标概述

| 能力升级 | 核心目的 | 实现思路 | 参考工具 |
|---------|---------|---------|---------|
| **无人值守长任务** | 让 AI 在后台甚至深夜都能持续工作 | 封装 tmux 会话创建/分离/重连 | tmux-orche |
| **Git 事件自动响应** | 提交后自动触发 AI 代码审查 | Claude Code Headless 模式 | Headless 模式 |
| **规范驱动开发强化** | 巩固"设计先行"原则 | Router 调度 SpecKit/OpenSpec | SpecKit / OpenSpec |
| **跨会话状态保持** | 告别失忆，持久保留关键决策 | claude-baton / claude-auto-retry | claude-baton |

---

## Step 1: 新增无人值守脚本

### 脚本位置
`scripts/tmux-session.sh`

### 功能需求

1. **创建会话**：检查是否存在同名会话，不存在则创建并启动 Claude Code
2. **重连会话**：存在则直接 attach
3. **分离会话**：detach 当前会话，保持后台运行
4. **终止会话**：kill 会话

### 核心逻辑

```bash
# 检查会话是否存在
tmux has-session -t claude-dev 2>/dev/null

if [ $? -eq 0 ]; then
    # 存在则 attach
    tmux attach -t claude-dev
else
    # 不存在则创建并启动 Claude Code
    tmux new-session -d -s claude-dev "claude"
    tmux attach -t claude-dev
fi
```

### 集成到 init.ps1/sh

在初始化脚本中复制 `tmux-session.sh` 到新项目的 `scripts/` 目录。

---

## Step 2: 新增 Git Hook 脚本

### 脚本位置
`scripts/post-commit-review.sh`

### 功能需求

1. **获取 diff**：获取最近一次提交的变更内容
2. **调用审查**：使用 `claude -p` 无头模式执行审查
3. **输出结果**：将审查结果写入临时文件或追加到评审日志
4. **后台运行**：避免拖慢提交过程

### 核心逻辑

```bash
#!/bin/bash
# 获取最近提交的 diff
diff=$(git diff HEAD~1 HEAD)

# 调用 Claude Code 审查（后台运行）
claude -p "Review the following code diff and provide a summary:

$diff" > ".git/review-$(date +%Y%m%d-%H%M%S).md" &

exit 0
```

### 配置 Hook

通过 `.git/hooks/post-commit` 调用，或在 `init.ps1/sh` 中自动配置。

---

## Step 3: 升级 Router Skill

### 位置
`.claude/skills/router/SKILL.md`

### 新增决策分支

在决策树中增加：

| 用户意图 | 动作 | 示例 |
|---------|------|------|
| 启动无人值守会话、后台运行 | 执行 `scripts/tmux-session.sh` | "启动后台开发会话" |
| 审查上一次的提交 | 执行 `scripts/post-commit-review.sh` | "审查我刚才的提交" |
| 开始一个新功能、需求分析 | 提示走 SpecKit 流程 | "帮我设计一个新功能" |
| 重构现有模块、迭代改进 | 提示走 OpenSpec 流程 | "重构这个模块" |

---

## Step 4: 文档与配置更新

### 更新文件清单

| 文件 | 更新内容 |
|------|---------|
| `templates/CLAUDE_Template.md` | 增加无人值守和自动审查功能描述 |
| `init.ps1` / `init.sh` | 确保脚本复制和 Hook 配置正确 |
| `README.md` | 增加 Step 2 新能力使用指南 |
| `GUIDE.md` | 增加命令使用说明 |

---

## 时间预估

| 步骤 | 工作量 |
|------|--------|
| Step 1: tmux-session.sh | 1-2 天 |
| Step 2: post-commit-review.sh | 1-2 天 |
| Step 3: Router 升级 | 0.5 天 |
| Step 4: 文档更新 | 0.5 天 |
| **总计** | **约 1-2 周** |

---

## 预期效果

完成后你将拥有：

- **夜间任务**：晚上提需求，次日看完整代码和审查报告
- **提交即审查**：每次 commit 自动生成变更摘要
- **设计先行**：新功能走规范流程，不直接写代码
- **无缝衔接**：跨会话持久化，告别上下文丢失

---

## 与阶段三的衔接

阶段二完成后，`claude-code-init` 将具备"小队流程化 2.0"核心能力，为未来进化到"军团建制"（Agent Teams 并行）打下坚实基础。
