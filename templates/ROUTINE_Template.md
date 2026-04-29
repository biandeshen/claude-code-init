# Routine 定义模板

## 基本信息
- **名称**：{{routine_name}}
- **描述**：{{description}}
- **触发方式**：schedule | webhook | manual

---

## 触发条件

```yaml
trigger:
  type: schedule  # schedule / github_event / manual
  cron: "0 2 * * *"  # 每天凌晨 2 点（仅 schedule 类型）
  # github_event: push  # 对于 GitHub 事件驱动
```

---

## 任务定义

```yaml
tasks:
  - id: lint-fix
    description: 修复所有 lint 错误
    tools: ["Read", "Edit", "Bash(npm run lint:*)", "Bash(git *)"]

  - id: test
    description: 运行测试套件
    tools: ["Bash(npm test)", "Read"]
    depends_on: [lint-fix]

  - id: commit
    description: 提交变更
    tools: ["Bash(git add *)", "Bash(git commit *)"]
    depends_on: [test]
```

---

## 约束条件

| 限制 | 默认值 |
|------|--------|
| 最大轮次 | 50 |
| 最大预算 | $10.00 |
| 最大文件数 | 20 |
| 最大行数 | 500 |

**禁止命令**：`rm -rf`, `git push --force`, `DROP TABLE`

---

## 使用方法

1. 复制此模板到 `routines/{{routine_name}}.yaml`
2. 修改 `{{placeholder}}` 为实际值
3. 在 Claude Code 中加载 Routine：`/routine load routines/{{routine_name}}.yaml`

---

## 示例：每日凌晨自动 lint + test

```yaml
trigger:
  type: schedule
  cron: "0 2 * * *"

tasks:
  - id: lint
    description: 运行并修复 lint 错误
    tools: ["Read", "Edit", "Bash(npm run lint:fix)"]

  - id: test
    description: 运行测试
    tools: ["Bash(npm test)"]
    depends_on: [lint]

  - id: commit-if-changed
    description: 如果有变更则提交
    tools: ["Bash(git add -A)", "Bash(git commit -m 'chore: auto-fix lint')"]
    depends_on: [test]
```
