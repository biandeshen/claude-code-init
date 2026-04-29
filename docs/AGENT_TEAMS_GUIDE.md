# Agent Teams 使用指南

> 多人并行开发与审查，让多个 AI 专家同时工作

---

## 什么时候用

- 复杂 PR 需要多人审查
- 多个独立模块可并行开发
- Bug 根因不明需要多个假设同时验证
- 需要从不同专业角度审视同一问题

---

## 怎么用

### 1. 启动 Agent 团队

```
/team 3 审查最近3个commit
```

或

```
/team 5 排查登录失败问题
```

### 2. AI 自动分派任务

Leader 自动将任务分配给 3-5 个 teammate，每个 teammate 负责不同维度：

- **Architect**：技术方案设计
- **Security**：安全审查
- **Performance**：性能分析
- **QA**：测试覆盖检查

### 3. Teammate 独立工作

每个 teammate：
- 使用独立的 Git worktree 工作区
- 独立执行分配的任务
- 完成后向 Leader 汇报

### 4. Leader 汇总结果

Leader 收集所有 teammate 汇报，输出综合报告。

---

## 通信模式

### 禁止直接通信

teammate 之间**禁止**互相发送消息。所有汇报通过 Lead 中转。

### 标准汇报格式

每个 teammate 完成任务后，必须向 Lead 输出：

```markdown
## Teammate {id} 汇报

### 完成的任务
- [x] 任务1：说明
- [x] 任务2：说明

### 修改的文件
| 文件 | 改动类型 | 说明 |
|------|----------|------|
| src/auth.py | 修改 | 修复 SQL 注入 |

### 测试结果
- 通过：15/15
- 失败：0

### 需要 Lead 关注的问题
- 无
```

### Lead 汇总

Lead 收集所有 teammate 汇报后，整合为一个综合报告输出给用户。

---

## 注意事项

- **teammate 数量**：建议 3-5 个
- **每个 teammate 分配**：自包含的原子任务
- **工作区隔离**：使用 Git worktree 隔离
- **完成后清理**：Leader 决定是否合并，清理 worktree

---

## 相关命令

| 命令 | 说明 |
|------|------|
| `/team <数量> <任务>` | 启动 Agent 团队 |
| `/qa <目标>` | 质量保证测试 |
| `/review` | 单人代码审查 |

---

## 进阶：gstack 角色体系

除了 Agent Teams，还可以使用 gstack 角色命令：

- `/plan-ceo-review` - 产品需求审查
- `/architect` - 架构评审
- `/qa` - QA 测试

这些命令可以单独使用，也可以与 Agent Teams 结合。
