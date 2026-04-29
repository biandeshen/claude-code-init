# /routine - Claude Code Routines 管理

> Claude Code 云端定时任务，让任务在你离开后自动执行

---

## 什么是 Routines？

Routines 是 Claude Code 的云端自动化功能，可以在指定时间自动执行任务，无需保持本地终端开启。

---

## 使用方式

### /routine <任务描述>

根据你的描述，自动生成 Routine 配置文件：

```
/routine 每晚 2 点修复所有 lint 错误并运行测试
```

AI 会：
1. 分析你的任务描述
2. 生成 Routine YAML 配置
3. 展示配置内容，等待你确认
4. 引导你保存到 `routines/` 目录

---

## Routine 文件结构

```
项目目录/
└── routines/
    ├── daily-lint.yaml      # 每日 lint 修复
    ├── weekly-test.yaml     # 每周测试
    └── ci-trigger.yaml      # CI 触发任务
```

---

## 触发类型

| 类型 | 说明 | 示例 |
|------|------|------|
| `schedule` | 定时执行 | 每天凌晨 2 点 |
| `github_event` | GitHub 事件驱动 | PR 创建时 |
| `manual` | 手动触发 | 按需执行 |

---

## 约束条件

所有 Routine 都自动应用以下安全限制：

- 最大轮次：50
- 最大预算：$10.00
- 最大文件数：20
- 最大行数：500
- **禁止**：`rm -rf`, `git push --force`

---

## 查看所有 Routine

```bash
ls routines/
cat routines/{{routine-name}}.yaml
```

---

## 相关命令

| 命令 | 说明 |
|------|------|
| `/team` | Agent 团队并行执行 |
| `/qa` | 质量保证测试 |
| `/status` | 项目状态仪表盘 |
