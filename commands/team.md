# /team - 启动 Agent 团队

创建由多个 Agent 组成的团队来处理复杂任务。

## 触发条件

当你需要以下场景时使用：
- 多角度代码审查
- 多个假设并行排查
- 分模块并行开发

## 使用方式

```
/team <数量> <任务描述>

示例：
/team 3 审查 PR #142
/team 5 排查登录失败问题
/team 3 实现用户模块（前端/后端/测试）
```

## 团队结构

- **Team Lead**：当前 Claude Code 会话（协调者）
- **Teammates**：N 个独立 Claude Code 实例

## 角色分配

| 任务类型 | 推荐人数 | 角色分配 |
|----------|:--------:|----------|
| 代码审查 | 3 | 安全审查 + 性能审查 + 测试覆盖审查 |
| 调试排查 | 3-5 | 多个调查者并行验证不同假设 |
| 功能开发 | 3 | 前端 + 后端 + 测试 |

## Teammate 工作区隔离（必须遵守）

### 启动隔离工作区

使用 `git worktree` 创建隔离的工作区：

```bash
git worktree add /tmp/teammate-{id} {branch}
cd /tmp/teammate-{id}
```

### 为什么需要隔离

- 避免 teammate 之间互相覆盖文件
- 确保每个 teammate 的修改独立可追溯
- 完成后由 Lead 决定是否合并

### Teammate 完成后

1. 在自己的 worktree 中 git commit
2. Lead 审查后 git merge 到主分支
3. 清理 worktree：`git worktree remove /tmp/teammate-{id}`

## 通信模式（必须遵守）

### 禁止直接通信

teammate 之间**禁止**互相发送消息。所有汇报通过 Lead 中转。

### 标准汇报格式

每个 teammate 完成任务后，必须向 Lead 输出结构化汇报：

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

## 最佳实践

1. **任务拆分**：每个 Agent 分配 5-6 个自包含的原子任务
2. **文件所有权**：避免两个 Agent 编辑同一文件
3. **隔离工作区**：使用 git worktree 避免冲突
4. **进度检查**：定期使用 `/messages` 检查团队状态

## 限制

- 每个会话只能有一个团队
- Agent Teams 需要 Claude Code v2.1.32+
- Split pane 模式在 Windows Terminal 中不支持

## 相关命令

- `/messages` - 查看 teammate 汇报
