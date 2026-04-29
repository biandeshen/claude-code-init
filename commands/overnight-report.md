# /overnight-report - 查看过夜任务执行汇总

早上起来，只需要运行这个命令，快速了解昨晚 AI 完成了什么。

## 使用方式

```
/overnight-report
/overnight-report 详细
/overnight-report 简短
```

## 输出内容

### 简短模式（默认）

```markdown
# 过夜任务汇总

## 执行概览
- 运行时长: 6小时32分
- 完成任务: 4/6
- 失败任务: 2
- 提交数: 4

## 完成任务
✅ 修复 user.ts 的 lint 错误
✅ 完成 auth 模块测试
✅ 重构 database.ts
✅ 更新 API 文档

## 失败任务
❌ 重构 payment.ts（已记录到 reports/blocked.md）
❌ 测试覆盖率提升（超出预算）

## Git 提交
abc1234 feat: 修复 user.ts lint
def5678 test: 完成 auth 测试
ghi9012 refactor: 重构 database 层
```

### 详细模式

```markdown
# 过夜任务汇总（详细）

## 执行概览
- 开始时间: 2024-01-15 22:00
- 结束时间: 2024-01-16 04:32
- 运行时长: 6小时32分
- 完成任务: 4/6
- 失败任务: 2
- 总提交: 4
- API 消耗: ~$8.50

## 完成任务

### ✅ 任务1: 修复 user.ts 的 lint 错误
- 开始: 22:00
- 结束: 22:23
- 改动: user.ts, user.test.ts
- 提交: abc1234

### ✅ 任务2: 完成 auth 模块测试
- 开始: 22:25
- 结束: 23:45
- 改动: auth/, 15个文件
- 提交: def5678
- 测试覆盖率: 78% → 91%

...

## 失败任务

### ❌ 任务5: 重构 payment.ts
- 原因: 超出任务范围，涉及多个模块
- 记录: reports/blocked.md#task-5
- 建议: 拆分为更小的任务

### ❌ 任务6: 测试覆盖率提升
- 原因: 超出预算
- 记录: reports/blocked.md#task-6
- 当前: 91% → 目标: 95%
```

## 文件结构

命令会读取以下文件生成汇总：

| 文件 | 用途 |
|------|------|
| `reports/summary.md` | 主汇总文件 |
| `reports/task-*.md` | 各任务详情 |
| `reports/blocked.md` | 被跳过的任务 |
| `.git/logs/HEAD` | Git 提交历史 |

## 使用场景

1. **早上快速回顾**：运行 `/overnight-report`，30 秒了解昨晚进展
2. **交接准备**：向同事说明 AI 做了什么
3. **问题排查**：查看失败任务原因，决定是否手动处理

## 相关命令

- `/overnight` - 启动新一轮无人值守任务
- `/team` - 启动 Agent 团队并行工作
