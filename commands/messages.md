# /messages - 查看 Agent 团队状态

查看所有队友的当前状态、完成的任务和待处理的消息。

## 触发条件

- 启动 Agent 团队后需要检查进度
- 队友完成任务后收到通知
- 需要协调多个 Agent 的工作

## 使用方式

```
/messages
```

## 查看内容

| 信息类型 | 说明 |
|----------|------|
| 团队成员 | 所有活跃的 Agent |
| 当前任务 | 每个 Agent 正在处理的任务 |
| 任务状态 | Pending / In Progress / Completed |
| 待处理消息 | 其他 Agent 发送的消息 |
| 空闲通知 | 已完成当前任务的 Agent |

## 使用场景

1. **检查进度**：定期查看各 Agent 完成情况
2. **协调工作**：将新任务分配给空闲的 Agent
3. **处理阻塞**：帮助遇到问题的 Agent 解决障碍

## 示例输出

```
=== Agent 团队状态 ===

🔧 security-reviewer
   状态: ✅ Completed
   任务: 审查 auth 模块安全性
   结果: 发现 2 个问题

🔧 performance-reviewer
   状态: ⏳ In Progress
   任务: 检查 N+1 查询
   进度: 3/5 文件

🔧 test-coverage-reviewer
   状态: ⏳ Pending
   任务: 验证边界条件测试
   依赖: 等待 performance-reviewer

=== 待处理消息 ===
- performance-reviewer: "发现 N+1 在 userRepository"
```

## 相关命令

- `/team` - 启动 Agent 团队
