# /status - 项目状态仪表盘

输出当前项目的完整状态概览，帮助你快速了解项目健康度。

## 执行方式

运行以下命令收集信息：
1. `git status --short` - Git 状态
2. `git log --oneline -5` - 最近提交
3. `git diff --stat` - 未提交的改动
4. 检查 `reports/` 目录

## 输出格式

```markdown
# 项目状态仪表盘

## 一、Git 状态
- 当前分支：{branch}
- 未提交文件：{n} 个
- 未推送 commit：{n} 个
- 上次提交：{time ago}

## 二、审查状态
- 最近审查：{date} ({result})
- 未审查的新 commit：{n} 个

## 三、无人值守任务
- 最近任务：{date}
- 完成状态：{completed/total}
- 失败任务：{n} 个

## 四、Skills 使用统计
- 本周触发最多：{skill1}, {skill2}, {skill3}
- 从未触发：{skill}

## 五、环境健康
| 组件 | 状态 |
|------|------|
| Claude Code | {version} |
| Python | {version} |
| Git | {version} |
| Pre-commit | {pass/fail} |
| ECC | {installed/not} |
| Superpowers | {installed/not} |
```

## 解读

| 状态 | 含义 | 建议 |
|------|------|------|
| ✅ 全部绿色 | 项目健康 | 继续开发 |
| ⚠️ 有未审查 commit | 存在风险 | 运行 `/review` |
| ❌ 环境有问题 | 需要修复 | 检查组件安装 |

## 相关命令

- `/review` - 代码审查
- `/validate` - 运行校验
- `/capabilities` - 按场景查看能力
