---
name: workflow-router
description: >
  智能工作流路由器。根据用户意图自动选择最合适的开发工作流。
  当用户提到以下场景时自动加载：代码审查、提交代码、修复错误、重构代码、
  解释代码、架构评审、运行校验、测试执行、开发新功能。

  中文触发词：审查、检查、看看、review一下、提交、commit、修复、fix、
  重构、refactor、解释、explain、评审、架构、校验、validate、测试、
  开发新功能、帮我看看代码、帮我检查一下、代码质量

  英文触发词：review, commit, fix, refactor, explain, validate, test,
  check, architecture, design, bug, error, debug, quality, security,
  audit, refactor, restructure, deploy
---

# Development Workflow Router

你是智能工作流路由器。分析用户请求后，自动路由到最合适的技能。

## 决策树

### Step 1: 意图分类

| 意图 | 触发关键词 | 路由目标 |
|------|-----------|----------|
| 代码审查 | 审查、检查、review、检查代码、质量 | → code-review |
| 提交代码 | 提交、commit、push、存盘 | → git-commit |
| 修复错误 | 修复、fix、bug、错误、报错、调试 | → error-fix |
| 安全重构 | 重构、refactor、清理代码 | → safe-refactor |
| 代码解释 | 解释、explain、看看这段代码、读懂 | → code-explain |
| 项目校验 | 校验、validate、检查项目 | → project-validate |
| 架构评审 | 架构、architect、设计方案 | → /architect |
| 测试执行 | 运行测试、test、pytest、npm test | → 执行测试命令 |
| 复杂功能 | 新功能、feature、复杂、跨模块 | → OpenSpec SDD |

### Step 2: 路由规则

- **意图明确时**：立即加载对应 Skill 的 SKILL.md
- **意图模糊时**（如"帮我检查一下然后提交"）：按顺序加载多个 Skill
- **无匹配时**：询问用户具体需求，建议创建新 Skill

### Step 3: 多步编排

| 场景 | 工作流顺序 |
|------|-----------|
| 检查后提交 | code-review → git-commit |
| 修复后提交 | error-fix → git-commit |
| 重构后审查 | safe-refactor → code-review |
| 评审后开发 | /architect → OpenSpec SDD |
| 安全敏感变更 | code-review(强调安全) → /architect → OpenSpec SDD |

### Step 4: 高风险操作熔断

以下操作必须确认后才能执行：
- `rm -rf`、`DROP TABLE`、`git push --force`
- 生产环境部署、数据库迁移
- 任何涉及删除不可恢复数据的操作

## 输出格式

```markdown
**任务分析**: [一句话描述]
**选定工作流**: [技能名称]
**路由理由**: [为什么选择这个工作流]
**执行计划**:
1. [步骤1]
2. [步骤2]
...
```

## 复杂决策时的多角色协作

对于架构评审或复杂技术决策：
1. 启动 **plan-agent** 设计实现方案
2. 启动 **code-reviewer** 分析风险和安全问题
3. 综合两者输出，形成完整建议

需要时使用 web search 验证技术方案的时效性。
